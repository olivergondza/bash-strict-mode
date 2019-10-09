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
export PATH="$PATH:$goreutils/bin/assert"

function snip() {
    mkdir -p "$TMP/snip/positive" "$TMP/snip/negative"
    dst="$TMP/snip/${1}.sh"
    cp "$STRICT_MODE" "$dst"
    cat "$DIR/$1.sh" >> "$dst"
    chmod +x "$dst"
    echo "$dst"
}

assert --running "$(snip 'negative/top-level-undefined')" --exit-with 1 --no-out --err-matches 'NO_SUCH_VAR: unbound variable'
assert --running "$(snip 'negative/top-level-fail')" --exit-with 1 --no-out --err-matches 'Error on line .: false'
assert --running "$(snip 'negative/top-level-pipefail')" --exit-with 1 --out-equals $'executed anyway\n' --err-matches 'Error on line .: echo '

assert --running "$(snip 'negative/function-undefined')" --exit-with 1 --no-out --err-matches 'NO_SUCH_VAR: unbound variable'
# TODO set -e
# assert --running "$(snip 'negative/function-fail')" --exit-with 1 --no-out --err-matches 'Error on line .: false'
# TODO set -o errtrace
# assert --running "$(snip 'negative/function-pipefail')" --exit-with 1 --out-equals $'executed anyway\n' --err-matches 'Error on line ..: echo '

assert --running "$(snip "positive/top-level-or-true")" --succeeds --out-equals $'continued\n'
assert --running "$(snip "positive/top-level-default-undeclared")" --succeeds --out-equals $'continued\n'
