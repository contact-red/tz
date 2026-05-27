# tz

[“Sooner or later every programmer has to deal with time zones … and you really should never, ever deal with time zones if you can help it.”](https://www.youtube.com/watch?v=-5wpm-gesOY)

A timezone and calendaring package for Pony. During packaging we incorporated
the IANA database so the package has no reason to ask for any Object Capablility
or C-FFI.

See the [fine documentation](https://tz.contact.red/) for an overview of what
functionality is and is not covered - as well as some of the "peculiarities"
that comes with international TimeZones.

Remember folks, "America/Chicago" ≠ "EST5EDT"(!) - Choose Wisely!

This package *DOES* differenciate betwixt the two.

## Status

Work in progress. The API surface is still settling and breaking changes
should be expected until 1.0.

## Installation

Add it to your project with [corral](https://github.com/ponylang/corral):

```sh
corral add github.com/contact-red/tz.git --version 0.1.0
corral fetch
```

Then in your Pony code:

```pony
use "tz"
```

## Building from source

```sh
make test    # build and run the test suite
make docs    # generate documentation under build/tz-docs
make clean   # remove the build directory
```

## Documentation

[https://tz.contact.red/](https://tz.contact.red)
