@echo === _evalcache ===

set temp (mktemp -d)
cd $temp

echo '#/usr/bin/env bash' > testeval
echo 'echo "echo testeval"' >> testeval
chmod +x testeval

set resultMD5 (echo -n "./testeval" | md5sum | cut -d' ' -f1)
set testFile "$HOME/.fish-evalcache/init-testeval-$resultMD5.fish"

_evalcache ./testeval


@test "cache file exists" -f "$testFile"

@test "cache equals eval result" (./testeval) = (cat "$testFile")

rm -rf $temp
