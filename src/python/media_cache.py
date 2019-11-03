import asyncio
import io
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import DefaultDict, Optional, Tuple
from urllib.parse import urlparse

import aiofiles
import nio
from PIL import Image as PILImage

from .matrix_client import MatrixClient

Size = Tuple[int, int]

CONCURRENT_DOWNLOADS_LIMIT                   = asyncio.BoundedSemaphore(8)
ACCESS_LOCKS: DefaultDict[str, asyncio.Lock] = DefaultDict(asyncio.Lock)


@dataclass
class DownloadFailed(Exception):
    message:   str = field()
    http_code: int = field()


@dataclass
class Media:
    cache: "MediaCache" = field()
    mxc:   str          = field()


    def __post_init__(self) -> None:
        self.mxc = re.sub(r"#auto$", "", self.mxc)

        if not re.match(r"^mxc://.+/.+", self.mxc):
            raise ValueError(f"Invalid mxc URI: {self.mxc}")


    @property
    def http(self) -> str:
        return nio.Api.mxc_to_http(self.mxc)


    @property
    def local_path(self) -> Path:
        parsed = urlparse(self.mxc)
        name   = parsed.path.lstrip("/")
        return self.cache.downloads_dir / parsed.netloc / name


    async def get(self) -> Path:
        async with ACCESS_LOCKS[self.mxc]:
            try:
                return await self._get_local_existing_file()
            except FileNotFoundError:
                return await self._download()


    async def _get_local_existing_file(self) -> Path:
        if not self.local_path.exists():
            raise FileNotFoundError()

        return self.local_path


    async def _download(self) -> Path:
        async with CONCURRENT_DOWNLOADS_LIMIT:
            body = await self._get_remote_data()

        self.local_path.parent.mkdir(parents=True, exist_ok=True)

        async with aiofiles.open(self.local_path, "wb") as file:
            await file.write(body)

        return self.local_path


    async def _get_remote_data(self) -> bytes:
        raise NotImplementedError()


@dataclass
class Thumbnail(Media):
    cache:       "MediaCache" = field()
    mxc:         str          = field()
    wanted_size: Size         = field()

    server_size: Optional[Size] = field(init=False, repr=False, default=None)


    @staticmethod
    def normalize_size(size: Size) -> Size:
        # https://matrix.org/docs/spec/client_server/latest#thumbnails

        if size[0] > 640 or size[1] > 480:
            return (800, 600)

        if size[0] > 320 or size[1] > 240:
            return (640, 480)

        if size[0] > 96 or size[1] > 96:
            return (320, 240)

        if size[0] > 32 or size[1] > 32:
            return (96, 96)

        return (32, 32)


    @property
    def local_path(self) -> Path:
        # example: thumbnails/matrix.org/32x32/<mxc id>

        parsed = urlparse(self.mxc)
        size   = self.normalize_size(self.server_size or self.wanted_size)
        name   = "%dx%d/%s" % (size[0], size[1], parsed.path.lstrip("/"))

        return self.cache.thumbs_dir / parsed.netloc / name


    async def _get_local_existing_file(self) -> Path:
        if self.local_path.exists():
            return self.local_path

        # If we have a bigger size thumbnail than the wanted_size for this pic,
        # return it instead of asking the server for a smaller thumbnail.

        try_sizes = ((32, 32), (96, 96), (320, 240), (640, 480), (800, 600))
        parts     = list(self.local_path.parts)
        size      = self.normalize_size(self.server_size or self.wanted_size)

        for width, height in try_sizes:
            if width < size[0] or height < size[1]:
                continue

            parts[-2] = f"{width}x{height}"
            path      = Path("/".join(parts))

            if path.exists():
                return path

        raise FileNotFoundError()



    async def _get_remote_data(self) -> bytes:
        parsed = urlparse(self.mxc)

        resp = await self.cache.client.thumbnail(
            server_name = parsed.netloc,
            media_id    = parsed.path.lstrip("/"),
            width       = self.wanted_size[0],
            height      = self.wanted_size[1],
        )

        with io.BytesIO(resp.body) as img:
            # The server may return a thumbnail bigger than what we asked for
            self.server_size = PILImage.open(img).size

        if isinstance(resp, nio.ErrorResponse):
            raise DownloadFailed(resp.message, resp.status_code)

        return resp.body


@dataclass
class MediaCache:
    client:   MatrixClient = field()
    base_dir: Path         = field()


    def __post_init__(self) -> None:
        self.thumbs_dir    = self.base_dir / "thumbnails"
        self.downloads_dir = self.base_dir / "downloads"

        self.thumbs_dir.mkdir(parents=True, exist_ok=True)
        self.downloads_dir.mkdir(parents=True, exist_ok=True)


    async def thumbnail(self, mxc: str, width: int, height: int) -> str:
        return str(await Thumbnail(self, mxc, (width, height)).get())
