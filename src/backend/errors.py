# SPDX-License-Identifier: LGPL-3.0-or-later

"""Custom exception definitions."""

from dataclasses import dataclass, field
from typing import Optional

import nio

# Matrix Errors

@dataclass
class MatrixError(Exception):
    """An error returned by a Matrix server."""

    http_code: int           = 400
    m_code:    Optional[str] = None

    @classmethod
    def from_nio(cls, response: nio.ErrorResponse) -> "MatrixError":
        """Return a `MatrixError` subclass from a nio `ErrorResponse`."""

        # Check for the M_CODE first: some errors for an API share the same
        # http code, but have different M_CODEs (e.g. POST /login 403).
        for subcls in cls.__subclasses__():
            if subcls.m_code and subcls.m_code == response.status_code:
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
class MatrixBadJson(MatrixError):
    http_code: int = 403
    m_code:    str = "M_BAD_JSON"


@dataclass
class MatrixNotJson(MatrixError):
    http_code: int = 403
    m_code:    str = "M_NOT_JSON"


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
class MatrixBadGateway(MatrixError):
    http_code: int = 502
    m_code:    str = ""


# Client errors

@dataclass
class InvalidUserId(Exception):
    user_id: str = field()


@dataclass
class InvalidUserInContext(Exception):
    user_id: str = field()


@dataclass
class UserFromOtherServerDisallowed(Exception):
    user_id: str = field()


@dataclass
class UneededThumbnail(Exception):
    pass


@dataclass
class BadMimeType(Exception):
    wanted: str = field()
    got:    str = field()
