function _evalcache_clear
  if test -z "$FISH_EVALCACHE_DIR"
    set -gx FISH_EVALCACHE_DIR "$HOME/.fish-evalcache"
  end

  rm -i "$FISH_EVALCACHE_DIR"/init-*.fish
end
