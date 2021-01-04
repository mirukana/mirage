# Contributing

- [Issues](#issues)
- [Pull Requests](#pull-requests)
  - [Procedure](#procedure)
- [Commit Guidelines](#commit-guidelines)
- [Coding Conventions](#coding-conventions)
  - [General](#general)
  - [Python](#python)
  - [QML](#qml)
  - [C++](#c)
- [Resources](#resources)
- [Packaging](#packaging)

## Issues

[Issues](https://github.com/mirukana/mirage/issues) on GitHub should be used to
ask questions, report problems, request new features,
or discuss potential changes before creating pull requests. 

Before opening new issues, please search for any already open or closed 
issue related to your problem, in order to prevent duplicates.

You can also join us on the 
[#mirage-client:matrix.org](https://matrix.to/#/%23mirage-client:matrix.org)
room for questions and discussions.


## Pull Requests

For changes outside of simple bug/typo/formatting fixes, it is strongly 
recommended to first discuss your ideas in a related issue or in
[#mirage-client:matrix.org](https://matrix.to/#/%23mirage-client:matrix.org).

New changes are merged to the 
[`dev` branch](https://github.com/mirukana/mirage/tree/dev) first.  
Once a new version of the application is released, 
the current `dev` is merged into the main `master` branch.

By sending your changes, you agree to license them under the LGPL 3.0 or later.

### Procedure

Start by forking the main repository from GitHub, then
clone your fork and switch to a new branch based on `dev`, in which 
you will make your changes:

```sh
git clone --recursive https://github.com/yourUsername/mirage
cd mirage
git remote add upstream https://github.com/mirukana/mirage
git fetch upstream
git checkout upstream/dev
git branch example-branch-name
git checkout example-branch-name
```

Test and commit your changes according to the 
[commit guidelines](#commit-guidelines), and `git push` to your fork's repo.  
You will then be able to make a pull request by going 
to the [main repo](https://github.com/mirukana/mirage).

Once your pull request is merged, you can update `dev`, and delete your
GitHub and local branch:

```sh
git fetch upstream
git checkout upstream/dev

git push -d origin example-branch-name
git branch -d example-branch-name
```

Make sure `dev` is up-to-date before creating new branches based on it.


## Commit Guidelines

Commit messages should be made in this form:

```
Title, a short summary of the changes

The body, a more detailed summary needed depending on the changes.
Explain the goal of the code, how to reproduce the bug it solves 
(if this is a bug fix), any special reasoning behind the 
implementation or side-effects.
```

- Write informative titles, e.g.
  `TextField: fix copying selected text by Ctrl+C` instead of 
  `fix field bug`
  (assuming `TextField` was the name of the component affected by the bug)

- Write the title in imperative form and without a period at the end,
  e.g. `Fix thing` instead of `Fixed thing` or `Fixes thing.`

- The title must not exceed 50 characters

- A blank line is required between the first line summary and detailed
  body, if there is one

- Lines of the body must not exceed 72 characters

- Split independent changes into separate commits,
  don't combine fixes for different problems or add multiple systems forming a
  complex feature all at once

- Every commit should be able to build and run the application without
  obvious crashes or tracebacks

- Check for linter errors before committing by running `make test` in the
  repository's root. The test tools can be installed with
  `pip3 install --user -Ur requirements-dev.txt`.

- For changes that aren't yet merged in a branch of the main repo,
  prefer amending or editing previous commits via git interactive rebase,
  rather than adding new "fix this" commits.
  This helps keeping the history clean.


## Coding Conventions

### General

- Use four space indentations, no tabs

- Use double quotes for strings, unless single quotes would avoid having to 
  escape double quotes in the text

- Keep lines under 80 columns, the only exception for this is long URL links
  that can't be broken in multiple parts

- Keep lines free from any trailing whitespace

- Function definitions, calls, list/dict/etc not fitting in
  one line follow this format (notice the trailing comma on the last element):

  ```python3
  long_function_call(
      long_argument_1, long_argument_1, long_argument_3, long_argument_4,
  )

  very_long_list_def = [
      "Lorem ipsum dolor sit amet, consectetuer adipiscing elit",
      "Aenean massa. Cum sociis natoque penatibus",
      "Mus donec quam felis, ultricies nec, pellentesque",
  ]
  ```

- When creating new files, don't forget the copyright and license
  header you see in other files of the same language.

### Python 

- All functions, class attributes or top-level variables should have type hints 

- Separate all top-level classes and functions by two blank lines.
  For classes with many long methods, separate those methodes by two blank 
  lines too.

- Readability is important. Vertically-align consecutive lines of assignments, 
  function definition arguments, dictionaries and inline comments:

  ```python3
  # Bad:

  num: int = 1  # A comment
  args: List[str] = ["a", "b"]  # Another comment

  def func(
      self,
      example_argument: int = 300,  # Comment
      other: str = "Sample text",  # Other comment
      some_floats: Tuple[float, float, float] = (4.2, 1.1, 9.8),
  ) -> None:
      pass

  # Good:

  num:  int       = 1           # A comment
  args: List[str] = ["a", "b"]  # Another comment

  def func(
      self,
      example_arg: int                 = 300,            # Comment
      other:       str                 = "Sample text",  # Other comment
      some_floats: Tuple[float, float] = (4.2, 9.8),
  ) -> None:
      pass
  ```

  If this is annoying, consider getting a plugin for your editor to automate it
  (e.g. [EasyAlign](https://github.com/junegunn/vim-easy-align) for vim).

- Use f-strings as long as the readability isn't impacted.
  For more complex string formatting, use the shorter `%` syntax when features
  special to `str.format()` aren't needed.

- Otherwise, follow the
  [PEP-8 standard](https://www.python.org/dev/peps/pep-0008/)

### QML

- Don't add trailing semicolons to lines

- If an object has more than one property, always keep each property on their
  own line:

  ```qml
  Rectangle { x: 10; width: 100; height: width; color: "black" }  // Bad!

  Rectangle {  // Good
      x: 10 
      width: 100
      height: width
      color: "black"
  }
  ```

- When creating new files, the `id` for the root component should always 
  be `root`

- When writing new code, refer to parent object properties explicitely, e.g.
  `parent.prop_name` or `someId.prop_name` instead of just `<prop_name>`

- Don't use [States](https://doc.qt.io/qt-5/qml-qtquick-state.html),
  the Rectangle in the description's example could simply be written like this:

  ```qml
  Rectangle {
      width: 100
      height: 100
      color: mouseArea.containsPress ? "red" : "black"

      MouseArea {
          id: mouseArea
          anchors.fill: parent
      }
  }
  ```

- Otherwise, follow the
  [QML Coding Conventions](https://doc.qt.io/qt-5/qml-codingconventions.html)

### C++

- Add C++ only if it can't easily be done in QML or Python;
  or if doing it in Python requires adding a dependency while a 
  similar feature is already provided by Qt, feature that just needs to be 
  exposed with some wrapper code
  ([example](https://github.com/mirukana/mirage/blob/v0.6.4/src/utils.h#L31)).

- Be explicit, always use `this->` to refer to methods and class attributes

- Don't split modules between `.h` and `.cpp` files, this creates unnecessary
  code repetition and has no benefits when most methods will 
  contain very few lines and the module is only included once before 
  starting the GUI.


## Resources

Resources include background images, icons or sounds.
New resources must have a permissive license that does not require attribution.
Built-in icons must be in the SVG format.  The majority of icons used in the
application come from [iconmonstr](https://iconmonstr.com).

When possible without any noticable quality loss, reduce the size of 
resources and strip any metadata by using tools such as:

- `svgcleaner --allow-bigger-file --indent 4 <file> <output>` for SVG images
- `pngquant --force --speed=1 --strip <file> <output>` for PNG images
- `jpegoptim --quality 80 --strip-all <file>` for JPEG images


## Packaging

If a new package for a distribution or any other easy way
of installing the application exists, [pull request](#pull-requests) for
adding instructions to the [INSTALL.md](INSTALL.md) are welcome.

Some suggestions when creating packages:

- As the `mirage` name is sometimes already taken by other software,
  prefer naming your package `mirage-im`

- Among the dependencies from the `submodules` directory, `hsluv-c` is the
  only one that is still needed for building.  
  The other folders are kept to allow building past versions of the
  application, and should be ignored.
