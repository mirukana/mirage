import asyncio
import logging as log
import random
import re
from dataclasses import dataclass, field
from io import BytesIO
from pathlib import Path
from typing import Optional, Tuple
from urllib.parse import urlparse

import aiofiles
from PIL import Image as PILImage

import nio
from nio.api import ResizingMethod

from . import pyotherside, utils
from .pyotherside import ImageData, Size

POSFormat = int

CONCURRENT_DOWNLOADS_LIMIT = asyncio.BoundedSemaphore(8)

with BytesIO() as img_out:
    PILImage.new("RGBA", (1, 1), (0, 0, 0, 0)).save(img_out, "PNG")
    TRANSPARENT_1X1_PNG = (img_out.getvalue(), pyotherside.format_data)


@dataclass
class Thumbnail:
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
        parsed = urlparse(self.mxc)
        name   = "%s.%03d.%03d.%s" % (
            parsed.path.lstrip("/"),
            self.server_size[0],
            self.server_size[1],
            self.resize_method.value,
        )
        return self.provider.cache / parsed.netloc / name


    async def read_data(self, data: bytes, mime: Optional[str],
                       ) -> Tuple[bytes, POSFormat]:
        if mime == "image/svg+xml":
            return (data, pyotherside.format_svg_data)

        if mime in ("image/jpeg", "image/png"):
            return (data, pyotherside.format_data)

        try:
            with BytesIO(data) as img_in:
                image = PILImage.open(img_in)

                if image.mode == "RGB":
                    return (data, pyotherside.format_rgb888)

                if image.mode == "RGBA":
                    return (data, pyotherside.format_argb32)

                with BytesIO() as img_out:
                    image.save(img_out, "PNG")
                    return (img_out.getvalue(), pyotherside.format_data)

        except OSError as err:
            log.warning("Unable to process image: %s - %r", self.http, err)
            return TRANSPARENT_1X1_PNG


    async def download(self) -> Tuple[bytes, POSFormat]:
        client = random.choice(
            tuple(self.provider.app.backend.clients.values()),
        )
        parsed = urlparse(self.mxc)

        async with CONCURRENT_DOWNLOADS_LIMIT:
            resp = await client.thumbnail(
                server_name = parsed.netloc,
                media_id    = parsed.path.lstrip("/"),
                width       = self.server_size[0],
                height      = self.server_size[1],
                method      = self.resize_method,
            )

        if isinstance(resp, nio.ThumbnailError):
            log.warning("Downloading thumbnail failed - %s", resp)
            return TRANSPARENT_1X1_PNG

        body, pos_format = await self.read_data(resp.body, resp.content_type)

        self.local_path.parent.mkdir(parents=True, exist_ok=True)

        async with aiofiles.open(self.local_path, "wb") as file:
            # body might have been converted, always save the original image.
            await file.write(resp.body)

        return (body, pos_format)


    async def local_read(self) -> Tuple[bytes, POSFormat]:
        data = self.local_path.read_bytes()
        with BytesIO(data) as data_io:
            return await self.read_data(data, utils.guess_mime(data_io))


    async def get_data(self) -> ImageData:
        try:
            data, pos_format = await self.local_read()
        except (OSError, IOError, FileNotFoundError):
            data, pos_format = await self.download()

        with BytesIO(data) as img_in:
            real_size = PILImage.open(img_in).size

        return (bytearray(data), real_size, pos_format)


class ImageProvider:
    def __init__(self, app) -> None:
        self.app = app

        self.cache = Path(self.app.appdirs.user_cache_dir) / "thumbnails"
        self.cache.mkdir(parents=True, exist_ok=True)


    def get(self, image_id: str, requested_size: Size) -> ImageData:
        if requested_size[0] < 1 or requested_size[1] < 1:
            raise ValueError(f"width or height < 1: {requested_size!r}")

        try:
            thumb = Thumbnail(self, image_id, *requested_size)
        except ValueError as err:
            log.warning(err)
            data, pos_format = TRANSPARENT_1X1_PNG
            return (bytearray(data), (1, 1), pos_format)

        return asyncio.run_coroutine_threadsafe(
            thumb.get_data(), self.app.loop,
        ).result()
