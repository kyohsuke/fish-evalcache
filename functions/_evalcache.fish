# _evalcache.fish - fish shell plugin to cache the output of binary initialization
# Based on https://github.com/mroth/evalcache
#
# FIX 1 (Performance): Hash algorithm detection moved to script load time (below function).
#   Previously, `command -v md5/md5sum` was called on EVERY function invocation.
#   Now detected once at load time, stored in _EVALCACHE_HASH_CMD.
#
# FIX 2 (Reliability): Added fallback hash computation using od when no external
#   hash command (md5, md5sum, sha256sum) is available. Previously, cmdHash
#   defaulted to literal "noHash" causing cache collisions.

# --- Script-load-time: detect hash tool (FIX 1) ---
set -g _EVALCACHE_HASH_CMD

if command -v md5sum >/dev/null 2>&1
    set -g _EVALCACHE_HASH_CMD md5sum
else if command -v sha256sum >/dev/null 2>&1
    set -g _EVALCACHE_HASH_CMD sha256sum
else if command -v md5 >/dev/null 2>&1
    set -g _EVALCACHE_HASH_CMD md5
else
    # FIX 2: Fallback when no external hash tool is available.
    # Use od to produce a deterministic hex dump of the input string.
    # This works on virtually all Unix systems since od is a POSIX utility.
    set -g _EVALCACHE_HASH_CMD od
end

# Internal helper: compute a hash of the given arguments
# Uses the pre-detected hash command (or od fallback)
function _evalcache_hash
    if test "$_EVALCACHE_HASH_CMD" = "od"
        # Fallback: produce a deterministic hex identifier from the string.
        # Join all args into one string, then get hex bytes via od.
        printf "%s" (string join " " $argv) | od -An -v -tx1 | tr -d ' \n'
    else
        # Use the pre-detected hash command (md5sum, sha256sum, or md5)
        printf "%s" (string join " " $argv) | $_EVALCACHE_HASH_CMD | cut -d' ' -f1
    end
end

# --- User-facing function ---
function _evalcache
    if test (count $argv) -eq 0
        return
    end

    if test -z "$FISH_EVALCACHE_DIR"
        set -gx FISH_EVALCACHE_DIR "$HOME/.fish-evalcache"
    end

    # Get the cache file name
    set -f cmd (basename $argv[1])
    set -f cmdHash (_evalcache_hash $argv)
    set -f cacheFile "$FISH_EVALCACHE_DIR/init-$cmd-$cmdHash.fish"

    if test "$FISH_EVALCACHE_DISABLE" = true
        echo "$argv[1] initialization not cached, skipping" 1>&2
        return 0
    end

    # Check if cache exists and is valid
    if test -f "$cacheFile"
        source "$cacheFile"
    else
        echo "$argv[1] initialization not cached, caching output of: $argv" 1>&2
        mkdir -p "$FISH_EVALCACHE_DIR"

        # Optimization: remove unnecessary basename call per iteration
        for fName in "$FISH_EVALCACHE_DIR/init-$cmd-"*".fish"
            rm -f "$fName"
        end

        # FIX: Write to temp file first, then rename atomically
        # to prevent reading partial content if another shell accesses it
        set -f tempFile (mktemp "$FISH_EVALCACHE_DIR/.tmp-init-XXXXXXXXXX")
        if test -z "$tempFile"
            echo "evalcache ERROR: Failed to create temporary file" 1>&2
            return 1
        end
        $argv >"$tempFile"
        if test $? -ne 0
            echo "evalcache ERROR: Failed to execute command: $argv" 1>&2
            rm -f "$tempFile"
            return 1
        end
        mv -f "$tempFile" "$cacheFile"
        source "$cacheFile"
    end
end
