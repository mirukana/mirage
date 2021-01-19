# PCN File Format

This document explains in details the PCN (Python Config Notation) format.
PCN files are organized in a hierarchy of sections and properties.
PCN files can also contain normal Python code, such as imports and
custom functions.

- [Overview](#overview)
- [Sections](#sections)
  - [Including Built-in Files](#including-built-in-files)
  - [Including User Files](#including-user-files)
  - [Inheritance](#inheritance)
- [Properties](#properties)
  - [Common Types](#common-types)
  - [Expressions](#expressions)
  - [Section Access](#section-access)
  - [Bracket Access](#bracket-access)
- [GUI files](#gui-files)


## Overview

```python3
# Lines starting with a "#" are considered comments. 
# Comments can also be added to the end of normal lines.

# Sections can contain indented properties, other sections or functions.
class Example:
    # Properties are written as "name: type = value", examples:
    integer_number:   int       = 5
    decimal_number:   float     = 2.5
    character_string: str       = "Sample text"
    boolean:          bool      = True  # or False
    string_list:      List[str] = ["foo", "bar", "baz"]

    # Property values can be any Python expression, e.g. math operations:
    other_number: int  = (5 * 4) / 2

    # "self" points to the current section, Example, containing other_number.
    above_10: bool = self.other_number > 10  # result: False

    class Names:
        # Property names with characters outside of a-z A-Z 0-9 _ need quoting:
        "@alice:example.org": str = "Alice"
        "@bob:example.org":   str = "Bob"

        # Section content can also be accessed with the "self[name]" syntax,
        # which works with quoted properties like the ones above:
        alice_name: str = self["@alice:example.org"]  # result: Alice

        # Child sections are also accessible from "self":
        child_integer: int = self.Test.integer  # result: 5

        class Test:
            # "parent" refers to the section parent of this one, here "Names".
            alice_name: str = parent["@alice:example.org"]  # result: "Alice"
            integer:    int = parent.parent.integer_number  # Example.integer_number, which is 5

            # Top-level sections can also be accessed directly by names:
            alice_name_2: str = Example.Names["@alice:example.org"]
            integer_2:    int = Example.integer_number
```


## Sections

Sections are defined like Python classes, and can contain properties, 
other sections, or Python functions.  
A section's name should be written as `CamelCase`, and can only contain
letters, digits and underscores.  
The content of a section must be indented by that section's indentation plus 
four spaces:

```python3
class FirstSection:
    content_spaces: int = 0 + 4

    class SectionInsideFirst:
        content_spaces: int = 4 + 4

class SecondSection:
    content_spaces: int = 0 + 4
```

Empty sections can be created using the `pass` keyword:

```python3
class Empty:
    pass
```

### Including Built-in Files

A section, including the file's root (which is treated as a section)
can include files that are supplied by the application using the 
`self.include_builtin(path)` function. 

`path` is the relative path to a file in the application's source folder, 
for example `self.include_builtin("config/settings.py")` refers to 
[`src/config/settings.py`][1].

The sections and properties from the included file will be recursively merged,
see [Including User Files](#including-user-files) for an example.

[1]: https://github.com/mirukana/mirage/tree/dev/src/config/settings.py

### Including User Files

Similar to [including built-in files](#including-built-in-files), user-written 
local files can be included with `self.include_file(path)`, where `path`
is an absolute or relative (from the current file's directory) file path.

Example with two files, `a.py`:

```python3
self.include_file("b.py")

class Shared:
    text:           str = "Sample"
    gets_overriden: str = "A"

    class FromA: 
        number: int = 1
```

and `b.py`:

```python3
class Shared:
    gets_overriden: str = "B"

    class FromB: 
        number: int = 2
```

This results in a merged PCN looking like so:

```python3
class Shared:
    text:           str = "Sample"
    gets_overriden: str = "B"

    class FromA: 
        number: int = 1

    class FromB: 
        number: int = 2
```

Include functions can also be used inside a section other than the root.
If `a.py` had the include line inside `Shared`, the result would be:

```python3
class Shared:
    text:           str = "Sample"
    gets_overriden: str = "A"

    class FromA: 
        number: int = 1

    class Shared:
        gets_overriden: str = "B"

        class FromB: 
            number: int = 2
```

### Inheritance

Like other Python classes, sections can inherit from other sections. 
Unlike including files, sections are not merged recursively.

This file:

```python3
class Mixin:
    first:  bool = True
    second: bool = False

class First(Mixin):
    pass

class Second(Mixin):
    third: int = 100
```

Would be equivalent to:

```python3
class First(Mixin):
    first:  bool = True
    second: bool = False

class Second(Mixin):
    first:  bool = True
    second: bool = False
    third:  int  = 100
```


## Properties

Properties have a name, optional type annotation and value. 
Standard property names should be written in `snake_case`.
In most cases, it is recommended to include type annotations, to make clear 
what a property's value should be:

```python3
    with_type:    int            = 3
    complex_type: Dict[str, int] = {"abc": 1, "def": 2, "ghi": 3}

    any_type: Any = None
    same_as_above = None
```

If the property's name starts with a digit or contains characters other than
letters, digits or underscores, that name must be quoted:

```python3
"!alice:example.org" = "Alice"
```

Properties with these names can only be accessed by the
[brackets syntax](#bracket-access).

### Common types

- `int`: An integer number, e.g. `4`.

- `float`: Floating point number, e.g. `4.5`. Can also be an integer.

- `str`: String, a piece of text.
  If the text contains quotes or backslashes, escape them with a backslash.
  Other properties can be included by combining strings or using an f-string:

  ```python3
  escaped:  str = "C:\\Users\\Alice \"Foo\" Bar"
  number:   int = 1
  combined: str = "foo " + self.number
  fstring:  str = f"foo {number}"
  ```

- `bool`: Boolean, a value that can be either `True` or `False`.

- `None`: A `None` value, represents an absence of choice.

- `Any`: A value that can be of any type.

- `list`: List of values, e.g. `[1, 2, 3]`.  
  The type can be written as `list` or `List[type]` to specify what type the 
  list's item should be.

- `tuple`: Similar to lists, but the length cannot be changed once created.  
  Can be written as `tuple`, `Tuple[type, type]` to specify for example that 
  the tuple must have two items of certain types, or `Tuple[type, ...]`
  for a tuple with any number of items of a certain same type:

  ```python3
  anything:     tuple                 = (1, 2, 3, "foo")
  many_ints:    Tuple[int, ...]       = (1, 2, 3, 4, 5)
  three_values: Tuple[int, str, bool] = (1, "example", False)
  ```

- `dict`: Mapping of keys to values. Can be written as `dict` or 
  `Dict[key_type, value_type]`:

  ```python3
  anything:      dict           = {1: 2, "foo": "bar", True: 1.5}
  account_order: Dict[str, int] = {"@a:example.com": 1, "@b:example.com": 2}
  ```

- `Optional[type]`: A value that can be either that type or `None`

- `Union[type1, type2]`: A value that can be one of the type in the `Union`. 
  The number of types can be more than two.

### Expressions

A property's value can be any Python expression. Properties can also 
refer to other properties, no matter what section they belong to or what
order they are defined in. 

This PCN code:

```python3
class Section1:
    other: int = self.text.lower() * 2  # "exampleexample"
    text:  str = "Example"
```

Is roughly equivalent to this in standard Python:

```python3
class Section1:
    @property
    def other(self) -> str:
        return self.text.lower() * 2

    @property
    def text(self) -> str:
        return "Example"
```

### Section Access

The current section and its properties are accessed via `self`:

```python3
class Base:
    number: int = 10
    other:  int = self.number * 2  # 20
```

The parent section is accessed via `parent`:

```python3
class Base:
    number: int = 10

    class Inner:
        number: int = parent.number * 2
```

Child sections can be accessed by `self.SectionName`:

```python3
class Base:
    number: int = self.Inner.number

    class Inner:
        number: int = 10
```

Any section (or property, or function) defined at the root/top-level of the 
file can be accessed by name:

```python3
class First:
    class InsideFirst:
        number: int = Second.number * 2  # 20
        other:  int = Second.InsideSecond.number  # 50

class Second:
    number: int = 10

    class InsideSecond:
        number: int = 50
```

The root (which behaves like a section) can also be explicitely accessed 
with `self.root`:

```python3
number: int = 10

class First:
    root_num: int = self.root.number  # Same as just saying "number"

class Second: 
    first_num: int = self.root.First.root_num  # Same as "First.root_num"
```

### Bracket Access

Inner sections and properties can also be accessed by the 
`section[name]` syntax. This is the only way to access properties with 
non-standard names (as described in [Properties](#properties)):

```python3
class Names:
    "!alice:example.org": str = "alice"

    class Capitalized:
        alice: str = parent["!alice:example.org"].capitalize()  # "Alice"
```

The syntax can also be used to access properties dynamically:

```python3
class Names:
    alice:         str = "Alice"
    property_name: str = "alice"
    first_person:  str = self[property_name]
```

Top-level properties can only be accessed this way using `self.root`:

```python3
"!alice:example.org": str = "Alice"

class Names:
    alice: str = self.root["!alice:example.org"] = "Alice"
```


# GUI Files

When properties for PCN files are edited from the user interface 
(programmatically or due to user actions), a separate file with a `.gui.json`
extension is created in the same folder.

These files take priority and override properties from the equivalent user 
files. They should not be edited by hand.
When a property in the user config file is edited, any equivalent property 
in the GUI file is automatically dropped,
to let the user's setting apply again.
