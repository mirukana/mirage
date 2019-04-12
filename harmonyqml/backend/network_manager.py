# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import logging
import socket
import ssl
import time
from typing import Callable, Optional, Tuple
from uuid import UUID

import nio.responses as nr

from .client import Client

OptSock        = Optional[ssl.SSLSocket]
NioRequestFunc = Callable[..., Tuple[UUID, bytes]]


class NioErrorResponse(Exception):
    def __init__(self, response: nr.ErrorResponse) -> None:
        self.response = response
        super().__init__(str(response))


class NetworkManager:
    http_retry_codes = {408, 429, 500, 502, 503, 504, 507}


    def __init__(self, client: Client) -> None:
        self.client = client
        self._ssl_context: ssl.SSLContext = ssl.create_default_context()
        self._ssl_session: Optional[ssl.SSLSession] = None


    def _get_socket(self) -> ssl.SSLSocket:
        sock = self._ssl_context.wrap_socket(  # type: ignore
            socket.create_connection((self.client.host, self.client.port)),
            server_hostname = self.client.host,
            session         = self._ssl_session,
        )
        self._ssl_session = self._ssl_session or sock.session
        return sock


    @staticmethod
    def _close_socket(sock: socket.socket) -> None:
        sock.shutdown(how=socket.SHUT_RDWR)
        sock.close()


    def read(self, with_sock: OptSock = None) -> nr.Response:
        sock = with_sock or self._get_socket()

        response = None
        while not response:
            self.client.nio.receive(sock.recv(4096))
            response = self.client.nio.next_response()

        if isinstance(response, nr.ErrorResponse):
            raise NioErrorResponse(response)

        if not with_sock:
            self._close_socket(sock)

        return response


    def write(self, data: bytes, with_sock: OptSock = None) -> None:
        sock = with_sock or self._get_socket()
        sock.sendall(data)

        if not with_sock:
            self._close_socket(sock)


    def talk(self, nio_func: NioRequestFunc, *args, **kwargs) -> nr.Response:
        while True:
            to_send = nio_func(*args, **kwargs)[1]
            sock    = self._get_socket()

            try:
                self.write(to_send, sock)
                response = self.read(sock)

            except NioErrorResponse as err:
                logging.error("read bad response for %s: %s", nio_func, err)
                self._close_socket(sock)
                if self._should_abort_talk(err):
                    logging.error("aborting talk")
                    break
                time.sleep(10)

            except Exception as err:
                logging.error("talk exception for %s: %r", nio_func, err)
                break

            else:
                break

        self._close_socket(sock)
        return response


    def _should_abort_talk(self, err: NioErrorResponse) -> bool:
        if err.response.status_code in self.http_retry_codes:
            return False
        return True
