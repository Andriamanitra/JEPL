# JEPL
A more ergonomic REPL for [Janet](https://janet-lang.org/index.html)


## Features

* Parens are automatically inserted for expressions that consist of multiple words
* Type " ??" after a symbol or a function call to view the docs for it
* Result of the previous expression is always available in a variable called `ans`
* Tab completion
* REPL history (remembers inputs for current session)
* Various keyboard shortcuts:
  * Close the terminal with `ctrl-q` or `ctrl-d`
  * Erase full word with `ctrl-w` or `ctrl-backspace`
  * Browse history with `up` and `down` arrows
  * Jump to prev/next word with `ctrl-left` and `ctrl-right`
  * Jump to beginning/end of the line with `ctrl-a`, `ctrl-e`, `home`, `end`
  * (hopefully more soon)


## How?

To run JEPL you need to have [Janet](https://github.com/janet-lang/janet#installation) and Python3 installed.
Only Linux is supported, I would be *very* surprised if it works at all on Windows since it relies heavily on
terminal escape codes.
JEPL must be started by running the `run.py` Python3 script (its only job is to disable line buffering - apparently
you can't do that in Janet without using C which I didn't want to do). This script must be located in the same
directory as `jepl.janet`. For a nicer setup I recommend creating a symlink to `run.py` somewhere in your `$PATH`.

For example:

```console
$ git clone https://github.com/Andriamanitra/JEPL
$ cd JEPL
$ ln -s "$PWD/run.py" "$HOME/.local/bin/jepl"
$ jepl
Welcome to JEPL, an alternative Janet REPL!
jepl> string "hello" "world"
"helloworld"
jepl>
```


## Why?

I've wanted to do something with a lispy language for a while. I recently learned about Janet and this seemed like a fun little project for trying it out.
Turns out it's a fun little language!

## Demo

[![asciicast](https://asciinema.org/a/LaMwDMvPTOgm35Nebs3drRwgC.svg)](https://asciinema.org/a/LaMwDMvPTOgm35Nebs3drRwgC)

