# SPDX-License-Identifier: LGPL-3.0-or-later

"""Matrix media downloading, caching and retrieval."""

import asyncio
import functools
import io
import re
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Any, DefaultDict, Dict, Optional
from urllib.parse import urlparse

import aiofiles
import nio
from PIL import Image as PILImage

from .utils import Size

if TYPE_CHECKING:
    from .backend import Backend

if sys.version_info < (3, 8):
    import pyfastcopy  # noqa

CryptDict = Optional[Dict[str, Any]]

CONCURRENT_DOWNLOADS_LIMIT                   = asyncio.BoundedSemaphore(8)
ACCESS_LOCKS: DefaultDict[str, asyncio.Lock] = DefaultDict(asyncio.Lock)


@dataclass
class MediaCache:
    """Matrix downloaded media cache."""

    backend:  "Backend" = field()
    base_dir: Path      = field()


    def __post_init__(self) -> None:
        self.thumbs_dir    = self.base_dir / "thumbnails"
        self.downloads_dir = self.base_dir / "downloads"

        self.thumbs_dir.mkdir(parents=True, exist_ok=True)
        self.downloads_dir.mkdir(parents=True, exist_ok=True)


    async def get_media(self, mxc: str, crypt_dict: CryptDict = None) -> Path:
        """Return a `Media` object. Method intended for QML convenience."""

        return await Media(self, mxc, crypt_dict).get()


    async def get_thumbnail(
        self, mxc: str, width: int, height: int, crypt_dict: CryptDict = None,
    ) -> Path:
        """Return a `Thumbnail` object. Method intended for QML convenience."""

        thumb = Thumbnail(
            # QML sometimes pass float sizes, which matrix API doesn't like.
            self, mxc, crypt_dict, (round(width), round(height)),
        )
        return await thumb.get()


@dataclass
class Media:
    """A matrix media file."""

    cache:      "MediaCache" = field()
    mxc:        str          = field()
    crypt_dict: CryptDict    = field(repr=False)


    def __post_init__(self) -> None:
        self.mxc = re.sub(r"#auto$", "", self.mxc)

        if not re.match(r"^mxc://.+/.+", self.mxc):
            raise ValueError(f"Invalid mxc URI: {self.mxc}")


    @property
    def local_path(self) -> Path:
        """The path where the file either exists or should be downloaded."""

        parsed = urlparse(self.mxc)
        name   = parsed.path.lstrip("/")
        return self.cache.downloads_dir / parsed.netloc / name


    async def get(self) -> Path:
        """Return the cached file's path, downloading it first if needed."""

        async with ACCESS_LOCKS[self.mxc]:
            try:
                return await self._get_local_existing_file()
            except FileNotFoundError:
                return await self.create()


    async def _get_local_existing_file(self) -> Path:
        """Return the cached file's path."""

        if not self.local_path.exists():
            raise FileNotFoundError()

        return self.local_path


    async def create(self) -> Path:
        """Download and cache the media file to disk."""

        async with CONCURRENT_DOWNLOADS_LIMIT:
            data = await self._get_remote_data()

        self.local_path.parent.mkdir(parents=True, exist_ok=True)

        async with aiofiles.open(self.local_path, "wb") as file:
            await file.write(data)

        return self.local_path


    async def _get_remote_data(self) -> bytes:
        """Return the file's data from the matrix server, decrypt if needed."""

        parsed = urlparse(self.mxc)

        resp = await self.cache.backend.download(
            server_name = parsed.netloc,
            media_id    = parsed.path.lstrip("/"),
        )

        return await self._decrypt(resp.body)


    async def _decrypt(self, data: bytes) -> bytes:
        """Decrypt an encrypted file's data."""

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


    @classmethod
    async def from_existing_file(
        cls,
        cache:     "MediaCache",
        mxc:       str,
        existing:  Path,
        overwrite: bool = False,
        **kwargs,
    ) -> "Media":
        """Copy an existing file to cache and return a `Media` for it."""

        media = cls(cache, mxc, {}, **kwargs)  # type: ignore
        media.local_path.parent.mkdir(parents=True, exist_ok=True)

        if not media.local_path.exists() or overwrite:
            func = functools.partial(shutil.copy, existing, media.local_path)
            await asyncio.get_event_loop().run_in_executor(None, func)

        return media


    @classmethod
    async def from_bytes(
        cls,
        cache:     "MediaCache",
        mxc:       str,
        data:      bytes,
        overwrite: bool = False,
        **kwargs,
    ) -> "Media":
        """Create a cached file from bytes data and return a `Media` for it."""

        media = cls(cache, mxc, {}, **kwargs)  # type: ignore
        media.local_path.parent.mkdir(parents=True, exist_ok=True)

        if not media.local_path.exists() or overwrite:
            async with aiofiles.open(media.local_path, "wb") as file:
                await file.write(data)

        return media


@dataclass
class Thumbnail(Media):
    """The thumbnail of a matrix media, which is a media itself."""

    cache:       "MediaCache" = field()
    mxc:         str          = field()
    crypt_dict:  CryptDict    = field(repr=False)
    wanted_size: Size         = field()

    server_size: Optional[Size] = field(init=False, repr=False, default=None)


    @staticmethod
    def normalize_size(size: Size) -> Size:
        """Return standard `(width, height)` matrix thumbnail dimensions.

        The Matrix specification defines a few standard thumbnail dimensions
        for homeservers to store and return: 32x32, 96x96, 320x240, 640x480,
        and 800x600.

        This method returns the best matching size for a `size` without
        upscaling, e.g. passing `(641, 480)` will return `(800, 600)`.
        """

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
        """The path where the thumbnail either exists or should be downloaded.

        The returned paths are in this form:
        `<base thumbnail folder>/<homeserver domain>/<standard size>/<mxc id>`,
        e.g. `~/.cache/appname/thumbnails/matrix.org/32x32/Hm24ar11i768b0el`.
        """

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
            # Matrix makes encrypted thumbs only available through the download
            # end-point, not the thumbnail one
            resp = await self.cache.backend.download(
                server_name = parsed.netloc,
                media_id    = parsed.path.lstrip("/"),
            )
        else:
            resp = await self.cache.backend.thumbnail(
                server_name = parsed.netloc,
                media_id    = parsed.path.lstrip("/"),
                width       = self.wanted_size[0],
                height      = self.wanted_size[1],
            )

        decrypted = await self._decrypt(resp.body)

        with io.BytesIO(decrypted) as img:
            # The server may return a thumbnail bigger than what we asked for
            self.server_size = PILImage.open(img).size

        return decrypted
