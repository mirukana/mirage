from collections import UserDict
from typing import TYPE_CHECKING, Any, Dict, Iterator

if TYPE_CHECKING:
    from .section import Section

from .. import color

PCN_GLOBALS: Dict[str, Any] = {
    "color":  color.Color,
    "hsluv":  color.hsluv,
    "hsluva": color.hsluva,
    "hsl":    color.hsl,
    "hsla":   color.hsla,
    "rgb":    color.rgb,
    "rgba":   color.rgba,
}


class GlobalsDict(UserDict):
    def __init__(self, section: "Section") -> None:
        super().__init__()
        self.section = section

    @property
    def full_dict(self) -> Dict[str, Any]:
        return {
            **PCN_GLOBALS,
            **(self.section.root if self.section.root else {}),
            **(self.section.root.globals if self.section.root else {}),
            "self": self.section,
            "parent": self.section.parent,
            "root": self.section.parent,
            **self.data,
        }

    def __getitem__(self, key: str) -> Any:
        return self.full_dict[key]

    def __iter__(self) -> Iterator[str]:
        return iter(self.full_dict)

    def __len__(self) -> int:
        return len(self.full_dict)

    def __repr__(self) -> str:
        return repr(self.full_dict)
