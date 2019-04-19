# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import logging
import socket
import ssl
import time
from threading import Lock
from typing import Callable, Optional, Tuple
from uuid import UUID

import nio
import nio.responses as nr
from nio.exceptions import ProtocolError, RemoteTransportError

OptSock        = Optional[ssl.SSLSocket]
NioRequestFunc = Callable[..., Tuple[UUID, bytes]]


class NioErrorResponse(Exception):
    def __init__(self, response: nr.ErrorResponse) -> None:
        self.response = response
        super().__init__(str(response))


class RetrySleeper:
    def __init__(self) -> None:
        self.current_time: float = 0
        self.tries:        int = 0


    def sleep(self, max_time: float) -> None:
        self.current_time = max(
            0, min((max_time / 10) * (2 ^ (self.tries - 1)), max_time)
        )
        time.sleep(self.current_time)
        self.tries += 1


class NetworkManager:
    http_retry_codes = {408, 429, 500, 502, 503, 504, 507}


    def __init__(self, host: str, port: int, nio_client: nio.client.HttpClient
                ) -> None:
        self.host = host
        self.port = port
        self.nio  = nio_client

        self._ssl_context: ssl.SSLContext = ssl.create_default_context()
        self._ssl_session: Optional[ssl.SSLSession] = None
        self._lock: Lock = Lock()


    def _get_socket(self) -> ssl.SSLSocket:
        sock = self._ssl_context.wrap_socket(  # type: ignore
            socket.create_connection((self.host, self.port), timeout=16),
            server_hostname = self.host,
            session         = self._ssl_session,
        )
        self._ssl_session = self._ssl_session or sock.session
        return sock


    @staticmethod
    def _close_socket(sock: Optional[socket.socket]) -> None:
        if not sock:
            return

        try:
            sock.shutdown(how=socket.SHUT_RDWR)
        except OSError:  # Already closer by server
            pass
        sock.close()


    def http_disconnect(self) -> None:
        try:
            self.write(self.nio.disconnect())
        except (OSError, ProtocolError):
            pass


    def read(self, with_sock: OptSock = None) -> nr.Response:
        sock = with_sock or self._get_socket()

        response = None
        while not response:
            left_to_send = self.nio.data_to_send()
            if left_to_send:
                self.write(left_to_send, sock)

            self.nio.receive(sock.recv(4096))
            response = self.nio.next_response()

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


    def talk(self,
             nio_func: NioRequestFunc,
             *args,
             **kwargs) -> nr.Response:
        with self._lock:
            retry = RetrySleeper()

            while True:
                sock = None

                try:
                    sock = self._get_socket()

                    if not self.nio.connection:
                        # Establish HTTP protocol connection:
                        self.write(self.nio.connect(), sock)

                    to_send = nio_func(*args, **kwargs)[1]
                    self.write(to_send, sock)
                    response = self.read(sock)

                except (OSError, RemoteTransportError) as err:
                    logging.error("Connection error for %s: %s",
                                  nio_func.__name__, str(err))
                    self._close_socket(sock)
                    self.http_disconnect()
                    retry.sleep(max_time=2)

                except NioErrorResponse as err:
                    logging.error("Nio response error for %s: %s",
                                  nio_func.__name__, err)
                    self._close_socket(sock)

                    if err.response.status_code in self.http_retry_codes:
                        return response

                    retry.sleep(max_time=10)

                else:
                    return response
