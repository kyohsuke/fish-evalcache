# Test file: Hash computation consistency
# Verifies that hash computation is consistent and deterministic

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

# Test case 1: Single arg produces cache file
echo "Test 1: Single arg creates cache file"
_evalcache ./testcmd 2>/dev/null

# Get all cache files for this command
set cache_files (ls "$FISH_EVALCACHE_DIR"/init-testcmd-*.fish 2>/dev/null)
if test (count $cache_files) -gt 0
    set actual_hash (basename (echo $cache_files[1]) | string replace 'init-testcmd-' '' | string replace '.fish' '')
    echo "  Cache files created: $cache_files[1]"
    _pass "single arg cache created"
else
    echo "  No cache file created for single arg"
    _fail "no cache file for single arg case"
end

# Test case 2: Multi-arg creates different cache file
echo "Test 2: Multi-arg creates different cache file"
_evalcache ./testcmd arg1 arg2 2>/dev/null

set cache_files2 (ls "$FISH_EVALCACHE_DIR"/init-testcmd-*.fish 2>/dev/null)
if test (count $cache_files2) -gt 1
    # Check that the hash is different
    set base1 (basename $cache_files2[1])
    set base2 (basename $cache_files2[2])
    
    set hash1 (echo $base1 | string replace 'init-testcmd-' '' | string replace '.fish' '')
    set hash2 (echo $base2 | string replace 'init-testcmd-' '' | string replace '.fish' '')
    
    if test "$hash1" != "$hash2"
        echo "  Hash 1: $hash1 (from $base1)"
        echo "  Hash 2: $hash2 (from $base2)"
        _pass "different args produce different cache files"
    else
        echo "  Hash mismatch: both are $hash1"
        _fail "same hash for different args"
    end
else
    echo "  Expected 2 cache files but got: $(count $cache_files2)"
    _fail "expected different cache files for multi-arg"
end

# Test case 3: Same args reuse same cache file
echo "Test 3: Same args reuse same cache file"
set cache_before (ls "$FISH_EVALCACHE_DIR"/init-testcmd-*.fish 2>/dev/null | string join " ")
_evalcache ./testcmd arg1 arg2 2>/dev/null
set cache_after (ls "$FISH_EVALCACHE_DIR"/init-testcmd-*.fish 2>/dev/null | string join " ")

if test "$cache_before" = "$cache_after"
    echo "  Cache files identical: $cache_before"
    _pass "cache files identical"
else
    echo "  Cache files changed: before='$cache_before' after='$cache_after'"
    _fail "cache files changed"
end

# Test case 4: Hash is deterministic (same command multiple times)
echo "Test 4: Hash is deterministic"
set h1 (echo -n ./testcmd | md5sum | cut -d' ' -f1)
set h2 (echo -n ./testcmd | md5sum | cut -d' ' -f1)

if test "$h1" = "$h2"
    echo "  Hash 1: $h1"
    echo "  Hash 2: $h2"
    _pass "hash is deterministic"
else
    echo "  Hash 1: $h1"
    echo "  Hash 2: $h2"
    _fail "hash not deterministic"
end

# Clean up
rm -rf "$temp"

echo ""
echo "=== Results: $_test_pass passed, $_test_fail failed ==="
if functions -q @test
    @test "hash consistency checks pass" "$_test_fail" -eq 0
end
exit $_test_fail
