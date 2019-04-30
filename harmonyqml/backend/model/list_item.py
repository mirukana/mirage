from typing import Any, Dict, List, Mapping, Optional, Tuple

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot


class _ListItemMeta(type(QObject)):  # type: ignore
    __slots__ = ()

    def __new__(mcs, name: str, bases: Tuple[type], attrs: Dict[str, Any]):
        def to_pyqt_type(type_):
            try:
                if issubclass(type_, (bool, int, float, str)):
                    return type_
                if issubclass(type_, Mapping):
                    return "QVariantMap"
                return "QVariant"
            except TypeError:  # e.g. None passed
                return to_pyqt_type(type(type_))

        special  = {"_main_key", "_required_init_values", "_constant"}
        constant = set(attrs.get("_constant") or set())

        props = {
            name: (to_pyqt_type(attrs.get("__annotations__", {}).get(name)),
                   value)
            for name, value in attrs.items()

            if not (name.startswith("__") or callable(value) or
                    name in special)
        }

        signals = {
            f"{name}Changed": pyqtSignal(type_)
            for name, (type_, _) in props.items() if name not in constant
        }

        pyqt_props_kwargs: Dict[str, Dict[str, Any]] = {
            name: {"constant": True} if name in constant else
                  {"notify": signals[f"{name}Changed"],
                   "fset": lambda self, value, n=name: (
                       setattr(self, f"_{n}", value) or  # type: ignore
                       getattr(self, f"{n}Changed").emit(value),
                   ),
                  }
            for name in props
        }

        pyqt_props = {
            name: pyqtProperty(
                type_,
                fget=lambda self, n=name: getattr(self, f"_{n}"),
                **pyqt_props_kwargs.get(name, {}),
            )
            for name, (type_, _) in props.items()
        }

        attrs = {
            **attrs, **signals, **pyqt_props,
            "__slots__": tuple({f"_{prop}" for prop in props} & {"_main_key"}),
            "_props":    props,
            "_main_key": attrs.get("_main_key") or
                         list(props.keys())[0] if props else None,

            "_required_init_values": attrs.get("_required_init_values") or (),
            "_constant": constant,
        }
        return type.__new__(mcs, name, bases, attrs)


class ListItem(QObject, metaclass=_ListItemMeta):
    def __init__(self, *args, **kwargs) -> None:
        super().__init__()

        method      = "%s.__init__()" % type(self).__name__
        already_set = set()

        required     = set(self._required_init_values)
        required_num = len(required) + 1  # + 1 = self
        args_num     = len(self._props) + 1
        from_to      = str(args_num) if required_num == args_num else \
                       f"from {required_num} to {args_num}"

        if len(args) > len(self._props):
            raise TypeError(
                f"{method} takes {from_to} positional arguments but "
                f"{len(args) + 1} were given"
            )

        for prop, value in zip(self._props, args):
            setattr(self, f"_{prop}", value)
            already_set.add(prop)

        for prop, value in kwargs.items():
            if prop in already_set:
                raise TypeError(f"{method} got multiple values for "
                                f"argument {prop!r}")
            if prop not in self._props:
                raise TypeError(f"{method} got an unexpected keyword "
                                f"argument {prop!r}")
            setattr(self, f"_{prop}", value)
            already_set.add(prop)

        missing = required - already_set
        if missing:
            raise TypeError("%s missing %d required argument: %s" % (
                method, len(missing), ", ".join((repr(m) for m in missing))))

        for prop in set(self._props) - already_set:
            # Set default values for properties not provided in arguments
            setattr(self, f"_{prop}", self._props[prop][1])


    def __repr__(self) -> str:
        return "%s(main_key=%r, required_init_values=%r, constant=%r, %s)" % (
            type(self).__name__,
            self.mainKey,
            self._required_init_values,
            self._constant,
            ", ".join((("%s=%r" % (p, getattr(self, p))) for p in self._props))
        )


    @pyqtSlot(result=str)
    def repr(self) -> str:
        return self.__repr()


    @pyqtProperty(list)
    def roles(self) -> List[str]:
        return list(self._props.keys())


    @pyqtProperty(str)
    def mainKey(self) -> str:
        return self._main_key


class User(ListItem):
    _required_init_values = {"name"}
    _constant             = {"name"}

    name:  str             = ""
    age:   int             = 0
    likes: Tuple[str, ...] = ()
    knows: Dict[str, str]  = {}
    photo: Optional[str]   = None
    other = None
