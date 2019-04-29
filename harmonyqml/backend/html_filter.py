# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import re

import mistune
from lxml.html import HtmlElement, etree  # nosec
from PyQt5.QtCore import QObject, pyqtProperty, pyqtSlot

import html_sanitizer.sanitizer as sanitizer


class HtmlFilter(QObject):
    link_regexes = [re.compile(r, re.IGNORECASE) for r in [
        (r"(?P<body>.+://(?P<host>[a-z0-9._-]+)(?:/[/\-_.,a-z0-9%&?;=~]*)?"
         r"(?:\([/\-_.,a-z0-9%&?;=~]*\))?)"),
        r"mailto:(?P<body>[a-z0-9._-]+@(?P<host>[a-z0-9_.-]+[a-z]))",
        r"tel:(?P<body>[0-9+-]+)(?P<host>)",
        r"(?P<body>magnet:\?xt=urn:[a-z0-9]+:.+)(?P<host>)",
    ]]


    def __init__(self, parent: QObject) -> None:
        super().__init__(parent)
        self._sanitizer = sanitizer.Sanitizer(self.sanitizer_settings)

        # The whitespace remover doesn't take <pre> into account
        sanitizer.normalize_overall_whitespace         = lambda html: html
        sanitizer.normalize_whitespace_in_text_or_tail = lambda el: el

        # hard_wrap: convert all \n to <br> without required two spaces
        self._markdown_to_html = mistune.Markdown(hard_wrap=True)


    @pyqtSlot(str, result=str)
    def fromMarkdown(self, text: str) -> str:
        return self.filter(self._markdown_to_html(text))


    @pyqtSlot(str, result=str)
    def filter(self, html: str) -> str:
        html = self._sanitizer.sanitize(html)
        tree = etree.fromstring(html, parser=etree.HTMLParser())

        if tree is None:
            return ""

        for el in tree.iter("img"):
            el = self._wrap_img_in_a(el)

        for el in tree.iter("a"):
            el = self._append_img_to_a(el)

        result = b"".join((etree.tostring(el, encoding="utf-8")
                           for el in tree[0].iterchildren()))

        return str(result, "utf-8")


    @pyqtProperty("QVariant")
    def sanitizer_settings(self) -> dict:
        # https://matrix.org/docs/spec/client_server/latest.html#m-room-message-msgtypes
        return {
            "tags": {
                # TODO: mx-reply, audio, video
                "font", "h1", "h2", "h3", "h4", "h5", "h6",
                "blockquote", "p", "a", "ul", "ol", "sup", "sub", "li",
                "b", "i", "s", "u", "code", "hr", "br",
                "table", "thead", "tbody", "tr", "th", "td",
                "pre", "img",
            },
            "attributes": {
                # TODO: translate font attrs to qt html subset
                "font": {"data-mx-bg-color", "data-mx-color"},
                "a":    {"href"},
                "img":  {"width", "height", "alt", "title", "src"},
                "ol":   {"start"},
                "code": {"class"},
            },
            "empty": {"hr", "br", "img"},
            "separate": {
                "a", "p", "li", "table", "tr", "th", "td", "br", "hr"
            },
            "whitespace": {},
            "add_nofollow": False,
            "autolink": {  # FIXME: arg dict not working
                "link_regexes": self.link_regexes,
                "avoid_hosts": [],
            },
            "sanitize_href": lambda href: href,
            "element_preprocessors": [
                sanitizer.bold_span_to_strong,
                sanitizer.italic_span_to_em,
                sanitizer.tag_replacer("strong", "b"),
                sanitizer.tag_replacer("em", "i"),
                sanitizer.tag_replacer("strike", "s"),
                sanitizer.tag_replacer("del", "s"),
                sanitizer.tag_replacer("span", "font"),
                self._remove_empty_font,
                sanitizer.tag_replacer("form", "p"),
                sanitizer.tag_replacer("div", "p"),
                sanitizer.tag_replacer("caption", "p"),
                sanitizer.target_blank_noopener,
            ],
            "element_postprocessors": [],
            "is_mergeable": lambda e1, e2: e1.attrib == e2.attrib,
        }


    def _remove_empty_font(self, el: HtmlElement) -> HtmlElement:
        if el.tag != "font":
            return el

        if not self.sanitizer_settings["attributes"]["font"] & set(el.keys()):
            el.clear()

        return el


    def _wrap_img_in_a(self, el: HtmlElement) -> HtmlElement:
        link   = el.attrib.get("src", "")
        width  = el.attrib.get("width", "256")
        height = el.attrib.get("height", "256")

        if el.getparent().tag == "a" or el.tag != "img" or \
           not self._is_image_path(link):
            return el

        el.tag    = "a"
        el.attrib.clear()
        el.attrib["href"] = link
        el.append(etree.Element("img", src=link, width=width, height=height))
        return el


    def _append_img_to_a(self, el: HtmlElement) -> HtmlElement:
        link = el.attrib.get("href", "")

        if not (el.tag == "a" and self._is_image_path(link)):
            return el

        for _ in el.iter("img"):  # if the <a> already has an <img> child
            return el

        el.append(etree.Element("br"))
        el.append(etree.Element("img", src=link, width="256", height="256"))
        return el


    @staticmethod
    def _is_image_path(link: str) -> bool:
        return bool(re.match(
            r".+\.(jpg|jpeg|png|gif|bmp|webp|tiff|svg)$", link, re.IGNORECASE
        ))
