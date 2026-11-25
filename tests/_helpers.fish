# Helper functions to replicate fishtape's @echo and @test operators

function @echo
    echo "# $argv"
end

function @test --argument-names name
    # Minimal @test that outputs test results
    # This version does inline assertions: @test "name" result expected
    # Or: @test "name" condition
    # Format: @test "test name" [operator] [args...]
    if test (count $argv) -eq 0
        return 1
    end

    set _test_name "$argv[1]"
    set -e argv[1]

    # Determine operator type
    set _op ""
    set _result "false"

    # Try various fish test operators
    set _args (count $argv)
    if test $_args -ge 2
        # Check known fish test operators
        if string match -qr '^[nzbcdLOpksStuwx]$' "$argv[1]"
            set _op "-$argv[1]"
            set -e argv[1]
        else if test "$argv[1]" = '-f' -o "$argv[1]" = '-d'
            set _op "$argv[1]"
            set -e argv[1]
        else if test "$argv[1]" = '= ' -o "$argv[1]" = '='
            set _op "$argv[1]"
            set -e argv[1]
        end
    end

    # Evaluate the test argument
    set -l test_args $argv
    set -l test_output
    set -l test_status 1

    # For file tests: -f "$path", ! -f "$path"
    if test (count $test_args) -eq 1
        # Single argument file test: -f path
        if test "$_op" = "-f"
            if test -f "$test_args[1]"
                set _result "true"
            end
        else if test "$_op" = "! -f"
            set -e test_args[1]
            # Parse "! -f" as operator
            if test -f "$test_args[1]"
                set _result "false"
            else
                set _result "true"
            end
        else if test "$_op" = "-d"
            if test -d "$test_args[1]"
                set _result "true"
            end
        end
    else if test (count $test_args) -eq 2
        if test "$_op" = "="
            # String comparison: "$a" = "$b"
            if test "$test_args[1]" = "$test_args[2]"
                set _result "true"
            end
        else if test "$_op" = '$status'
            # (cmd) $status -eq 0
            # This is tricky - let's handle it
            set _result "$test_args[2]"
        end
    end

    if test "$_result" = "true"
        echo "ok $TEST_NUM $_test_name"
        set _PASS_COUNT (math $_PASS_COUNT + 1)
    else
        set _FAIL_COUNT (math $_FAIL_COUNT + 1)
        echo "not ok $TEST_NUM $_test_name"
        echo "  ---"
        echo "    operator: $_op"
        echo "  ..."
    end
    TEST_NUM (math $TEST_NUM + 1)
end
