# SPDX-License-Identifier: LGPL-3.0-or-later

"""HTML and Markdown processing tools."""

import re
from typing import DefaultDict, Dict, List, Tuple
from urllib.parse import unquote

import html_sanitizer.sanitizer as sanitizer
import lxml.html  # nosec
import mistune
from html_sanitizer.sanitizer import Sanitizer
from lxml.html import HtmlElement, etree  # nosec

from .svg_colors import SVG_COLORS


class MarkdownInlineGrammar(mistune.InlineGrammar):
    """Markdown inline elements syntax modifications for the Mistune parser.

    Modifications:

    - Disable underscores for bold/italics (e.g. `__bold__`)

    - Add syntax for coloring text: `<color>(text)`,
      e.g. `<red>(Lorem ipsum)` or `<#000040>(sit dolor amet...)`
    """

    escape          = re.compile(r"^\\([\\`*{}\[\]()#+\-.!_<>~|])")  # Add <
    emphasis        = re.compile(r"^\*((?:\*\*|[^\*])+?)\*(?!\*)")
    double_emphasis = re.compile(r"^\*{2}([\s\S]+?)\*{2}(?!\*)")

    # test string: r"<b>(x) <r>(x) \<a>b>(x) <a\>b>(x) <b>(\(z) <c>(foo\)xyz)"
    color = re.compile(
        r"^<(.+?)>"          # capture the color in `<color>`
        r"\((.+?)"           # capture text in `(text`
        r"(?<!\\)(?:\\\\)*"  # ignore the next `)` if it's \escaped
        r"\)",               # finish on a `)`
    )


class MarkdownInlineLexer(mistune.InlineLexer):
    """Apply the changes from `MarkdownInlineGrammar` for Mistune."""

    grammar_class = MarkdownInlineGrammar

    default_rules = [
        "escape", "color", "autolink", "url",  # Add color
        "footnote", "link", "reflink", "nolink",
        "double_emphasis", "emphasis", "code",
        "linebreak", "strikethrough", "text",
    ]
    inline_html_rules = [
        "escape", "color", "autolink", "url", "link", "reflink",  # Add color
        "nolink", "double_emphasis", "emphasis", "code",
        "linebreak", "strikethrough", "text",
    ]


    def output_double_emphasis(self, m):
        return self.renderer.double_emphasis(self.output(m.group(1)))


    def output_emphasis(self, m):
        return self.renderer.emphasis(self.output(m.group(1)))


    def output_color(self, m):
        color = m.group(1)
        text  = self.output(m.group(2))
        return self.renderer.color(color, text)


class MarkdownRenderer(mistune.Renderer):
    def color(self, color: str, text: str):
        """Render given text with a color using `<span data-mx-color=#hex>`."""

        # This may be a color name, try to get a #hex code for it.
        color = SVG_COLORS.get(re.sub(r"\s", "", color.lower()), color)

        return f'<span data-mx-color="{color}">{text}</span>'


class HTMLProcessor:
    """Provide HTML filtering and conversion from Markdown.

    Filtering sanitizes HTML and ensures it complies both with the Matrix
    specification:
    https://matrix.org/docs/spec/client_server/latest#m-room-message-msgtypes
    and the supported Qt HTML subset for usage in QML:
    https://doc.qt.io/qt-5/richtext-html-subset.html

    Some methods take an `outgoing` argument, specifying if the HTML is
    intended to be sent to matrix servers or used locally in our application.

    For local usage, extra transformations are applied:

    - Wrap text lines starting with a `>` in `<span>` with a `quote` class.
      This allows them to be styled appropriately from QML.

    Some methods take an `inline` argument, which return text appropriate
    for UI elements restricted to display a single line, e.g. the room
    last message subtitles in QML or notifications.
    In inline filtered HTML, block tags are stripped or substituted and
    newlines are turned into ⏎ symbols (U+23CE).
    """

    inline_tags = {
        "span", "font", "a", "sup", "sub", "b", "i", "s", "u", "code",
    }

    block_tags = {
        "h1", "h2", "h3", "h4", "h5", "h6","blockquote",
        "p", "ul", "ol", "li", "hr", "br",
        "table", "thead", "tbody", "tr", "th", "td", "pre",
    }

    opaque_id         = r"[a-zA-Z\d._-]+?"
    user_id_localpart = r"[\x21-\x39\x3D-\x7E]+?"

    user_id_regex = re.compile(
        rf"(?P<body>@{user_id_localpart}:(?P<host>[a-zA-Z\d.-:]*[a-zA-Z\d]))",
    )
    room_id_regex = re.compile(
        rf"(?P<body>!{opaque_id}:(?P<host>[a-zA-Z\d.-:]*[a-zA-Z\d]))",
    )
    room_alias_regex = re.compile(
        r"(?=^|\W)(?P<body>#\S+?:(?P<host>[a-zA-Z\d.-:]*[a-zA-Z\d]))",
    )

    link_regexes = [re.compile(r, re.IGNORECASE)
                    if isinstance(r, str) else r for r in [
        # Normal :// URLs
        (r"(?P<body>[a-zA-Z\d]+://(?P<host>[a-z\d._-]+(?:\:\d+)?)"
         r"(?:/[/\-_.,a-z\d#%&?;=~]*)?(?:\([/\-_.,a-z\d#%&?;=~]*\))?)"),

        # mailto: and tel:
        r"mailto:(?P<body>[a-z0-9._-]+@(?P<host>[a-z0-9.-:]*[a-z\d]))",
        r"tel:(?P<body>[0-9+-]+)(?P<host>)",

        # magnet:
        r"(?P<body>magnet:\?xt=urn:[a-z0-9]+:.+)(?P<host>)",

        user_id_regex, room_id_regex, room_alias_regex,
    ]]

    link_is_matrix_to_regex = re.compile(
        r"https?://matrix.to/#/\S+", re.IGNORECASE,
    )
    link_is_user_id_regex = re.compile(
        r"https?://matrix.to/#/@\S+", re.IGNORECASE,
    )
    link_is_room_id_regex = re.compile(
        r"https?://matrix.to/#/!\S+", re.IGNORECASE,
    )
    link_is_room_alias_regex = re.compile(
        r"https?://matrix.to/#/#\S+", re.IGNORECASE,
    )
    link_is_message_id_regex = re.compile(
        r"https?://matrix.to/#/[!#]\S+/\$\S+", re.IGNORECASE,
    )

    inline_quote_regex = re.compile(r"(^|⏎)(\s*&gt;[^⏎\n]*)", re.MULTILINE)

    quote_regex = re.compile(
        r"(^|<span/?>|<p/?>|<br/?>|<h\d/?>)"
        r"(\s*&gt;.*?)"
        r"(<span/?>|</?p>|<br/?>|</?h\d>|$)",
        re.MULTILINE,
    )

    extra_newlines_regex = re.compile(r"\n(\n*)")

    # {room_id: {user_id: username}}
    rooms_user_id_names: DefaultDict[str, Dict[str, str]] = DefaultDict(dict)


    def __init__(self) -> None:
        # The whitespace remover doesn't take <pre> into account
        sanitizer.normalize_overall_whitespace = lambda html, *args, **kw: html
        sanitizer.normalize_whitespace_in_text_or_tail = \
            lambda el, *args, **kw: el

        # hard_wrap: convert all \n to <br> without required two spaces
        # escape: escape HTML characters in the input string, e.g. tags
        self._markdown_to_html = mistune.Markdown(
            hard_wrap=True,
            escape=True,
            inline=MarkdownInlineLexer,
            renderer=MarkdownRenderer(),
        )

        self._markdown_to_html.block.default_rules = [
            rule for rule in self._markdown_to_html.block.default_rules
            if rule != "block_quote"
        ]


    def mentions_in_html(self, html: str) -> List[Tuple[str, str]]:
        """Return list of (text, href) tuples for all mention links in html."""

        if not html.strip():
            return []

        return [
            (a_tag.text, href)
            for a_tag, _, href, _ in lxml.html.iterlinks(html)
            if a_tag.text and
               self.link_is_matrix_to_regex.match(unquote(href.strip()))
        ]


    def user_id_link_in_html(self, html: str, user_id: str) -> bool:
        """Return whether html contains a mention link for user_id."""

        regex = re.compile(rf"https?://matrix.to/#/{user_id}", re.IGNORECASE)

        for _, href in self.mentions_in_html(html):
            if regex.match(unquote(href.strip())):
                return True

        return False


    def from_markdown(
        self,
        text:     str,
        inline:   bool = False,
        outgoing: bool = False,
        room_id:  str  = "",
    ) -> str:
        """Return filtered HTML from Markdown text."""

        return self.filter(
            self._markdown_to_html(text),
            inline,
            outgoing,
            room_id,
        )


    def filter(
        self,
        html:     str,
        inline:   bool = False,
        outgoing: bool = False,
        room_id:  str  = "",
    ) -> str:
        """Filter and return HTML."""

        sanit = Sanitizer(self.sanitize_settings(inline, outgoing, room_id))
        html  = sanit.sanitize(html).rstrip("\n")

        if not html.strip():
            return html

        tree = etree.fromstring(
            html, parser=etree.HTMLParser(encoding="utf-8"),
        )

        for a_tag in tree.iterdescendants("a"):
            self._mentions_to_matrix_to_links(a_tag, room_id, outgoing)

            if not outgoing:
                self._matrix_to_links_add_classes(a_tag)

        html = etree.tostring(tree, encoding="utf-8", method="html").decode()
        html = sanit.sanitize(html).rstrip("\n")

        if outgoing:
            return html

        # Client-side modifications

        html = self.quote_regex.sub(r'\1<span class="quote">\2</span>\3', html)

        if not inline:
            return html

        return self.inline_quote_regex.sub(
            r'\1<span class="quote">\2</span>', html,
        )



    def sanitize_settings(
        self, inline: bool = False, outgoing: bool = False, room_id: str = "",
    ) -> dict:
        """Return an html_sanitizer configuration."""

        # https://matrix.org/docs/spec/client_server/latest#m-room-message-msgtypes
        # TODO: mx-reply and the new hidden thing

        inline_tags = self.inline_tags
        all_tags    = inline_tags | self.block_tags

        inlines_attributes = {
            "font": {"color"},
            "a":    {"href", "class", "data-mention"},
            "code": {"class"},
        }
        attributes = {**inlines_attributes, **{
            "ol":   {"start"},
            "hr":   {"width"},
            "span": {"data-mx-color"},
        }}

        username_link_regexes = []

        if outgoing:
            username_link_regexes = [re.compile(r) for r in [
                rf"(?<!\w)(?P<body>{re.escape(username)})(?!\w)(?P<host>)"
                for username in self.rooms_user_id_names[room_id].values()
            ]]

        return {
            "tags": inline_tags if inline else all_tags,
            "attributes": inlines_attributes if inline else attributes,
            "empty": {} if inline else {"hr", "br"},
            "separate": {"a"} if inline else {
                "a", "p", "li", "table", "tr", "th", "td", "br", "hr",
            },
            "whitespace": {},
            "keep_typographic_whitespace": True,
            "add_nofollow": False,
            "autolink": {
                "link_regexes":
                    self.link_regexes + username_link_regexes,  # type: ignore
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

                self._span_color_to_font if not outgoing else lambda el: el,

                self._img_to_a,
                self._remove_extra_newlines,
                self._newlines_to_return_symbol if inline else lambda el: el,
            ],
            "element_postprocessors": [
                self._font_color_to_span if outgoing else lambda el: el,
            ],
            "is_mergeable": lambda e1, e2: e1.attrib == e2.attrib,
        }


    @staticmethod
    def _span_color_to_font(el: HtmlElement) -> HtmlElement:
        """Convert HTML `<span data-mx-color=...` to `<font color=...>`."""

        if el.tag not in ("span", "font"):
            return el

        color = el.attrib.pop("data-mx-color", None)
        if color:
            el.tag = "font"
            el.attrib["color"] = color

        return el


    @staticmethod
    def _font_color_to_span(el: HtmlElement) -> HtmlElement:
        """Convert HTML `<font color=...>` to `<span data-mx-color=...`."""

        if el.tag not in ("span", "font"):
            return el

        color = el.attrib.pop("color", None)
        if color:
            el.tag = "span"
            el.attrib["data-mx-color"] = color

        return el


    @staticmethod
    def _img_to_a(el: HtmlElement) -> HtmlElement:
        """Linkify images by wrapping `<img>` tags in `<a>`."""

        if el.tag == "img":
            el.tag            = "a"
            el.attrib["href"] = el.attrib.pop("src", "")
            el.text           = el.attrib.pop("alt", None) or el.attrib["href"]

        return el


    def _remove_extra_newlines(self, el: HtmlElement) -> HtmlElement:
        r"""Remove excess `\n` characters from HTML elements.

        This is done to avoid additional blank lines when the CSS directive
        `white-space: pre` is used.

        Text inside `<pre>` tags is ignored, except for the final newlines.
        """

        pre_parent = any(parent.tag == "pre" for parent in el.iterancestors())

        if el.tag != "pre" and not pre_parent:
            if el.text:
                el.text = self.extra_newlines_regex.sub(r"\1", el.text)
            if el.tail:
                el.tail = self.extra_newlines_regex.sub(r"\1", el.tail)
        else:
            if el.text and el.text.endswith("\n"):
                el.text = el.text[:-1]
            if el.tail and el.tail.endswith("\n"):
                el.tail = el.tail[:-1]

        return el


    def _newlines_to_return_symbol(self, el: HtmlElement) -> HtmlElement:
        """Turn newlines into unicode return symbols (⏎, U+23CE).

        The symbol is added to blocks with siblings (e.g. a `<p>` followed by
        another `<p>`) and `<br>` tags.
        The `<br>` themselves will be removed by the inline sanitizer.
        """

        is_block_with_siblings = (el.tag in self.block_tags and
                                  next(el.itersiblings(), None) is not None)

        if el.tag == "br" or is_block_with_siblings:
            el.tail = f" ⏎ {el.tail or ''}"


        # Replace left \n in text/tail of <pre> content by the return symbol.
        if el.text:
            el.text = re.sub(r"\n", r" ⏎ ", el.text)

        if el.tail:
            el.tail = re.sub(r"\n", r" ⏎ ", el.tail)

        return el


    def _mentions_to_matrix_to_links(
        self, el: HtmlElement, room_id: str = "", outgoing: bool = False,
    ) -> HtmlElement:
        """Turn user ID/names and room ID/aliases into matrix.to URL.

        After the HTML sanitizer autolinks these, the links's hrefs will be the
        link text, e.g. `<a href="@foo:bar.com">@foo:bar.com</a>`.
        We turn them into proper matrix.to URL in this function.
        """

        if el.tag != "a" or not el.attrib.get("href"):
            return el

        id_regexes = (
            self.user_id_regex, self.room_id_regex, self.room_alias_regex,
        )

        for regex in id_regexes:
            if regex.match(unquote(el.attrib["href"])):
                el.attrib["href"] = f"https://matrix.to/#/{el.attrib['href']}"
                return el

        if not outgoing or room_id not in self.rooms_user_id_names:
            return el

        for user_id, username in self.rooms_user_id_names[room_id].items():
            if unquote(el.attrib["href"]) == username:
                el.attrib["href"] = f"https://matrix.to/#/{user_id}"
                return el

        return el


    def _matrix_to_links_add_classes(self, el: HtmlElement) -> HtmlElement:
        """Add special CSS classes to matrix.to mention links."""

        href = unquote(el.attrib.get("href", ""))

        if not href or not el.text:
            return el


        # This must be first, or link will be mistaken by room ID/alias regex
        if self.link_is_message_id_regex.match(href):
            el.attrib["class"]        = "mention message-id-mention"
            el.attrib["data-mention"] = el.text.strip()

        elif self.link_is_user_id_regex.match(href):
            if el.text.strip().startswith("@"):
                el.attrib["class"] = "mention user-id-mention"
            else:
                el.attrib["class"] = "mention username-mention"

            el.attrib["data-mention"] = el.text.strip()

        elif self.link_is_room_id_regex.match(href):
            el.attrib["class"]        = "mention room-id-mention"
            el.attrib["data-mention"] = el.text.strip()

        elif self.link_is_room_alias_regex.match(href):
            el.attrib["class"]        = "mention room-alias-mention"
            el.attrib["data-mention"] = el.text.strip()

        return el


HTML_PROCESSOR = HTMLProcessor()
