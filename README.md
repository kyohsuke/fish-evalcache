# fish-evalcache
[![Test](https://github.com/kyohsuke/fish-evalcache/actions/workflows/test.yml/badge.svg)](https://github.com/kyohsuke/fish-evalcache/actions/workflows/test.yml)

> fish plugin to cache the output of a binary initialization command, intended to help lower shell startup time.

## Install
```sh
fisher install kyohsuke/fish-evalcache
```

## Usage
```sh
source (anyenv init -|psub)
```

↓

```sh
_evalcache anyenv init - fish
```

## It based on
https://github.com/mroth/evalcache
