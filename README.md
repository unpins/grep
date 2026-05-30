# grep

Standalone build of [GNU grep](https://www.gnu.org/software/grep/), with PCRE2 support (`grep -P`).

[![CI](https://github.com/unpins/grep/actions/workflows/grep.yml/badge.svg)](https://github.com/unpins/grep/actions)
![Linux](https://img.shields.io/badge/Linux-%E2%9C%93-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-%E2%9C%93-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-%E2%9C%93-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

## Usage

The package ships one executable, `grep`. `unpin grep` materializes `egrep` and `fgrep` shims next to it; GNU grep dispatches its mode from argv[0] (`-E` and `-F` respectively), so the aliases work without a separate binary. You can also invoke them directly:

```bash
grep -E 'foo|bar' file.txt    # same as: egrep
grep -F 'literal text' file   # same as: fgrep
grep -P '\d{3}-\d{4}' file    # PCRE2
```

## Installation

Install with [unpin](https://github.com/unpins/unpin):

```bash
unpin grep
```

Or run without installing:

```bash
unpin run grep
```

## Build locally

```bash
nix build github:unpins/grep
./result/bin/grep --version
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Man pages

`grep.1` is embedded in the binary — read with `unpin man grep`. `egrep` and `fgrep` share it; they're argv[0] modes of the same tool, not separate pages.

## Manual download

The [Releases](https://github.com/unpins/grep/releases) page has standalone binaries for manual download.
