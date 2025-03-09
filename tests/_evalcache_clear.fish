@echo === _evalcache_clear ===

set temp (mktemp -d)
cd "$temp"

set -lx FISH_EVALCACHE_DIR "$temp"

set resultMD5 (echo -n "./testeval" | md5sum | cut -d' ' -f1)
set testFile "$FISH_EVALCACHE_DIR/init-testeval-$resultMD5.fish"

echo testtesttest >"$testFile"

@test "cache file exists" -f "$testFile"

@test "all cache file could remove" (echo -n "y" | _evalcache_clear) $status -eq 0

@test "cache file does not exists" ! -f "$testFile"

@echo === _evalcache_clear $testFile ===

set resultMD5 (echo -n "./testeval" | md5sum | cut -d' ' -f1)
set testFile "$FISH_EVALCACHE_DIR/init-testeval-$resultMD5.fish"
echo testtesttest >"$testFile"

set resultMD5_2 (echo -n "./testeval2" | md5sum | cut -d' ' -f1)
set testFile2 "$FISH_EVALCACHE_DIR/init-testeval2-$resultMD5_2.fish"
echo testtesttest2 >"$testFile2"

@test "cache file exists" -f "$testFile"
@test "cache file exists" -f "$testFile2"

@test "target cache file could remove" (echo -n "y" | _evalcache_clear testeval) $status -eq 0

@test "cache file does not exists" ! -f "$testFile"
@test "cache file exists" -f "$testFile2"
