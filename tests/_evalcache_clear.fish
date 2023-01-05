@echo === _evalcache_clear ===

set resultMD5 (echo -n "./testeval" | md5sum | cut -d' ' -f1)
set testFile "$HOME/.fish-evalcache/init-testeval-$resultMD5.fish"

echo testtesttest >"$testFile"

@test "cache file exists" -f "$testFile"

@test "cache file could remove" (echo -n "y" | _evalcache_clear) $status -eq 0

@test "cache file does not exists" ! -f "$testFile"
