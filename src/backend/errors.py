# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
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
    message:   Optional[str] = None

    @classmethod
    def from_nio(cls, response: nio.ErrorResponse) -> "MatrixError":
        """Return a `MatrixError` subclass from a nio `ErrorResponse`."""

        http_code = response.transport_response.status
        m_code    = response.status_code
        message   = response.message

        for subcls in cls.__subclasses__():
            if subcls.m_code and subcls.m_code == m_code:
                return subcls(http_code, m_code, message)

        # If error doesn't have a M_CODE, look for a generic http error class
        for subcls in cls.__subclasses__():
            if not subcls.m_code and subcls.http_code == http_code:
                return subcls(http_code, m_code, message)

        return cls(http_code, m_code, message)


@dataclass
class MatrixUnrecognized(MatrixError):
    http_code: int = 400
    m_code:    str = "M_UNRECOGNIZED"


@dataclass
class MatrixInvalidAccessToken(MatrixError):
    http_code: int = 401
    m_code:    str = "M_UNKNOWN_TOKEN"


@dataclass
class MatrixUnauthorized(MatrixError):
    http_code: int = 401
    m_code:    str = "M_UNAUTHORIZED"


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
    http_code: int           = 502
    m_code:    Optional[str] = None


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
