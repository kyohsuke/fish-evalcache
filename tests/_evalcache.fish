@echo === _evalcache ===

set temp (mktemp -d)
cd "$temp"

set -lx FISH_EVALCACHE_DIR "$temp"


echo '#/usr/bin/env bash' >testeval
echo 'echo "echo testeval"' >>testeval
chmod +x testeval

set resultMD5 (_evalcache_cmdhash ./testeval)
set testFile "$FISH_EVALCACHE_DIR/init-testeval-$resultMD5.fish"

_evalcache ./testeval

@test "cache file exists" -f "$testFile"

@test "cache equals eval result" (./testeval) = (cat "$testFile")

set otherMD5 (_evalcache_cmdhash ./testeval 123 456)
set otherFile "$FISH_EVALCACHE_DIR/init-testeval-$otherMD5.fish"

_evalcache ./testeval 123 456

@test "removes other arguments cache file" ! -f "$testFile"

# Empty output test
echo '#/usr/bin/env bash' >emptyeval
chmod +x emptyeval

set emptyMD5 (_evalcache_cmdhash ./emptyeval)
set emptyFile "$FISH_EVALCACHE_DIR/init-emptyeval-$emptyMD5.fish"

_evalcache ./emptyeval

@test "empty output cache file exists" -f "$emptyFile"

# Calling again should hit cache
_evalcache ./emptyeval
@test "empty output cache remains valid" -f "$emptyFile"

rm -rf "$temp"
