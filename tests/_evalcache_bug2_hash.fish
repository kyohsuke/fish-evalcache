# Test file: Bug 2 - Hash computation consistency
# Verifies that multi-arg hash inside _evalcache matches manual computation

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

# Create a test command
echo '#!/usr/bin/env bash' > testcmd
echo 'echo "cached output"' >> testcmd
chmod +x testcmd

# Get the hash as computed inside _evalcache (via echo -n "$argv")
# We need to see what _evalcache computes internally.
# We can't easily hook into the function, so we verify by:
# 1. Calling _evalcache with known args
# 2. Computing the same hash manually
# 3. Checking if the resulting cache file matches

# Test case 1: Single arg
_evalcache ./testcmd 2>/dev/null
# The cache file name will be: init-testcmd-<hash>.fish
# where hash = md5("testcmd")  (echo -n "$argv" where $argv = ./testcmd)
# In fish, echo -n "$argv" where argv has one element = "./testcmd"
# Wait - what does echo -n "$argv" produce?
# When argv = {./testcmd}, "$argv" produces "./testcmd"
# But when argv = {./testcmd arg1 arg2}, "$argv" produces "./testcmd arg1 arg2"
# Let's verify by computing what the hash SHOULD be:

# Single arg case
set expected_hash_single (echo -n ./testcmd | md5sum | cut -d' ' -f1)

# Find the actual cache file created (single arg = just ./testcmd)
set actual_cache (ls "$FISH_EVALCACHE_DIR"/init-testcmd-*.fish 2>/dev/null | head -1)
if test -n "$actual_cache"
    set base (basename "$actual_cache")
    # Extract hash from filename: init-testcmd-<hash>.fish
    set actual_hash (echo "$base" | string replace 'init-testcmd-' '' | string replace '.fish' '')
    if test "$actual_hash" = "$expected_hash_single"
        echo "Test 1: Single arg hash matches"
        _pass "single arg hash = $actual_hash"
    else
        echo "Test 1: Single arg hash mismatch"
        echo "  expected: $expected_hash_single"
        echo "  actual:   $actual_hash"
        _fail "single arg hash does not match"
    end
else
    echo "Test 1: Single arg hash - NO CACHE FILE FOUND"
    _fail "no cache file created for single arg case"
end

# Test case 2: Multi-arg case
# When argv = {./testcmd arg1 arg2}, echo -n "$argv" produces "./testcmd arg1 arg2"
set expected_hash_multi (echo -n "./testcmd arg1 arg2" | md5sum | cut -d' ' -f1)

_evalcache ./testcmd arg1 arg2 2>/dev/null

# Find the cache file for multi-arg
set actual_cache_multi (ls "$FISH_EVALCACHE_DIR"/init-testcmd-*.fish 2>/dev/null | head -1)
if test -n "$actual_cache_multi"
    set base_multi (basename "$actual_cache_multi")
    set actual_hash_multi (echo "$base_multi" | string replace 'init-testcmd-' '' | string replace '.fish' '')
    if test "$actual_hash_multi" = "$expected_hash_multi"
        echo "Test 2: Multi-arg hash matches"
        _pass "multi-arg hash = $actual_hash_multi"
    else
        echo "Test 2: Multi-arg hash mismatch"
        echo "  expected: $expected_hash_multi"
        echo "  actual:   $actual_hash_multi"
        _fail "multi-arg hash does not match"
    end
else
    echo "Test 2: Multi-arg hash - NO CACHE FILE FOUND"
    _fail "no cache file created for multi-arg case"
end

# Test case 3: Hash consistency - same args should produce the same cache file
# Call again with same args - should reuse the SAME cache file
set -l cache_before (ls "$FISH_EVALCACHE_DIR"/init-testcmd-*.fish 2>/dev/null | string join " ")
_evalcache ./testcmd arg1 arg2 2>/dev/null
set -l cache_after (ls "$FISH_EVALCACHE_DIR"/init-testcmd-*.fish 2>/dev/null | string join " ")

if test "$cache_before" = "$cache_after"
    echo "Test 3: Same args reuse same cache file"
    _pass "cache files identical: $cache_before"
else
    echo "Test 3: Same args reuse same cache file"
    _fail "cache files changed: before='$cache_before' after='$cache_after'"
end

# Clean up
rm -rf "$temp"

echo ""
echo "=== Results: $_test_pass passed, $_test_fail failed ==="
if functions -q @test
    @test "hash consistency checks pass" "$_test_fail" -eq 0
end
exit $_test_fail
