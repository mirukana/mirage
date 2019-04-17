# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

import re

import html_sanitizer.sanitizer as sanitizer
from lxml.html import HtmlElement
from PyQt5.QtCore import QObject, pyqtProperty, pyqtSlot


class HtmlFilter(QObject):
    link_regexes = [re.compile(r, re.IGNORECASE) for r in [
        (r"(?P<body>.+://(?P<host>[a-z0-9._-]+)(?:/[/\-_.,a-z0-9%&?;=~]*)?"
         r"(?:\([/\-_.,a-z0-9%&?;=~]*\))?)"),
        r"mailto:(?P<body>[a-z0-9._-]+@(?P<host>[a-z0-9_.-]+[a-z]))",
        r"tel:(?P<body>[0-9+-]+)(?P<host>)",
        r"(?P<body>magnet:\?xt=urn:[a-z0-9]+:.+)(?P<host>)",
    ]]


    def __init__(self) -> None:
        super().__init__()
        self._sanitizer = sanitizer.Sanitizer(self.sanitizer_settings)

        # The whitespace remover doesn't take <pre> into account
        sanitizer.normalize_overall_whitespace         = lambda html: html
        sanitizer.normalize_whitespace_in_text_or_tail = lambda el: el

        # See FIXME note in sanitizer_settings
        autolink_func = sanitizer.lxml.html.clean.autolink
        sanitizer.lxml.html.clean.autolink = \
            lambda el, **kw: autolink_func(
                el, **self.sanitizer_settings["autolink"]
            )

        # Prevent custom attributes from being removed
        sanitizer.lxml.html.clean.Cleaner.safe_attrs |= \
            self.sanitizer_settings["attributes"]["font"]


    @pyqtSlot(str, result=str)
    def sanitize(self, html: str) -> str:
        return self._sanitizer.sanitize(html)


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
            "sanitize_href": sanitizer.sanitize_href,
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
