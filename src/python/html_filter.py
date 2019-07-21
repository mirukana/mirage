# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import re

import mistune
from lxml.html import HtmlElement, etree  # nosec

import html_sanitizer.sanitizer as sanitizer
from html_sanitizer.sanitizer import Sanitizer


class MarkdownRenderer(mistune.Renderer):
    pass


class HtmlFilter:
    link_regexes = [re.compile(r, re.IGNORECASE) for r in [
        (r"(?P<body>[a-zA-Z\d]+://(?P<host>[a-z\d._-]+)"
         r"(?:/[/\-_.,a-z\d%&?;=~]*)?(?:\([/\-_.,a-z\d%&?;=~]*\))?)"),
        r"mailto:(?P<body>[a-z0-9._-]+@(?P<host>[a-z0-9_.-]+[a-z]))",
        r"tel:(?P<body>[0-9+-]+)(?P<host>)",
        r"(?P<body>magnet:\?xt=urn:[a-z0-9]+:.+)(?P<host>)",
    ]]


    def __init__(self) -> None:
        self._sanitizer        = Sanitizer(self.sanitize_settings())
        self._inline_sanitizer = Sanitizer(self.sanitize_settings(inline=True))

        # The whitespace remover doesn't take <pre> into account
        sanitizer.normalize_overall_whitespace         = lambda html: html
        sanitizer.normalize_whitespace_in_text_or_tail = lambda el: el

        # hard_wrap: convert all \n to <br> without required two spaces
        self._markdown_to_html = mistune.Markdown(
            hard_wrap=True, renderer=MarkdownRenderer()
        )

        self._markdown_to_html.block.default_rules = [
            rule for rule in self._markdown_to_html.block.default_rules
            if rule != "block_quote"
        ]


    def from_markdown(self, text: str) -> str:
        return self.filter(self._markdown_to_html(text))


    def from_markdown_inline(self, text: str) -> str:
        return self.filter_inline(self._markdown_to_html(text))


    def filter_inline(self, html: str) -> str:
        text = self._inline_sanitizer.sanitize(html).strip("\n")
        text = re.sub(
            r"(^\s*&gt;.*)", r'<span class="greentext">\1</span>', text
        )
        return text


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

        text = str(result, "utf-8").strip("\n")
        text = re.sub(
            r"<(p|br/?)>(\s*&gt;.+)(!?<(?:br|p)/?>)",
            r'<\1><span class="greentext">\2</span>\3',
            text
        )
        return text


    def sanitize_settings(self, inline: bool = False) -> dict:
        # https://matrix.org/docs/spec/client_server/latest.html#m-room-message-msgtypes
        # TODO: mx-reply, audio, video

        inline_tags = {"font", "a", "sup", "sub", "b", "i", "s", "u", "code"}
        tags        = inline_tags | {
            "h1", "h2", "h3", "h4", "h5", "h6","blockquote",
            "p", "ul", "ol", "li", "hr", "br",
            "table", "thead", "tbody", "tr", "th", "td",
            "pre", "img",
        }

        inlines_attributes = {
            # TODO: translate font attrs to qt html subset
            "font": {"data-mx-bg-color", "data-mx-color"},
            "a":    {"href"},
            "code": {"class"},
        }
        attributes = {**inlines_attributes, **{
            "img":  {"width", "height", "alt", "title", "src"},
            "ol":   {"start"},
        }}

        return {
            "tags": inline_tags if inline else tags,
            "attributes": inlines_attributes if inline else attributes,
            "empty": {} if inline else {"hr", "br", "img"},
            "separate": {"a"} if inline else {
                "a", "p", "li", "table", "tr", "th", "td", "br", "hr"
            },
            "whitespace": {},
            "add_nofollow": False,
            "autolink": {
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

        settings = self.sanitize_settings()
        if not settings["attributes"]["font"] & set(el.keys()):
            el.clear()

        return el


    @staticmethod
    def _wrap_img_in_a(el: HtmlElement) -> HtmlElement:
        link   = el.attrib.get("src", "")
        width  = el.attrib.get("width", "256")
        height = el.attrib.get("height", "256")

        if el.getparent().tag == "a" or el.tag != "img":
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


HTML_FILTER = HtmlFilter()
