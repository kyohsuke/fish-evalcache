# fish-evalcache

fish shell plugin to cache the output of binary initialization to improve shell startup time.

## Features

- Caches binary initialization code based on command hash
- Supports multiple hash algorithms (md5sum, sha256sum, md5)
- Fallback to `od` when no external hash tool is available
- Atomic file writes to prevent reading partial content

## Installation

Add to your `.config/fish/config.fish`:

```fish
function fish_prompt
    _evalcache prompt
    # rest of your prompt configuration
end
```

## Configuration

- `FISH_EVALCACHE_DIR`: Directory to store cache files (default: `~/.fish-evalcache`)
- `FISH_EVALCACHE_DISABLE`: Disable caching by setting to `true`

## Usage

No manual intervention required - the plugin hooks into binary initialization automatically.

## Testing

Run the test suite:

```bash
fish run_tests.fish
```

Or run specific test files:

```bash
fish run_tests.fish tests/_evalcache_baseline.fish
fish run_tests.fish tests/_evalcache_fallback.fish
```

## Test Files

- `tests/_evalcache_baseline.fish`: Basic cache functionality tests
- `tests/_evalcache_fallback.fish`: Hash fallback mechanism tests
- `tests/_evalcache_hash_consistency.fish`: Hash consistency tests
- `tests/_helpers.fish`: Helper functions for testing

## Improvements

### FIX 1 (Performance)
- Hash algorithm detection moved to script load time
- Previously, `command -v md5/md5sum` was called on EVERY function invocation
- Now detected once at load time, stored in `_EVALCACHE_HASH_CMD`

### FIX 2 (Reliability)
- Added fallback hash computation using `od` when no external hash command is available
- Previously, cmdHash defaulted to literal "noHash" causing cache collisions
- `od` works on virtually all Unix systems as it's a POSIX utility

### Atomic Writes
- Cache files are now written to a temporary file first
- After successful completion, the temp file is atomically renamed to the final cache file
- Prevents reading partial content if another shell accesses it concurrently

### Error Handling
- Improved error messages for cache creation failures
- Temp file creation failure now returns an error instead of proceeding

## Supported Systems

- Linux
- macOS
- Unix systems with POSIX `od` command

## Compatibility

This plugin is designed to work with fish shell 3.0 and later.
