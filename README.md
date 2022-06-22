# JEPL
A more ergonomic REPL for [Janet](https://janet-lang.org/index.html)


## Features

* Parens are automatically inserted for expressions that consist of multiple words
* Type " ??" after a symbol or a function call to view the docs for it
* Result of the previous expression is always available in a variable called `ans`


## How?

To run JEPL you need to have [Janet](https://github.com/janet-lang/janet#installation) and Python3 installed.
Only Linux is supported, I would be *very* surprised if it works at all on Windows since it relies heavily on
terminal escape codes.
JEPL must be started by running the `jepl` bash script which calls `jepl2.janet`. If you have `rlwrap` installed
the script uses it to provide readline features like history and completions. Completions should be
placed in a file called completions (you can generate completions by running `make completions`).
For a nicer setup I recommend creating a symlink to `jepl` somewhere in your `$PATH`.

For example:

```console
$ git clone https://github.com/Andriamanitra/JEPL
$ cd JEPL
$ ln -s "$PWD/jepl" "$HOME/.local/bin/jepl"
$ jepl
Welcome to JEPL, an alternative Janet REPL!
jepl> string "hello" "world"
"helloworld"
jepl>
```


## Why?

I've wanted to do something with a lispy language for a while. I recently learned about Janet and this seemed like a fun little project for trying it out.
Turns out it's a fun little language!

## Demo (old version with buggy DIY readline-like functionality)

[![asciicast](https://asciinema.org/a/LaMwDMvPTOgm35Nebs3drRwgC.svg)](https://asciinema.org/a/LaMwDMvPTOgm35Nebs3drRwgC)

