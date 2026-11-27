# evalcache 処理速度改善 — 調査結果と最適化計画

対象リポジトリ: `/workspace`(fish-evalcache / kyohsuke/fish-evalcache)

## 1. プロジェクト概要

fish shell 向けプラグイン。シェル起動時に実行される初期化ラッパー
(例: `anyenv init -f fish`)の出力をキャッシュし、以降の shell startup で
実コマンドを再実行せずに source する、という仕組み。

- `functions/_evalcache.fish` … 本体
- `functions/_evalcache_clear.fish` … キャッシュ削除
- `tests/_evalcache.fish`, `tests/_evalcache_clear.fish` … fishtape によるテスト
- `.github/workflows/test.yml` … CI(fish + fishtape)
- `README.md`, `LICENSE`, `opencode.jsonc`

上流実装: https://github.com/mroth/evalcache(`evalcache.plugin.zsh`)

## 2. 調査で確認した実装上の問題

### 2.1 [高] キャッシュキー計算で外部プロセスを毎回実行する(シェル起動のホットパス)

対象: `functions/_evalcache.fish` の該当行

```fish
set -f cmdHash noHash

if command -v md5 >/dev/null
    set -f cmdHash (echo -n "$argv" | md5)
else if command -v md5sum >/dev/null
    set -f cmdHash (echo -n "$argv" | md5sum | cut -d' ' -f1)
end
```

- fish の `echo` は builtin だが、`md5` / `md5sum`、`cut` はいずれも外部コマンド。
- キャッシュヒット時・ヒット時であっても毎回 fork + exec が発生する。
  Linux では `md5sum` と `cut` の2プロセス、macOS では `md5` 1プロセス(+パイプ2段)。
- 上流 zsh 実装(`mroth/evalcache`)は外部プロセスを一切使わないシェル内ハッシュ
  (Jenkins one-at-a-time hash)で `cmdHash` を計算していた。
  fish 版への移植時に外部コマンドベースの実装へ置き換わっているため、
  シェル起動のたびに evalcache 本体だけで fork/exec が数回発生し、
  本来なら shell startup を高速化するプラグインなのに、その分だけ
  オーバーヘッドが乗っている、という構造が判明した。
- なお fish の `echo` は `-n`(改行なし)・`-s`(引数間区切りなし)をサポートしており、
  ハッシュ対象文字列の作り方は問題ない。

### 2.2 [中] `basename` も毎回外部プロセスを起動する

対象: `functions/_evalcache.fish` の該当行

```fish
set -f cmd (basename $argv[1])
```

- fish には `basename` builtin がないため `/usr/bin/basename` を毎回起動する。
- キャッシュヒット時にも `cmd`(キャッシュファイル名の一部)が必要なため、
  この外部コマンドは hot path で必ず実行される。

### 2.3 [低] キャッシュ未満時・削除時の後処理

- miss 時に `mkdir -p`、引数違いキャッシュの全削除ループ内で
  `set -l baseName (basename $fName)` を呼んでいる(こちらも fork)。
- `rm -f` はファイルごとにプロセスを起動しているため、一気にまとめられる。

## 3. 潜在バグ(速度改善と並行して修正を検討すべき箇所)

### 3.1 [バグ] 出力が空の init コマンドでキャッシュが機能しない

対象: `functions/_evalcache.fish` の該当行

```fish
else if test -s "$cacheFile"
```

- fish の `test` の `-s` は「**ファイルサイズ > 0** を返す」ことを公式ドキュメントで確認済み。
- init コマンドの出力が空の場合、リダイレクト `"$argv" >"$cacheFile"` により空ファイルが
  作られ、`test -s` は false を返す → **毎回 cache miss → 毎回実コマンドを実行**する。
- 対応: 存在確認の `test -f`(または `test -e`)に置き換える。

### 3.2 [疑似/要修正] `FISH_EVALCACHE_DISABLE` 時の分岐

対象: `functions/_evalcache.fish`

```fish
eval ($argv | source)
```

- fish 公式ドキュメント(`eval` の説明)では、`eval` は複数引数をスペース区切りで結合し
  コマンド文字列として評価、あるいは変数展開による「変数 as コマンド」
  (`set cmd ls -la; $cmd`)を利用することが推奨されている。
- pipe を組み込んだ `eval ($argv | source)` は意図の整理が必要な形となっている。
  キャッシュをバイパスしてコマンドを実行する、という挙動にするなら正しい形は
  `eval $argv` 系になるはず。

### 3.3 [低確度] md5/md5sum 不在環境でのフォールバック

`set -f cmdHash noHash` の初期化が残っており、両方のハッシュコマンドが無い環境では
全コマンドで同一キャッシュファイル名となり、引数違いキャッシュの分離が壊れる。

## 4. 最適化方針(案)

### 4.1 [主] evalcache 本体から外部プロセスを排除する

- 上流 zsh 実装と同じく、シェル内で完結するハッシュ計算へ戻す。
  - 案 A: Jenkins one-at-a-time hash を fish に移植(上流実装と同一のキー計算を維持)。
  - 案 B: `md5sum` を単一プロセスにしつつ `cut` を外す(fish builtin の `string` 等で hash を抽出)。
- 案 A は実装・移植コストが低く、上流とキー計算を完全に揃えられるため優先度が高い。

### 4.2 [中] `basename` の外部呼び出しを shell builtin / `string` で置換。

### 4.3 [低] キャッシュ削除(`rm`)を1プロセスで処理できる形に整理。

### 4.4 [低] バグ修正(`test -f` / DISABLE 分岐 / hash fallback)を同一リファクタで実施。

## 5. テストへの影響

- `tests/_evalcache.fish`、`tests/_evalcache_clear.fish` が md5sum + `cut` で
  キャッシュキーを再現計算している。
- キャッシュキー計算方法を変える場合は、テスト側の期待値も同時に更新が必要。

## 6. 計測・検証方法(案)

- fish での shell startup 時間前後比較(`fish -c` を用いた計測)。
- evalcache miss → hit の実測(fishtape / 手動)。
- CI(`Test` workflow)でのリグレッション確認。

## 7. 実装ステップ(案)

1. 現状ベンチマーク取得(任意)。
2. `_evalcache.fish` のキャッシュキー計算を外部プロセスなしに変更(上流 zsh 方式の移植)。
3. `basename` 外部呼び出しを排除。
4. キャッシュ存在確認を `test -s` → `test -f` に修正(空出力対応)。
5. `FISH_EVALCACHE_DISABLE` 分岐を正しい形(`eval $argv` 系)に修正。
6. md5/md5sum 不在時のフォールバックを整備。
7. キャッシュ削除周りを fork 削減(案)。
8. テスト更新・CI 通過確認。

## 8. リスクと注意点

- ハッシュアルゴリズム変更により既存キャッシュが無効化される可能性があるが,
  再生成されるだけなので実害は軽微。
- md5sum 系コマンド不在環境での動作保証が必要。
- fish バージョン間での builtin 仕様差(`echo -n`, `test -s`, `eval` の挙動)への注意。
