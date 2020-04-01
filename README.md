# mono-webassembly-zoneinfo
Repository to build the `mono-webassembly-zoneinfo.js` database module for Mono WebAssembly TimeZoneInfo support.

The purpose of this module is to only support the TimeZone database information used by Mono WebAssembly.  This data comes from a distribution of the [IANA time zone database](https://www.iana.org/time-zones).

**NOTE**: The `TimeZoneInfo` class created will be generated with the information from [IANA time zone database](https://www.iana.org/time-zones) file and does not attempt to provide any routines to convert between Windows timezone id's and IANA's nor vice-versa.

## Build Requirements

Operating system that supports the `zic`<sup>[1](#zic1)</sup> command that will generate the zone database files.

## Executing

From a terminal execute the following:

``` bash
> make
```

## Process

1. Download the latest [IANA time zone](https://www.iana.org/time-zones) data and extract it.

1. Generate the time zone databases using the `zic` command for the following continents.
   - africa, antarctica, asia, australasia, etcetera, europe, northamerica, southamerica, backward

1. Clone the DotNet file packager project from git https://github.com/kjpou1/Mono.WebAssembly.FilePackager.git

1. Build and execute the `FilePackager` to build the following:

   | .js | .data | continent(s) |
   |:-:|:-:|:-:|
   | mono-webassembly-zoneinfo-fs.js | zoneinfo.data | africa, antarctica, asia, australasia, etcetera, europe, northamerica, southamerica, backward |
   | mono-webassembly-zoneinfo-africa-fs.js | zoneinfo-africa.data | africa |
   | mono-webassembly-zoneinfo-antarctica-fs.js | zoneinfo-antarctica.data | antarctica |
   | mono-webassembly-zoneinfo-australasia-fs.js | zoneinfo-australasia.data | australasia |
   | mono-webassembly-zoneinfo-etcetera-fs.js | zoneinfo-etcetera.data | etcetera |
   | mono-webassembly-zoneinfo-europe-fs.js | zoneinfo-europe.data | europe |
   | mono-webassembly-zoneinfo-northamerica-fs.js | zoneinfo-northamerica.data | northamerica |
   | mono-webassembly-zoneinfo-southamerica-fs.js | zoneinfo-southamerica.data | southamerica |
   | mono-webassembly-zoneinfo-northamerica-and-us-fs.js | zoneinfo-northamerica-and-us.data | northamerica as well as the US data from backward |
   | mono-webassembly-zoneinfo-europe-luxembourg-fs.js | zoneinfo-europe-luxembourg.data | only Europe/Luxembourg |


## Embedding an absolute file/directory

The data is loaded into the WebAssembly Virtual File System and is required to use the directory structure `/zoneinfo`.

To package specific directories you can use the file packager explicit syntax `--preload srcpath@dstpath` to explicitly specify the target location the absolute source path should be directed to.

For example Europe/Luxembourg:

`--preload zoneinfo-europe/Europe/Luxembourg@zoneinfo/Europe/Luxembourg`

Notice the separating `@` symbol that tells the packager how to target is to be directed.

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

<a name="zic1">1</a>: [zic - timezone compiler](http://man7.org/linux/man-pages/man8/zic.8.html)