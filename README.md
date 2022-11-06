# fish-evalcache
[![Test](https://github.com/kyohsuke/fish-evalcache/actions/workflows/test.yml/badge.svg)](https://github.com/kyohsuke/fish-evalcache/actions/workflows/test.yml)

> fish plugin to cache the output of a binary initialization command, intended to help lower shell startup time.

## Install
```fish
fisher install kyohsuke/fish-evalcache
```

## Usage
```fish
source (anyenv init - fish | psub)
```

↓

```fish
_evalcache anyenv init - fish
```

## It based on
https://github.com/mroth/evalcache
