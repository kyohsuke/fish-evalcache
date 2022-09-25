function _evalcache_clear
  if test -z "$FISH_EVALCACHE_DIR"
    export FISH_EVALCACHE_DIR="$HOME/.fish-evalcache"
  end

  rm -i "$FISH_EVALCACHE_DIR"/init-*.sh
end
