@echo === _evalcache_clear ===

set resultMD5 (echo -n "./testeval" | md5sum | cut -d' ' -f1)
set testFile "$HOME/.fish-evalcache/init-testeval-$resultMD5.fish"

echo testtesttest >"$testFile"

@test "cache file exists" -f "$testFile"

@test "all cache file could remove" (echo -n "y" | _evalcache_clear) $status -eq 0

@test "cache file does not exists" ! -f "$testFile"

@echo === _evalcache_clear $testFile ===

set resultMD5 (echo -n "./testeval" | md5sum | cut -d' ' -f1)
set testFile "$HOME/.fish-evalcache/init-testeval-$resultMD5.fish"
echo testtesttest >"$testFile"

set resultMD5_2 (echo -n "./testeval2" | md5sum | cut -d' ' -f1)
set testFile2 "$HOME/.fish-evalcache/init-testeval2-$resultMD5_2.fish"
echo testtesttest2 >"$testFile2"

@test "cache file exists" -f "$testFile"
@test "cache file exists" -f "$testFile2"

@test "target cache file could remove" (echo -n "y" | _evalcache_clear testeval) $status -eq 0

@test "cache file does not exists" ! -f "$testFile"
@test "cache file exists" -f "$testFile2"
