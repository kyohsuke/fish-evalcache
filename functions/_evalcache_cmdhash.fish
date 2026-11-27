function _evalcache_cmdhash
    set -l data (string join " " $argv)

    if command -v md5 >/dev/null
        # macOS / BSD: md5 -q -s string
        command md5 -q -s "$data"
    else if command -v md5sum >/dev/null
        # Linux: md5sum output format is "<hash>  -"
        set -l out (echo -n "$data" | command md5sum)
        string split -f1 " " $out
    else
        # Fallback when neither md5 nor md5sum is found
        string replace -ra '[^a-zA-Z0-9_-]' '_' "$data"
    end
end
