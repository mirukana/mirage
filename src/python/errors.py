from dataclasses import dataclass, field
from typing import Optional

import nio


@dataclass
class MatrixError(Exception):
    http_code: int = 400
    m_code:    str = "M_UNKNOWN"

    @classmethod
    def from_nio(cls, response: nio.ErrorResponse) -> "MatrixError":
        # Check for the M_CODE first: some errors for an API share the same
        # http code, but have different M_CODEs (e.g. POST /login 403).
        for subcls in cls.__subclasses__():
            if subcls.m_code == response.status_code:
                return subcls()

        for subcls in cls.__subclasses__():
            if subcls.http_code == response.transport_response.status:
                return subcls()

        return cls(response.transport_response.status, response.status_code)


@dataclass
class MatrixForbidden(MatrixError):
    http_code: int = 403
    m_code:    str = "M_FORBIDDEN"


@dataclass
class MatrixUserDeactivated(MatrixError):
    http_code: int = 403
    m_code:    str = "M_USER_DEACTIVATED"


@dataclass
class MatrixNotFound(MatrixError):
    http_code: int = 404
    m_code:    str = "M_NOT_FOUND"


@dataclass
class MatrixTooLarge(MatrixError):
    http_code: int = 413
    m_code:    str = "M_TOO_LARGE"


@dataclass
class UserNotFound(Exception):
    user_id: str = field()


@dataclass
class InvalidUserInContext(Exception):
    user_id: str = field()


@dataclass
class UneededThumbnail(Exception):
    pass


@dataclass
class UnthumbnailableError(Exception):
    exception: Optional[Exception] = None


@dataclass
class BadMimeType(Exception):
    wanted: str = field()
    got:    str = field()
