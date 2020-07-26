# SPDX-License-Identifier: LGPL-3.0-or-later

import asyncio
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, quote, urlparse
from . import __display_name__

_SUCCESS_HTML_PAGE = """<!DOCTYPE html>
<html>
    <head>
        <title>""" + __display_name__ + """</title>
        <meta charset="utf-8">
        <style>
            body { background: hsl(0, 0%, 90%); }

            @keyframes appear {
                0% { transform: scale(0); }
                45% { transform: scale(0); }
                80% { transform: scale(1.6); }
                100% { transform: scale(1); }
            }

            .circle {
                width: 90px;
                height: 90px;
                position: absolute;
                top: 50%;
                left: 50%;
                margin: -45px 0 0 -45px;
                border-radius: 50%;
                font-size: 60px;
                line-height: 90px;
                text-align: center;
                background: hsl(203, 51%, 15%);
                color: hsl(162, 56%, 42%, 1);
                animation: appear 0.4s linear;
            }
        </style>
    </head>

    <body><div class="circle">✓</div></body>
</html>"""


class _SSORequestHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        parameters = parse_qs(urlparse(self.path).query)

        if "loginToken" in parameters:
            self.server._token = parameters["loginToken"][0]  # type: ignore
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(_SUCCESS_HTML_PAGE.encode())
        else:
            self.send_error(400, "missing loginToken parameter")

        self.close_connection = True


class SSOServer(HTTPServer):
    """Local HTTP server to retrieve a SSO login token.

    Call `SSOServer.wait_for_token()` in a background task to start waiting
    for a SSO login token from the Matrix homeserver.

    Once the task is running, the user must open `SSOServer.url_to_open` in
    their browser, where they will be able to complete the login process.
    Once they are done, the homeserver will call us back with a login token
    and the `SSOServer.wait_for_token()` task will return.
    """

    def __init__(self, for_homeserver: str) -> None:
        self.for_homeserver: str = for_homeserver
        self._token:         str = ""

        # Pick the first available port
        super().__init__(("127.0.0.1", 0), _SSORequestHandler)


    @property
    def url_to_open(self) -> str:
        """URL for the user to open in their browser, to do the SSO process."""

        return "%s/_matrix/client/r0/login/sso/redirect?redirectUrl=%s" % (
            self.for_homeserver,
            quote(f"http://{self.server_address[0]}:{self.server_port}/"),
        )


    async def wait_for_token(self) -> str:
        """Wait until the homeserver gives us a login token and return it."""

        loop = asyncio.get_event_loop()

        while not self._token:
            await loop.run_in_executor(None, self.handle_request)

        return self._token
