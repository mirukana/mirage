import asyncio
import functools
import io
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, DefaultDict, Dict, Optional, Tuple
from urllib.parse import urlparse

import aiofiles
from PIL import Image as PILImage

import nio

from .matrix_client import MatrixClient

CryptDict = Optional[Dict[str, Any]]
Size      = Tuple[int, int]

CONCURRENT_DOWNLOADS_LIMIT                   = asyncio.BoundedSemaphore(8)
ACCESS_LOCKS: DefaultDict[str, asyncio.Lock] = DefaultDict(asyncio.Lock)


@dataclass
class DownloadFailed(Exception):
    message:   str = field()
    http_code: int = field()


@dataclass
class Media:
    cache:      "MediaCache"    = field()
    mxc:        str             = field()
    data:       Optional[bytes] = field(repr=False)
    crypt_dict: CryptDict       = field(repr=False)


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
                return await self.create()


    async def _get_local_existing_file(self) -> Path:
        if not self.local_path.exists():
            raise FileNotFoundError()

        return self.local_path


    async def create(self) -> Path:
        if self.data is None:
            async with CONCURRENT_DOWNLOADS_LIMIT:
                self.data = await self._get_remote_data()

        self.local_path.parent.mkdir(parents=True, exist_ok=True)

        async with aiofiles.open(self.local_path, "wb") as file:
            await file.write(self.data)

        return self.local_path


    async def _get_remote_data(self) -> bytes:
        parsed = urlparse(self.mxc)

        resp = await self.cache.client.download(
            server_name = parsed.netloc,
            media_id    = parsed.path.lstrip("/"),
        )

        if isinstance(resp, nio.DownloadError):
            raise DownloadFailed(resp.message, resp.status_code)

        return await self._decrypt(resp.body)


    async def _decrypt(self, data: bytes) -> bytes:
        if not self.crypt_dict:
            return data

        func = functools.partial(
            nio.crypto.attachments.decrypt_attachment,
            data,
            self.crypt_dict["key"]["k"],
            self.crypt_dict["hashes"]["sha256"],
            self.crypt_dict["iv"],
        )

        # Run in a separate thread
        return await asyncio.get_event_loop().run_in_executor(None, func)


@dataclass
class Thumbnail(Media):
    cache:       "MediaCache"    = field()
    mxc:         str             = field()
    data:        Optional[bytes] = field(repr=False)
    crypt_dict:  CryptDict       = field(repr=False)
    wanted_size: Size            = field()

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

        if self.crypt_dict:
            resp = await self.cache.client.download(
                server_name = parsed.netloc,
                media_id    = parsed.path.lstrip("/"),
            )
        else:
            resp = await self.cache.client.thumbnail(
                server_name = parsed.netloc,
                media_id    = parsed.path.lstrip("/"),
                width       = self.wanted_size[0],
                height      = self.wanted_size[1],
            )

        if isinstance(resp, (nio.DownloadError, nio.ThumbnailError)):
            import remote_pdb; remote_pdb.RemotePdb("127.0.0.1", 4444).set_trace()
            raise DownloadFailed(resp.message, resp.status_code)

        decrypted = await self._decrypt(resp.body)

        with io.BytesIO(decrypted) as img:
            # The server may return a thumbnail bigger than what we asked for
            self.server_size = PILImage.open(img).size

        return decrypted


@dataclass
class MediaCache:
    client:   MatrixClient = field()
    base_dir: Path         = field()


    def __post_init__(self) -> None:
        self.thumbs_dir    = self.base_dir / "thumbnails"
        self.downloads_dir = self.base_dir / "downloads"

        self.thumbs_dir.mkdir(parents=True, exist_ok=True)
        self.downloads_dir.mkdir(parents=True, exist_ok=True)


    async def get_media(self, mxc: str, crypt_dict: CryptDict = None) -> str:
        return str(await Media(self, mxc, None, crypt_dict).get())


    async def get_thumbnail(
        self, mxc: str, width: int, height: int, crypt_dict: CryptDict = None,
    ) -> str:

        thumb = Thumbnail(
            # QML sometimes pass float sizes, which matrix API doesn't like.
            self, mxc, None, crypt_dict, (round(width), round(height)),
        )
        return str(await thumb.get())
