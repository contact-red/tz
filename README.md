# tz

A timezone and calendaring package for Pony. It reads IANA tzdata from the
operating system and provides calendar primitives (`Date`, `TimeOfDay`,
`Period`) plus zoned datetimes (`Zdt`) that convert between POSIX time and
local wall-clock time across historical and present-day zone definitions.

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

The test binary is built into `build/debug/tz` (or `build/release/tz` with
`config=release`).

## Zone data regeneration

`tz/_zones_generated.pony` is generated from the system zoneinfo database
under `/usr/share/zoneinfo`. Regenerate it with:

```sh
./regenerate-zones.sh
```

To check for drift between the committed file and a fresh regeneration:

```sh
./verify-zones.sh
```

## License

TBD.
