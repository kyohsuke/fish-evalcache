#!/usr/bin/fish
# Test runner that sources our functions and runs test scripts
set workspace_dir (dirname (status filename))

# --- Argument parsing ---
if test (count $argv) -eq 0
    echo "Usage: run_tests.fish [test_file ...]"
    echo "Running all tests in tests/ directory..."
    set test_files tests/*_test*.fish
else
    set test_files $argv
end

# Counters
set _pass 0
set _fail 0
set _total 0

# Build init command to source our functions (relative to workspace)
set init_src "source $workspace_dir/functions/_evalcache.fish; source $workspace_dir/functions/_evalcache_clear.fish"

for test_file in $test_files
    echo "=== Running: $test_file ==="
    fish \
        --init-command="$init_src" \
        "$test_file" 2>&1
    set test_status $status
    if test $test_status -ne 0
        set _fail (math $_fail + 1)
        echo "  ^^^ FAILED (exit: $test_status)"
    else
        set _pass (math $_pass + 1)
    end
    echo ""
    set _total (math $_total + 1)
end

echo "=== Results: $_pass passed, $_fail failed (out of $_total) ==="
if test $_fail -gt 0
    exit 1
end

