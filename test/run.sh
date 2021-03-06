#!/usr/bin/env bash
# https://github.com/olivergondza/bash-strict-mode
set -u
trap 's=$?; echo >&2 -e "$0: Error on line "$LINENO": $BASH_COMMAND ($s)\n\n"' ERR

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
CACHE="$DIR/../cache"
STRICT_MODE="$DIR/../strict-mode.sh"

TMP="$(mktemp -d "/tmp/bash-safe-mode-XXXXXXXX")"
rm -rf "$TMP" && mkdir -p "$TMP"
trap "rm -rf '$TMP'" EXIT

goreutils="$CACHE/goreutils"
if [ ! -d "$goreutils" ]; then
    git clone https://github.com/olivergondza/goreutils.git "$goreutils" > /dev/null
fi
export PATH="$PATH:$goreutils/bin"

function snip() {
    mkdir -p "$TMP/snip/positive" "$TMP/snip/negative"
    dst="$TMP/snip/${1}.sh"
    cp "$STRICT_MODE" "$dst"
    cat "$DIR/$1.sh" >> "$dst"
    chmod +x "$dst"
    echo "$dst"
}

# Gotcha: The pipeline will not be aborted early when it fails
# Gotcha: The trap will print the last sub-command no matter which one has failed

assert --running "$(snip 'negative/top-level-undefined')" --exit-with 1 --no-out --err-matches 'NO_SUCH_VAR: unbound variable'
assert --running "$(snip 'negative/top-level-fail')" --exit-with 1 --no-out --err-matches 'Error on line .: false'
assert --running "$(snip 'negative/top-level-pipefail')" --exit-with 1 --out-equals $'executed anyway\n' --err-matches 'Error on line .: echo '

assert --running "$(snip 'negative/function-undefined')" --exit-with 1 --no-out --err-matches 'NO_SUCH_VAR: unbound variable'
# TODO set -E
# assert --running "$(snip 'negative/function-fail')" --exit-with 1 --no-out --err-matches 'Error on line .: false'
# TODO set -o errtrace
# assert --running "$(snip 'negative/function-pipefail')" --exit-with 1 --out-equals $'executed anyway\n' --err-matches 'Error on line ..: echo '

assert --running "$(snip 'negative/subshell-undefined')" --exit-with 1 --no-out --err-matches 'NO_SUCH_VAR: unbound variable'
assert --running "$(snip 'negative/subshell-fail')" --exit-with 1 --no-out --err-matches 'Error on line .: \( false \)'
assert --running "$(snip 'negative/subshell-pipefail')" --exit-with 1 --out-equals $'executed anyway\n' --err-matches 'Error on line ..: true | false | echo "executed anyway" '

# Gotcha: Command substitution result is ignored in many contexts: https://unix.stackexchange.com/questions/23026/how-can-i-get-bash-to-exit-on-backtick-failure-in-a-similar-way-to-pipefail
assert --running "$(snip 'negative/comsub-undefined')" --exit-with 1 --no-out --err-matches 'NO_SUCH_VAR: unbound variable'
assert --running "$(snip 'negative/comsub-fail')" --exit-with 1 --no-out --err-matches 'Error on line .: a="\$\(false\)"'
assert --running "$(snip 'negative/comsub-pipefail')" --exit-with 1 --no-out --err-matches 'Error on line ..: true | false | echo "executed anyway" '

# Gotcha: Process substitution does not propagate the errors at all. Use named pipes instead

########

assert --running "$(snip "positive/top-level-or-true")" --succeeds --out-equals $'continued\n'
assert --running "$(snip "positive/top-level-default-undeclared")" --succeeds --out-equals $'continued\n'
assert --running "$(snip "positive/associative-array-key-exists")" --succeeds --out-equals $'continued\n'
