@echo === _evalcache ===

set temp (mktemp -d)
cd "$temp"

set -lx FISH_EVALCACHE_DIR "$temp"


echo '#/usr/bin/env bash' >testeval
echo 'echo "echo testeval"' >>testeval
chmod +x testeval

set resultMD5 (echo -n "./testeval" | md5sum | cut -d' ' -f1)
set testFile "$FISH_EVALCACHE_DIR/init-testeval-$resultMD5.fish"

_evalcache ./testeval

@test "cache file exists" -f "$testFile"

@test "cache equals eval result" (./testeval) = (cat "$testFile")

set otherMD5 (echo -n "./testeval 123 456" | md5sum | cut -d' ' -f1)
set otherFile "$FISH_EVALCACHE_DIR/init-testeval-$otherMD5.fish"

_evalcache ./testeval 123 456

@test "removes other arguments cache file" ! -f "$testFile"

rm -rf "$temp"
