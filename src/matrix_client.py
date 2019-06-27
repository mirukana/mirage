from typing import Optional

import nio


class MatrixClient(nio.AsyncClient):
    def __init__(self,
                 user:       str,
                 homeserver: str           = "https://matrix.org",
                 device_id:  Optional[str] = None) -> None:

        super().__init__(homeserver=homeserver, user=user, device_id=device_id)


    def __repr__(self) -> str:
        return "%s(user_id=%r, homeserver=%r, device_id=%r)" % (
            type(self).__name__, self.user_id, self.homeserver, self.device_id
        )


    async def resume(self, user_id: str, token: str, device_id: str) -> None:
        self.receive_response(nio.LoginResponse(user_id, device_id, token))
