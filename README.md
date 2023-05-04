# bash-strict-mode

The declaration build atop of work by [Aaron Maxwell](http://redsymbol.net/articles/unofficial-bash-strict-mode/)
and [Michael Daffin](https://disconnected.systems/blog/another-bash-strict-mode/) and their respective strict mode implementations.

The evolution and some of the rationale can be seen in an introductory [blog post](https://olivergondza.github.io/2019/10/01/bash-strict-mode.html).

# Overcoming common difficulties

Frequently used bash code is sometimes unusable when bash strict mode is used.
This might be surprising or even annoying to newcomers.
Rather than avoiding or turning of the strict mode, here are the examples of correct bash code working in strict mode.

## Commands that are expected to fail (sometimes)

For such anticipated failures, stopping the script is not desirable.

### `or-true`

Tolerating the eventual failures is ok in cases it is known the non-zero status does not indicate real problem:
```bash
# grep can fail if output contains no ERROR
grep "Error:" ./out.log || true
```
---

### `if-command`

To capture the error code for further processing (diagnostics, recovery, etc.), wrap the offending commend in `if`:
```bash
if grep needle ./haystack.log; then
    echo "Succeeded"
else
    ret=$?
    echo "Failed $ret"
fi
```
There are several downsides:
- The value of `$?` needs to be captured early in the block, before it get overwritten by other statements.
- Complicated or long commands will become even harder to understand when run as `if` conditionals.
  To avoid that, wrap them in descriptively named function - it will make the code self-documenting as well.
- Reversing the conditional (`if ! command ...`) will also reverse the exit code.
  That will effectively turn the meaningful exit code into `0` throwing away any value it had.
  This is tempting to use in case there is no meaningful action in case of command success.
  Though leaving one of the `if/else` branches empty is far from idiomatic.
---

### `or-block`

For handling only the negative command outcome, this can be more practical:

```bash
potentialy-failing-command || {
    command_status=$?
    echo "Failed with $command_status"
}
```
There are several downsides:
- The value of `$?` needs to be captured early in the block, before it get overwritten by other statements.
- Complicated or long commands can obscure the `||` at the end, making it hard to understand the program flow.
  To avoid that, wrap them in descriptively named function - it will make the code self-documenting as well.
