# Testing for associative array presence can be tricky with set -u in cases, when the key is not present.

# Let's have an associative array like:
declare -A foo
foo[bar]="bax"

# Following test passes when the key is present, it fails otherwise with
# `foo[none]: unbound variable` in case they key was not set.
test ! -z "${foo[bar]}"

# Using `test -v` for the variable name (mind there is no variable expansion) works for strict mode in both cases.
test -v "foo[bar]"
test ! -v "foo[none]"

echo "continued"
