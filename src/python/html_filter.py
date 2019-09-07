import re

import mistune
from lxml.html import HtmlElement  # nosec

import html_sanitizer.sanitizer as sanitizer
from html_sanitizer.sanitizer import Sanitizer


class MarkdownRenderer(mistune.Renderer):
    pass


class HtmlFilter:
    link_regexes = [re.compile(r, re.IGNORECASE) for r in [
        (r"(?P<body>[a-zA-Z\d]+://(?P<host>[a-z\d._-]+(?:\:\d+)?)"
         r"(?:/[/\-_.,a-z\d#%&?;=~]*)?(?:\([/\-_.,a-z\d#%&?;=~]*\))?)"),
        r"mailto:(?P<body>[a-z0-9._-]+@(?P<host>[a-z0-9_.-]+[a-z](?:\:\d+)?))",
        r"tel:(?P<body>[0-9+-]+)(?P<host>)",
        r"(?P<body>magnet:\?xt=urn:[a-z0-9]+:.+)(?P<host>)",
    ]]


    def __init__(self) -> None:
        self._sanitizer        = Sanitizer(self.sanitize_settings())
        self._inline_sanitizer = Sanitizer(self.sanitize_settings(inline=True))

        # The whitespace remover doesn't take <pre> into account
        sanitizer.normalize_overall_whitespace = lambda html, *args, **kw: html
        sanitizer.normalize_whitespace_in_text_or_tail = \
            lambda el, *args, **kw: el

        # hard_wrap: convert all \n to <br> without required two spaces
        self._markdown_to_html = mistune.Markdown(
            hard_wrap=True, renderer=MarkdownRenderer(),
        )

        self._markdown_to_html.block.default_rules = [
            rule for rule in self._markdown_to_html.block.default_rules
            if rule != "block_quote"
        ]


    def from_markdown(self, text: str, outgoing: bool = False) -> str:
        return self.filter(self._markdown_to_html(text), outgoing)


    def from_markdown_inline(self, text: str, outgoing: bool = False) -> str:
        return self.filter_inline(self._markdown_to_html(text), outgoing)


    def filter_inline(self, html: str, outgoing: bool = False) -> str:
        text = self._inline_sanitizer.sanitize(html).strip("\n")

        if outgoing:
            return text

        return re.sub(
            r"(^\s*&gt;.*)", r'<span class="quote">\1</span>', text,
        )


    def filter(self, html: str, outgoing: bool = False) -> str:
        html = self._sanitizer.sanitize(html).rstrip("\n")

        if outgoing:
            return html

        return re.sub(
            r"<(p|br/?)>(\s*&gt;.*)(!?</?(?:br|p)/?>)",
            r'<\1><span class="quote">\2</span>\3',
            html,
        )


    def sanitize_settings(self, inline: bool = False) -> dict:
        # https://matrix.org/docs/spec/client_server/latest#m-room-message-msgtypes
        # TODO: mx-reply and the new hidden thing

        inline_tags = {"font", "a", "sup", "sub", "b", "i", "s", "u", "code"}
        tags        = inline_tags | {
            "h1", "h2", "h3", "h4", "h5", "h6","blockquote",
            "p", "ul", "ol", "li", "hr", "br",
            "table", "thead", "tbody", "tr", "th", "td", "pre",
        }

        inlines_attributes = {
            "font": {"color"},
            "a":    {"href"},
            "code": {"class"},
        }
        attributes = {**inlines_attributes, **{
            "ol":   {"start"},
            "hr":   {"width"},
        }}

        return {
            "tags": inline_tags if inline else tags,
            "attributes": inlines_attributes if inline else attributes,
            "empty": {} if inline else {"hr", "br"},
            "separate": {"a"} if inline else {
                "a", "p", "li", "table", "tr", "th", "td", "br", "hr",
            },
            "whitespace": {},
            "keep_typographic_whitespace": True,
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
                sanitizer.tag_replacer("form", "p"),
                sanitizer.tag_replacer("div", "p"),
                sanitizer.tag_replacer("caption", "p"),
                sanitizer.target_blank_noopener,
                self._process_span_font,
                self._img_to_a,
            ],
            "element_postprocessors": [],
            "is_mergeable": lambda e1, e2: e1.attrib == e2.attrib,
        }


    @staticmethod
    def _process_span_font(el: HtmlElement) -> HtmlElement:
        if el.tag not in ("span", "font"):
            return el

        color = el.attrib.pop("data-mx-color", None)
        if color:
            el.tag = "font"
            el.attrib["color"] = color

        return el


    @staticmethod
    def _img_to_a(el: HtmlElement) -> HtmlElement:
        if el.tag == "img":
            el.tag            = "a"
            el.attrib["href"] = el.attrib.pop("src", "")
            el.text           = el.attrib.pop("alt", None) or el.attrib["href"]

        return el


HTML_FILTER = HtmlFilter()
