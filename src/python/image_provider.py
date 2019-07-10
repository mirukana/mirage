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

from .app import App

Size      = Tuple[int, int]
ImageData = Tuple[bytearray, Size, int]  # last int: pyotherside format enum


@dataclass
class Thumbnail:
    provider:      "ImageProvider" = field()
    id:            str             = field()
    width:         int             = field()
    height:        int             = field()

    def __post_init__(self) -> None:
        self.id = re.sub(r"#auto$", "", self.id)

        if not re.match(r"^(crop|scale)/mxc://.+/.+", self.id):
            raise ValueError(f"Invalid image ID: {self.id}")


    @property
    def resize_method(self) -> ResizingMethod:
        return ResizingMethod.crop \
               if self.id.startswith("crop/") else ResizingMethod.scale


    @property
    def mxc(self) -> str:
        return re.sub(r"^(crop|scale)/", "", self.id)


    @property
    def http(self) -> str:
        return nio.Api.mxc_to_http(self.mxc)


    @property
    def local_path(self) -> Path:
        parsed = urlparse(self.mxc)
        name   = "%s.%d.%d.%s" % (
            parsed.path.lstrip("/"),
            self.width,
            self.height,
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
            width       = self.width,
            height      = self.height,
            method      = self.resize_method,
        )
        body = response.body

        if response.content_type not in ("image/jpeg", "image/png"):
            with BytesIO(body) as in_, BytesIO() as out:
                PILImage.open(in_).save(out, "PNG")
                body = out.getvalue()

        self.local_path.parent.mkdir(parents=True, exist_ok=True)

        with AtomicFile(str(self.local_path), "wb") as file:
            file.write(body)

        return body


    async def get_data(self) -> ImageData:
        try:
            body = self.local_path.read_bytes()
        except FileNotFoundError:
            body = await self.download()

        size = (self.width, self.height)
        return (bytearray(body), size , pyotherside.format_data)


class ImageProvider:
    def __init__(self, app) -> None:
        self.app = app

        self.cache = Path(self.app.appdirs.user_cache_dir) / "thumbnails"
        self.cache.mkdir(parents=True, exist_ok=True)


    def get(self, image_id: str, requested_size: Size) -> ImageData:
        print("Get image:", image_id, "with size", requested_size)

        width  = 128 if requested_size[0] < 1 else requested_size[0]
        height = width if requested_size[1] < 1 else requested_size[1]
        thumb  = Thumbnail(self, image_id, width, height)

        return asyncio.run_coroutine_threadsafe(
            thumb.get_data(), self.app.loop
        ).result()
