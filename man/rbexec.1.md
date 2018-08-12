# rbexec 1 "Aug 2018" rbexec "User Manuals"

## NAME

rbexec - execute commands against different Ruby interpreters

## SYNOPSIS

**rbexec** ruby-identifier [command ...]

## DESCRIPTION

`rbexec` is a shell script that configures the environment to use a particular
Ruby interpreter. It works with a number of shells, including `bash` and `zsh`.

Unlike some similar tools (*e.g.*, the excellent
[chruby](https://github.com/postmodern/chruby) ), `rbexec` does not modify the
current shell environment. Instead, it starts an entirely new process -- so
your previous environment is just an `exit` away.

## EXAMPLES

Using the full path to a Ruby interpreter:

    $ rbexec ~/.rvm/rubies/ruby-2.5.0/bin/ruby bash

Using an executable matching `bin/ruby*` under the provided directory:

    $ source rbexec ; rbexec /opt/rubies/ruby-2.4.2

Using the last-matching entry in `RBEXEC_RUBIES`:

    $ export RBEXEC_RUBIES=/my/custom/ruby-2.3.5:/my/custom/ruby-2.5.0
    $ rbexec 2.3 which ruby
    /my/custom/ruby-2.3.5/bin/ruby
    $ rbexec 2 which ruby
    /my/custom/ruby-2.5.0/bin/ruby

## ENVIRONMENT VARIABLES

`RBEXEC_RUBIES` */a/ruby/path:/another/ruby/path/bin/ruby*
  A colon-separated list of directories containing Ruby interpreters (paths
  matching `.../bin/ruby*`), or full paths to Ruby interpreters, or a
  combination thereof. Please not that `rbexec` does not handle paths with
  embedded colons, escaped or otherwise.

`RBEXEC_AUTO_ADD_RUBIES` *1|0*
  When set to `1`, any subdirectories of `/opt/rubies`, `~/.rbfu/rubies`,
  `~/.rbenv/versions`, `~/.rvm/rubies`, and `~/.rubies` that contain executable
  files matching `bin/ruby*` will be treated as if they appeared in
  `RBEXEC_RUBIES`. This variable is set to `1` by default.

`RBEXEC_EXEC` *1|0*
  When set to `1`, `rbexec` will start the specified command (or, if none was
  given, `RBEXEC_SHELL`) with the shell builtin `exec`. The default value of
  `RBEXEC_EXEC` is `0` if `RBEXEC_SOURCED` is set to `1` or if the variable
  `$-` contains the letter `i`, and `0` otherwise.

`RBEXEC_PIPE_DOWN` *1|0*
  `rbexec` probes whether the specified Ruby really is a Ruby interpreter by
  asking it to execute a Ruby one-liner via `ruby -e 'command'`.  `rbexec`
  attempts to wrap this test in a timeout using, in order of preference,
  `timeout`, `ruby`, `perl`, `python`, or `python2`. If none of these programs
  appear in your `PATH`, `rbexec` issues a warning that the test Ruby command
  may hang indefinitely. Set `RBEXEC_PIPE_DOWN=1` to disable this warning.

`RBEXEC_SHELL` */path/to/my/sh*
  This is the program that `rbexec` executes when not given one explicitly on
  the command line. If `RBEXEC_SHELL` is unset or empty, `rbexec` uses various
  heuristics to infer the current shell, falling back to `/bin/sh` if none of
  the heuristics yields a match.

`RBEXEC_SOURCED` *1|0*
  Set this to indicate that `rbexec` has been sourced rather than run as an
  executable. As with `RBEXEC_SHELL`, if `RBEXEC_SOURCED` is not explicitly
  defined, `rbexec` uses a number of heurstics to determine whether it was
  sourced. These heuristics are far from perfect, so you may have to define
  `RBEXEC_SOURCED` yourself if `rbexec` gets it wrong.

`RBEXEC_TIMEOUT` *N*
  Set this to the number of seconds `rbexec` should wait for the test Ruby
  command described under `RBEXEC_PIPE_DOWN` to exit. Defaults to 5.

## AUTHOR

Matt Schreiber <tomeon@dogea.red>

## SEE ALSO

Shells supported by `rbexec`:

* [sh](man:sh(1))
* [ash](man:ash(1))
* [bash](man:bash(1))
* [dash](man:dash(1))
* [ksh](man:ksh(1))
* [mksh](man:mksh(1))
* [pdksh](man:pdksh(1))
* [zsh](man:zsh(1))

Tools occupying a similar niche:

* [chruby](https://github.com/postmodern/chruby)
* [rbenv](https://github.com/sstephenson/rbenv)
* [rbfu](https://github.com/hmans/rbfu)
* [ruby-version](https://github.com/wilmoore/ruby-version)
* [RVM](https://rvm.io/)
* [ry](https://github.com/jneen/ry)
