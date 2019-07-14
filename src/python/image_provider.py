# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import asyncio
import random
import re
from io import BytesIO
from pathlib import Path
from typing import Tuple
from urllib.parse import urlparse

from atomicfile import AtomicFile
from dataclasses import dataclass, field
from PIL import Image as PILImage

import nio
import pyotherside
from nio.api import ResizingMethod

Size      = Tuple[int, int]
ImageData = Tuple[bytearray, Size, int]  # last int: pyotherside format enum


@dataclass
class Thumbnail:
    # pylint: disable=no-member
    provider: "ImageProvider" = field()
    mxc:      str             = field()
    width:    int             = field()
    height:   int             = field()

    def __post_init__(self) -> None:
        self.mxc = re.sub(r"#auto$", "", self.mxc)

        if not re.match(r"^mxc://.+/.+", self.mxc):
            raise ValueError(f"Invalid mxc URI: {self.mxc}")


    @property
    def server_size(self) -> Tuple[int, int]:
        # https://matrix.org/docs/spec/client_server/latest#thumbnails

        if self.width > 640 or self.height > 480:
            return (800, 600)

        if self.width > 320 or self.height > 240:
            return (640, 480)

        if self.width > 96 or self.height > 96:
            return (320, 240)

        if self.width > 32 or self.height > 32:
            return (96, 96)

        return (32, 32)


    @property
    def resize_method(self) -> ResizingMethod:
        return ResizingMethod.scale \
               if self.width > 96 or self.height > 96 else ResizingMethod.crop


    @property
    def http(self) -> str:
        return nio.Api.mxc_to_http(self.mxc)


    @property
    def local_path(self) -> Path:
        # pylint: disable=bad-string-format-type
        parsed = urlparse(self.mxc)
        name   = "%s.%03d.%03d.%s" % (
            parsed.path.lstrip("/"),
            self.server_size[0],
            self.server_size[1],
            self.resize_method.value,
        )
        return self.provider.cache / parsed.netloc / name


    async def download(self) -> bytes:
        client = random.choice(
            tuple(self.provider.app.backend.clients.values())
        )
        parsed = urlparse(self.mxc)

        response = await client.thumbnail(
            server_name = parsed.netloc,
            media_id    = parsed.path.lstrip("/"),
            width       = self.server_size[0],
            height      = self.server_size[1],
            method      = self.resize_method,
        )
        body = response.body

        if response.content_type not in ("image/jpeg", "image/png"):
            with BytesIO(body) as img_in, BytesIO() as img_out:
                PILImage.open(img_in).save(img_out, "PNG")
                body = img_out.getvalue()

        self.local_path.parent.mkdir(parents=True, exist_ok=True)

        with AtomicFile(str(self.local_path), "wb") as file:
            file.write(body)

        return body


    async def get_data(self) -> ImageData:
        try:
            body = self.local_path.read_bytes()
        except FileNotFoundError:
            body = await self.download()

        with BytesIO(body) as img_in:
            real_size = PILImage.open(img_in).size

        return (bytearray(body), real_size, pyotherside.format_data)


class ImageProvider:
    def __init__(self, app) -> None:
        self.app = app

        self.cache = Path(self.app.appdirs.user_cache_dir) / "thumbnails"
        self.cache.mkdir(parents=True, exist_ok=True)


    def get(self, image_id: str, requested_size: Size) -> ImageData:
        if requested_size[0] < 1 or requested_size[1] < 1:
            raise ValueError(f"width or height < 1: {requested_size!r}")

        return asyncio.run_coroutine_threadsafe(
            Thumbnail(self, image_id, *requested_size).get_data(),
            self.app.loop
        ).result()
