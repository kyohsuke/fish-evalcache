# Test file: Hash fallback mechanism
# Tests the fallback behavior when external hash commands are unavailable
# Uses 'od' as a POSIX-compatible alternative

source (dirname (status filename))/../functions/_evalcache.fish
set temp (mktemp -d)
cd "$temp"
set -lx FISH_EVALCACHE_DIR "$temp"

set _test_pass 0
set _test_fail 0

function _pass
    echo "  PASS: $argv"
    set -g _test_pass (math $_test_pass + 1)
end

function _fail
    echo "  FAIL: $argv"
    set -g _test_fail (math $_test_fail + 1)
end

# Create test commands
echo '#!/usr/bin/env bash' > testcmd1
echo 'echo "result1"' >> testcmd1
chmod +x testcmd1

echo '#!/usr/bin/env bash' > testcmd2
echo 'echo "result2"' >> testcmd2
chmod +x testcmd2

# Test 1: Verify the _evalcache_hash function supports the 'od' fallback
echo "Test 1: Verify od fallback produces different hashes for different inputs"

# Temporarily overwrite _EVALCACHE_HASH_CMD to 'od' (simulate no external tools)
set -g _EVALCACHE_HASH_CMD od

# Hash two different inputs and verify they produce DIFFERENT hashes
set hash_a (_evalcache_hash test_string_A)
set hash_b (_evalcache_hash test_string_B)

if test "$hash_a" != "$hash_b" -a -n "$hash_a" -a -n "$hash_b"
    echo "  hash_A = $hash_a"
    echo "  hash_B = $hash_b"
    echo "  Different inputs → different hashes"
    _pass "od fallback produces unique hashes"
else
    echo "  hash_A = $hash_a"
    echo "  hash_B = $hash_b"
    _fail "od fallback did NOT produce different hashes"
end

# Test 2: Verify od fallback produces same hash for same input (deterministic)
echo "Test 2: Od fallback is deterministic"
set hash_a2 (_evalcache_hash test_string_A)
if test "$hash_a" = "$hash_a2"
    echo "  hash_A (2nd call) = $hash_a2"
    _pass "same input produces same hash"
else
    echo "  hash_A (1st) = $hash_a"
    echo "  hash_A (2nd) = $hash_a2"
    _fail "same input produces different hashes"
end

# Test 3: Verify same-cmd-different-args with od fallback DON'T collide
echo "Test 3: Same cmd, different args produce different hashes (od fallback)"
set temp2 (mktemp -d)
set -g FISH_EVALCACHE_DIR "$temp2"

# Hash different args but same cmd
set hash_v1 (_evalcache_hash testcmd1 arg_v1)
set hash_v2 (_evalcache_hash testcmd1 arg_v2)

if test "$hash_v1" != "$hash_v2"
    echo "  hash_v1 = $hash_v1"
    echo "  hash_v2 = $hash_v2"
    _pass "no collision with od fallback"
else
    echo "  hash_v1 = $hash_v1"
    echo "  hash_v2 = $hash_v2"
    _fail "SAME hash for different args — collision!"
end

# Test 4: Actual cache creation with od fallback
echo "Test 4: Actual cache creation with od fallback"
_evalcache ./testcmd1 2>/dev/null

# Find the cache file
set cache_files (ls "$FISH_EVALCACHE_DIR"/init-testcmd1-*.fish 2>/dev/null)
if test (count $cache_files) -gt 0
    set cache_hash (basename $cache_files[1] | string replace 'init-testcmd1-' '' | string replace '.fish' '')
    # Verify the hash was computed by od (should be hex)
    if test (string match -q '[0-9a-f]*' "$cache_hash")
        echo "  Cache file: init-testcmd1-$cache_hash.fish"
        _pass "cache created with od fallback"
    else
        echo "  Cache hash '$cache_hash' is not valid hex"
        _fail "invalid cache hash"
    end
else
    echo "  No cache file created"
    _fail "cache file not created"
end

# Clean up
rm -rf "$temp" "$temp2"

echo ""
echo "=== Results: $_test_pass passed, $_test_fail failed ==="
exit $_test_fail
