# mono-webassembly-zoneinfo
Repository to build the `mono-webassembly-zoneinfo.js` database module for Mono WebAssembly TimeZoneInfo support.

The purpose of this module is to only support the TimeZone database information used by Mono WebAssembly.  This data comes from a distribution of the [IANA time zone database](https://www.iana.org/time-zones).

**NOTE**: The `TimeZoneInfo` class created will be generated with the information from [IANA time zone database](https://www.iana.org/time-zones) file and does not attempt to provide any routines to convert between Windows timezone id's and IANA's nor vice-versa.

## Build Requirements

Operating system that supports the `zic` command that will generate the zone database files.

## Executing

From a terminal execute the following:

``` bash
> make
```

## Process

1. Download the latest [IANA time zone](https://www.iana.org/time-zones) data and extract it.

1. Generate the time zone databases using the `zic` command for the following continents.
   - africa, antarctica, asia, australasia, etcetera, europe, northamerica, southamerica, backward

1. Compile and execute the application `TimeZoneBuilder` application which will generate the `mono-webassembly.zoneinfo.js` module.

## Warnings

The following warning may be seen depending on the operating system.  `warning: time zone abbreviation differs from POSIX standard`.

> These warnings should not otherwise affect zic's output and can
safely be ignored on today's platforms, as the warnings refer to a restriction
in POSIX.1-1988 that was removed in POSIX.1-2001. One way to suppress the
warnings is to upgrade to zic derived from tz releases 2015f and later.




debug no force file-system
mono.js             504559      505 KB
mono.wasm           9621131     9.6 MB
mono.wasm.map       743837   744KB

release no force file-system
mono.js             210138      210 KB
mono.wasm           1739017     1.7 MB

