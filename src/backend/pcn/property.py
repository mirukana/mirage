import re
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any, Callable, Dict, Type

if TYPE_CHECKING:
    from .section import Section

TYPE_PROCESSORS: Dict[str, Callable[[Any], Any]] = {
    "tuple": lambda v: tuple(v),
    "set": lambda v: set(v),
}


class Unset:
    pass


@dataclass
class Property:
    name:           str       = field()
    annotation:     str       = field()
    expression:     str       = field()
    section:        "Section" = field()
    value_override: Any       = Unset

    def __get__(self, obj: "Section", objtype: Type["Section"]) -> Any:
        if not obj:
            return self

        if self.value_override is not Unset:
            return self.value_override

        env    = obj.globals
        result = eval(self.expression, dict(env), env)  # nosec

        return process_value(self.annotation, result)

    def __set__(self, obj: "Section", value: Any) -> None:
        self.value_override = value
        obj._edited[self.name] = value


def process_value(annotation: str, value: Any) -> Any:
    annotation = re.sub(r"\[.*\]$", "", annotation)

    if annotation in TYPE_PROCESSORS:
        return TYPE_PROCESSORS[annotation](value)

    if annotation.lower() in TYPE_PROCESSORS:
        return TYPE_PROCESSORS[annotation.lower()](value)

    return value
