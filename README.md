# `rbexec`

Execute commands against different Ruby interpreters.

---

In the spirit of [chruby's README](https://github.com/postmodern/chruby/blob/master/README.md#features):

## Features

Even fewer than [chruby](https://github.com/postmodern/chruby.git)!

* Distributed as a single executable (plus a manual page).
* Can be used as an executable or as a shell function.
* Supports `ash`, `bash`, `dash`, `ksh`, `mksh`, `pdksh`, and `zsh`. Maybe
  other shells, too, but those are the only tested ones.
* Auto-detects Rubies installed in `/opt/rubies`, `~/.rbfu/rubies`,
  `~/.rbenv/versions`, `~/.rvm/rubies`, and `~/.rubies`.

## Anti-Features

* Doesn't change your current shell's environment (instead, it starts a new
  process).
* Doesn't do pretty much anything else.

## Requirements

`ash`, `bash`, `dash`, `ksh`, `mksh`, `pdksh`, or `zsh`. Probably works with
other shells, too.

## Install


## Configuration

You don't have to do much, as `rbexec` is designed to work as a standalone
executable and Do The Right Thing under common circumstances.  Just

```sh
$ rbexec 2.5.0 do-something
```

and you're cooking with Ruby 2.5.0! (assuming you have Ruby 2.5.0 installed)

Please see [the manual page](man/rbexec.1.md) for information on how to
fine-tune `rbexec`'s behavior.
