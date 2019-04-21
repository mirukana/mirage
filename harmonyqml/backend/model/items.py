from typing import Any, Callable, Optional, Tuple, Union

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal


class ListItem(QObject):
    roles: Tuple[str, ...] = ()

    def __init__(self, *args, **kwargs):
        super().__init__()

        for role, value in zip(self.roles, args):
            setattr(self, role, value)

        for role, value in kwargs.items():
            setattr(self, role, value)


    def __repr__(self) -> str:
        return "%s(%s)" % (
            type(self).__name__,
            ", ".join((f"{r}={getattr(self, r)!r}" for r in self.roles)),
        )


    @pyqtProperty(str, constant=True)
    def repr(self) -> str:
        return repr(self)


def prop(qt_type:       Union[str, Callable],
         name:          str,
         signal:        Optional[pyqtSignal] = None,
         default_value: Any                  = None) -> pyqtProperty:

    def fget(self, name=name, default_value=default_value):
        if not hasattr(self, f"_{name}"):
            setattr(self, f"_{name}", default_value)
        return getattr(self, f"_{name}")

    def fset(self, value, name=name, signal=signal):
        setattr(self, f"_{name}", value)
        if signal:
            getattr(self, f"{name}Changed").emit(value)

    kws = {"notify": signal} if signal else {"constant": True}

    return pyqtProperty(qt_type, fget=fget, fset=fset, **kws)


class User(ListItem):
    roles = ("userId", "displayName", "avatarUrl", "statusMessage")

    displayNameChanged   = pyqtSignal("QVariant")
    avatarUrlChanged     = pyqtSignal("QVariant")
    statusMessageChanged = pyqtSignal(str)

    userId        = prop(str, "userId")
    displayName   = prop("QVariant", "displayName", displayNameChanged)
    avatarUrl     = prop(str, "avatarUrl", avatarUrlChanged)
    statusMessage = prop(str, "statusMessage", statusMessageChanged, "")


class Room(ListItem):
    roles = ("roomId", "category", "displayName", "topic", "typingUsers")

    categoryChanged    = pyqtSignal(str)
    displayNameChanged = pyqtSignal("QVariant")
    topicChanged       = pyqtSignal(str)
    typingUsersChanged = pyqtSignal("QVariantList")

    roomId      = prop(str, "roomId")
    category    = prop(str, "category")
    displayName = prop(str, "displayName", displayNameChanged)
    topic       = prop(str, "topic", topicChanged, "")
    typingUsers = prop(list, "typingUsers", typingUsersChanged, [])


class RoomEvent(ListItem):
    roles = ("type", "dateTime", "dict", "isLocalEcho")

    type        = prop(str, "type")
    dateTime    = prop("QVariant", "dateTime")
    dict        = prop("QVariantMap", "dict")
    isLocalEcho = prop(bool, "isLocalEcho", None, False)
