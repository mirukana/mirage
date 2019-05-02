from typing import Any, Dict, List, Mapping, Set, Tuple, Union

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot

PyqtType = Union[str, type]


class _ListItemMeta(type(QObject)):  # type: ignore
    __slots__ = ()

    def __new__(mcs, name: str, bases: Tuple[type], attrs: Dict[str, Any]):
        def to_pyqt_type(type_) -> PyqtType:
            "Return an appropriate pyqtProperty type from an annotation."
            try:
                if issubclass(type_, (bool, int, float, str, type(None))):
                    return type_
                if issubclass(type_, Mapping):
                    return "QVariantMap"
                return "QVariant"
            except TypeError:  # e.g. None passed
                return to_pyqt_type(type(type_))

        # These special attributes must not be processed like properties
        special = {"_main_key", "_required_init_values", "_constant"}

        # These properties won't be settable and will not have a notify signal
        constant: Set[str] = set(attrs.get("_constant") or set())

        # pyqtProperty objects that were directly defined in the class
        direct_pyqt_props: Dict[str, pyqtProperty] = {
            name: obj for name, obj in attrs.items()
            if isinstance(obj, pyqtProperty)
        }

        # {property_name: (its_pyqt_type, its_default_value)}
        props: Dict[str, Tuple[PyqtType, Any]] = {
            name: (to_pyqt_type(attrs.get("__annotations__", {}).get(name)),
                   value)
            for name, value in attrs.items()

            if not (name.startswith("__") or callable(value) or
                    name in special)
        }

        # Signals for the pyqtProperty notify arguments
        signals: Dict[str, pyqtSignal] = {
            f"{name}Changed": pyqtSignal(type_)
            for name, (type_, _) in props.items() if name not in constant
        }

        # pyqtProperty() won't take None, so we make dicts of extra kwargs
        # to pass for each property
        pyqt_props_kwargs: Dict[str, Dict[str, Any]] = {
            name: {"constant": True} if name in constant else

                  {"notify": signals[f"{name}Changed"],

                   "fset": lambda self, value, n=name: (
                       setattr(self, f"_{n}", value) or  # type: ignore
                       getattr(self, f"{n}Changed").emit(value),
                   )}
            for name in props
        }

        # The final pyqtProperty objects we create
        pyqt_props: Dict[str, pyqtProperty] = {
            name: pyqtProperty(
                type_,
                fget=lambda self, n=name: getattr(self, f"_{n}"),
                **pyqt_props_kwargs.get(name, {}),
            )
            for name, (type_, _) in props.items()
        }

        attrs = {
            **attrs,  # Original class attributes
            **signals,
            **direct_pyqt_props,
            **pyqt_props,

            # Set the internal _properties as slots for memory savings
            "__slots__": tuple({f"_{prop}" for prop in props} & {"_main_key"}),

            "_direct_props": list(direct_pyqt_props.keys()),
            "_props": props,

            # The main key is either the attribute _main_key,
            # or the first defined property
            "_main_key": attrs.get("_main_key") or
                         list(props.keys())[0] if props else None,

            "_required_init_values": attrs.get("_required_init_values") or (),
            "_constant": constant,
        }
        return type.__new__(mcs, name, bases, attrs)


class ListItem(QObject, metaclass=_ListItemMeta):
    def __init__(self, *args, **kwargs) -> None:
        super().__init__()

        method:      str      = "%s.__init__()" % type(self).__name__
        already_set: Set[str] = set()

        required:     Set[str] = set(self._required_init_values)
        required_num: int      = len(required) + 1  # + 1 = self

        args_num: int = len(self._props) + 1
        from_to: str  = str(args_num) if required_num == args_num else \
                        f"from {required_num} to {args_num}"

        # Check that not too many positional arguments were passed
        if len(args) > len(self._props):
            raise TypeError(
                f"{method} takes {from_to} positional arguments but "
                f"{len(args) + 1} were given"
            )

        # Set properties from provided positional arguments
        for prop, value in zip(self._props, args):
            setattr(self, f"_{prop}", value)
            already_set.add(prop)

        # Set properties from provided keyword arguments
        for prop, value in kwargs.items():
            if prop in already_set:
                raise TypeError(f"{method} got multiple values for "
                                f"argument {prop!r}")
            if prop not in self._props:
                raise TypeError(f"{method} got an unexpected keyword "
                                f"argument {prop!r}")
            setattr(self, f"_{prop}", value)
            already_set.add(prop)

        # Check for required init arguments not provided
        missing: Set[str] = required - already_set
        if missing:
            raise TypeError("%s missing %d required argument: %s" % (
                method, len(missing), ", ".join((repr(m) for m in missing))))

        # Set default values for properties not provided in arguments
        for prop in set(self._props) - already_set:
            setattr(self, f"_{prop}", self._props[prop][1])


    def __repr__(self) -> str:
        prop_strings = (
            "\033[%dm%s\033[0m=%r" % (
                1 if p == self.mainKey else 0, # 1 = term bold
                p,
                getattr(self, p)
            ) for p in list(self._props.keys()) + self._direct_props
        )
        return "%s(%s)" % (type(self).__name__, ", ".join(prop_strings))


    @pyqtSlot(result=str)
    def repr(self) -> str:
        return self.__repr__()


    @pyqtProperty("QStringList", constant=True)
    def roles(self) -> List[str]:
        return list(self._props.keys()) + self._direct_props


    @pyqtProperty(str, constant=True)
    def mainKey(self) -> str:
        return self._main_key
