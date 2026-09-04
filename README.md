# grep

[GNU grep](https://www.gnu.org/software/grep/), with PCRE2 support (`grep -P`). A single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/grep/actions/workflows/grep.yml/badge.svg)](https://github.com/unpins/grep/actions)
![Linux](https://img.shields.io/badge/Linux-%E2%9C%93-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-%E2%9C%93-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-%E2%9C%93-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install grep`.

## Usage

Run the `grep` program with [unpin](https://github.com/unpins/unpin):

```bash
unpin grep -rn pattern .
```

To install it onto your PATH:

```bash
unpin install grep
```

`unpin install grep` also creates the `egrep` and `fgrep` commands.

## Man pages

`grep.1` is embedded in the binary — read with `unpin man grep`. `egrep` and `fgrep` share it; they're the same program under different names, not separate pages.

## Build locally

```bash
nix build github:unpins/grep
./result/bin/grep --version
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/grep/releases) page has standalone binaries for manual download.

## Build notes

- **PCRE2:** `grep -P` (Perl-compatible regexes) works — libpcre2 is folded in statically.
- **Aliases:** `egrep`/`fgrep` are `argv[0]`-dispatch names (GNU grep 3.x dropped the built-in dispatch and shipped shell wrappers; we re-add the dispatch in-source and drop the wrappers). Invoked as `egrep`/`fgrep`, grep selects `-E`/`-F`.
- **Windows:** a single `grep.exe` targeting the mingw-w64 runtime, linking `-lbcrypt` for gnulib's `getrandom`.
- **Man pages:** `grep.1` is embedded; `egrep`/`fgrep` share it.
- **Tests:** GNU grep's test suite runs on native builds (0 failures under static-musl) and auto-skips on cross targets the build host can't execute.
