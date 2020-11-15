import textwrap
from collections import OrderedDict
from collections.abc import MutableMapping
from dataclasses import dataclass, field
from operator import attrgetter
from pathlib import Path
from typing import (
    Any, Callable, ClassVar, Dict, Generator, List, Optional, Set, Tuple, Type,
    Union,
)

import redbaron as red

from .globals_dict import GlobalsDict
from .property import Property, process_value

# TODO: docstrings, error handling, support @property, non-section classes
BUILTINS_DIR: Path = Path(__file__).parent.parent.parent.resolve()  # src dir


@dataclass(repr=False, eq=False)
class Section(MutableMapping):
    sections:   ClassVar[Set[str]]        = set()
    methods:    ClassVar[Set[str]]        = set()
    properties: ClassVar[Set[str]]        = set()
    order:      ClassVar[Dict[str, None]] = OrderedDict()

    source_path:   Optional[Path]      = None
    root:          Optional["Section"] = None
    parent:        Optional["Section"] = None
    builtins_path: Path                = BUILTINS_DIR
    globals:       GlobalsDict         = field(init=False)

    _edited: Dict[str, Any] = field(init=False, default_factory=dict)

    def __init_subclass__(cls, **kwargs) -> None:
        # Make these attributes not shared between Section and its subclasses
        cls.sections   = set()
        cls.methods    = set()
        cls.properties = set()
        cls.order      = OrderedDict()

        for parent_class in cls.__bases__:
            if not issubclass(parent_class, Section):
                continue

            cls.sections   |= parent_class.sections  # union operator
            cls.methods    |= parent_class.methods
            cls.properties |= parent_class.properties
            cls.order.update(parent_class.order)

        super().__init_subclass__(**kwargs)  # type: ignore


    def __post_init__(self) -> None:
        self.globals = GlobalsDict(self)


    def __getattr__(self, name: str) -> Union["Section", Any]:
        # This method signature tells mypy about the dynamic attribute types
        # we can access. The body is run for attributes that aren't found.

        return super().__getattribute__(name)


    def __setattr__(self, name: str, value: Any) -> None:
        # This method tells mypy about the dynamic attribute types we can set.
        # The body is also run when setting an existing or new attribute.

        if name in self.__dataclass_fields__:
            super().__setattr__(name, value)
            return

        if name in self.properties:
            value = process_value(getattr(type(self), name).annotation, value)

            if self[name] == value:
                return

            getattr(type(self), name).value_override = value
            self._edited[name]                       = value
            return

        if name in self.sections or isinstance(value, Section):
            raise NotImplementedError(f"cannot set section {name!r}")

        if name in self.methods or callable(value):
            raise NotImplementedError(f"cannot set method {name!r}")

        self._set_property(name, "Any", "None")
        getattr(type(self), name).value_override = value
        self._edited[name] = value


    def __delattr__(self, name: str) -> None:
        raise NotImplementedError(f"cannot delete existing attribute {name!r}")


    def __getitem__(self, key: str) -> Any:
        try:
            return getattr(self, key)
        except AttributeError as err:
            raise KeyError(str(err))


    def __setitem__(self, key: str, value: Union["Section", str]) -> None:
        setattr(self, key, value)


    def __delitem__(self, key: str) -> None:
        delattr(self, key)


    def __iter__(self) -> Generator[str, None, None]:
        for attr_name in self.order:
            yield attr_name


    def __len__(self) -> int:
        return len(self.order)


    def __eq__(self, obj: Any) -> bool:
        if not isinstance(obj, Section):
            return False

        if self.globals.data != obj.globals.data or self.order != obj.order:
            return False

        return not any(self[attr] != obj[attr] for attr in self.order)


    def __repr__(self) -> str:
        name:     str       = type(self).__name__
        children: List[str] = []
        content:  str       = ""
        newline:  bool      = False

        for attr_name in self.order:
            value = getattr(self, attr_name)

            if attr_name in self.sections:
                before  = "\n" if children else ""
                newline = True

                try:
                    children.append(f"{before}{value!r},")
                except RecursionError as err:
                    name = type(value).__name__
                    children.append(f"{before}{name}(\n    {err!r}\n),")
                    pass

            elif attr_name in self.methods:
                before  = "\n" if children else ""
                newline = True
                children.append(f"{before}def {value.__name__}(…),")

            elif attr_name in self.properties:
                before  = "\n" if newline else ""
                newline = False

                try:
                    children.append(f"{before}{attr_name} = {value!r},")
                except RecursionError as err:
                    children.append(f"{before}{attr_name} = {err!r},")

            else:
                newline = False

        if children:
            content = "\n%s\n" % textwrap.indent("\n".join(children), " " * 4)

        return f"{name}({content})"


    @classmethod
    def _register_set_attr(cls, name: str, add_to_set_name: str) -> None:
        cls.methods.discard(name)
        cls.properties.discard(name)
        cls.sections.discard(name)
        getattr(cls, add_to_set_name).add(name)
        cls.order[name] = None

        for subclass in cls.__subclasses__():
            subclass._register_set_attr(name, add_to_set_name)


    def _set_section(self, section: "Section") -> None:
        name = type(section).__name__

        if hasattr(self, name) and name not in self.order:
            raise AttributeError(f"{name!r}: forbidden name")

        if name in self.sections:
            self[name].deep_merge(section)
            return

        self._register_set_attr(name, "sections")
        setattr(type(self), name, section)


    def _set_method(self, name: str, method: Callable) -> None:
        if hasattr(self, name) and name not in self.order:
            raise AttributeError(f"{name!r}: forbidden name")

        self._register_set_attr(name, "methods")
        setattr(type(self), name, method)


    def _set_property(
        self, name: str, annotation: str, expression: str,
    ) -> None:
        if hasattr(self, name) and name not in self.order:
            raise AttributeError(f"{name!r}: forbidden name")

        prop = Property(name, annotation, expression, self)
        self._register_set_attr(name, "properties")
        setattr(type(self), name, prop)


    def deep_merge(self, section2: "Section") -> None:
        for key in section2:
            if key in self.sections and key in section2.sections:
                self.globals.data.update(section2.globals.data)
                self[key].deep_merge(section2[key])

            elif key in section2.sections:
                self.globals.data.update(section2.globals.data)
                new_type = type(key, (Section,), {})
                instance = new_type(
                    source_path   = self.source_path,
                    root          = self.root or self,
                    parent        = self,
                    builtins_path = self.builtins_path,
                )
                self._set_section(instance)
                instance.deep_merge(section2[key])

            elif key in section2.methods:
                self._set_method(key, section2[key])

            else:
                prop2 = getattr(type(section2), key)
                self._set_property(key, prop2.annotation, prop2.expression)


    def include_file(self, path: Union[Path, str]) -> None:
        if not Path(path).is_absolute() and self.source_path:
            path = self.source_path.parent / path

        self.deep_merge(Section.from_file(path))


    def include_builtin(self, relative_path: Union[Path, str]) -> None:
        self.deep_merge(Section.from_file(self.builtins_path / relative_path))


    def as_dict(self, _section: Optional["Section"] = None) -> Dict[str, Any]:
        dct     = {}
        section = self if _section is None else _section

        for key, value in section.items():
            if isinstance(value, Section):
                dct[key] = self.as_dict(value)
            else:
                dct[key] = value

        return dct


    def edits_as_dict(
        self, _section: Optional["Section"] = None,
    ) -> Dict[str, Any]:

        warning = (
            "This file is generated when settings are changed from the GUI, "
            "and properties in it override the ones in the corresponding "
            "PCN user config file. "
            "If a property is gets changed in the PCN file, any corresponding "
            "property override here is removed."
        )

        if _section is None:
            section = self
            dct     = {"__comment": warning, "set": section._edited.copy()}
            add_to  = dct["set"]
        else:
            section = _section
            dct     = {
                prop_name: (
                    getattr(type(section), prop_name).expression,
                    value_override,
                )
                for prop_name, value_override in section._edited.items()
            }
            add_to  = dct

        for name in section.sections:
            edits = section.edits_as_dict(section[name])

            if edits:
                add_to[name] = edits  # type: ignore

        return dct


    def deep_merge_edits(
        self, edits: Dict[str, Any], has_expressions: bool = True,
    ) -> bool:

        changes = False

        if not self.parent:  # this is Root
            edits = edits.get("set", {})

        for name, value in edits.copy().items():
            if isinstance(self.get(name), Section) and isinstance(value, dict):
                if self[name].deep_merge_edits(value, has_expressions):
                    changes = True

            elif not has_expressions:
                self[name] = value

            elif isinstance(value, (tuple, list)):
                user_expression, gui_value = value

                if not hasattr(type(self), name):
                    self[name] = gui_value
                elif getattr(type(self), name).expression == user_expression:
                    self[name] = gui_value
                else:
                    # If user changed their config file, discard the GUI edit
                    del edits[name]
                    changes = True

        return changes


    @classmethod
    def from_source_code(
        cls,
        code:     str,
        path:     Optional[Path] = None,
        builtins: Optional[Path] = None,
        *,
        inherit:  Tuple[Type["Section"], ...]              = (),
        node:     Union[None, red.RedBaron, red.ClassNode] = None,
        name:     str                                      = "Root",
        root:     Optional["Section"]                      = None,
        parent:   Optional["Section"]                      = None,
    ) -> "Section":

        builtins                  = builtins or BUILTINS_DIR
        section:  Type["Section"] = type(name, inherit or (Section,), {})
        instance: Section         = section(path, root, parent, builtins)

        node = node or red.RedBaron(code)

        for child in node.node_list:
            if isinstance(child, red.ClassNode):
                root_arg      = instance if root is None else root
                child_inherit = []

                for name in child.inherit_from.dumps().split(","):
                    name = name.strip()

                    if name:
                        child_inherit.append(type(attrgetter(name)(root_arg)))

                instance._set_section(section.from_source_code(
                    code     = code,
                    path     = path,
                    builtins = builtins,
                    inherit  = tuple(child_inherit),
                    node     = child,
                    name     = child.name,
                    root     = root_arg,
                    parent   = instance,
                ))

            elif isinstance(child, red.AssignmentNode):
                if isinstance(child.target, red.NameNode):
                    name = child.target.value
                else:
                    name = str(child.target.to_python())

                instance._set_property(
                    name,
                    child.annotation.dumps() if child.annotation else "",
                    child.value.dumps(),
                )

            else:
                env = instance.globals
                exec(child.dumps(), dict(env), env)  # nosec

                if isinstance(child, red.DefNode):
                    instance._set_method(child.name, env[child.name])

        return instance


    @classmethod
    def from_file(
        cls, path: Union[str, Path], builtins: Union[str, Path] = BUILTINS_DIR,
    ) -> "Section":
        path = Path(path)
        return Section.from_source_code(path.read_text(), path, Path(builtins))
