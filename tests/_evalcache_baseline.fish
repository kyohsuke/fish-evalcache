# Baseline test: verify existing behavior before fixes
# Tests use native fish commands

set temp (mktemp -d)
cd "$temp"
set -lx FISH_EVALCACHE_DIR "$temp"

# Create test commands
echo '#!/usr/bin/env bash' > testcmd
echo 'echo "hello testcmd"' >> testcmd
chmod +x testcmd

echo '#!/usr/bin/env bash' > testcmd_multi
echo 'echo "args: $@"' >> testcmd_multi
chmod +x testcmd_multi

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

# === Test 1: Basic caching creates cache file ===
_evalcache ./testcmd
set h1 (echo -n ./testcmd | md5sum | cut -d' ' -f1)

if test -f "$FISH_EVALCACHE_DIR/init-testcmd-$h1.fish"
    echo "Test 1: Basic caching creates cache file"
    _pass "cache file exists"
else
    echo "Test 1: Basic caching creates cache file"
    _fail "cache file NOT created (expected init-testcmd-$h1.fish)"
end

# === Test 2: Second call reuses cache ===
_evalcache ./testcmd
if test -f "$FISH_EVALCACHE_DIR/init-testcmd-$h1.fish"
    echo "Test 2: Second call reuses cache"
    _pass "cached file persists on second call"
else
    echo "Test 2: Second call reuses cache"
    _fail "cache file missing on second call"
end

# === Test 3: Cache file content matches command output ===
set cmd_output (./testcmd)
set cache_content (cat "$FISH_EVALCACHE_DIR/init-testcmd-$h1.fish")
if test "$cmd_output" = "$cache_content"
    echo "Test 3: Cache content matches command output"
    _pass "output matches"
else
    echo "Test 3: Cache content matches command output"
    _fail "mismatch: expected='$cmd_output' got='$cache_content'"
end

# === Test 4: Different args create different cache file ===
# The hash is computed from the FULL command string (cmd + args), matching what _evalcache does
_evalcache ./testcmd_multi arg1 arg2
set h2 (echo -n "./testcmd_multi arg1 arg2" | md5sum | cut -d' ' -f1)

if test -f "$FISH_EVALCACHE_DIR/init-testcmd_multi-$h2.fish"
    echo "Test 4: Different args create new cache file"
    _pass "new args create new cache"
else
    echo "Test 4: Different args create new cache file"
    _fail "new cache NOT created (expected init-testcmd_multi-$h2.fish)"
end

# === Test 5: Old cache removed when SAME command, DIFFERENT args ===
# First, create a cache with args "v1"
_evalcache ./testcmd_multi arg_v1
set h_v1 (echo -n "./testcmd_multi arg_v1" | md5sum | cut -d' ' -f1)

# Then, create a cache with different args "v2" - old v1 cache should be deleted
_evalcache ./testcmd_multi arg_v2

if test -f "$FISH_EVALCACHE_DIR/init-testcmd_multi-$h_v1.fish"
    echo "Test 5: Old same-cmd cache should be removed when args differ"
    _fail "old cache file still exists (was NOT deleted)"
else
    echo "Test 5: Old same-cmd cache removed when args differ"
    _pass "old same-cmd cache properly removed"
end

# List all cache files for debugging
echo ""
echo "Cache directory contents:"
ls -la "$FISH_EVALCACHE_DIR" 2>/dev/null || echo "  (empty)"
echo ""

# Clean up
rm -rf "$temp"

# Report
echo ""
echo "=== Results: $_test_pass passed, $_test_fail failed ==="
if functions -q @test
    @test "baseline checks pass" "$_test_fail" -eq 0
end
exit $_test_fail

