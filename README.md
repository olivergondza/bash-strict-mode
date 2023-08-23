# bash-strict-mode

The declaration build atop of work by [Aaron Maxwell](http://redsymbol.net/articles/unofficial-bash-strict-mode/)
and [Michael Daffin](https://disconnected.systems/blog/another-bash-strict-mode/) and their respective strict mode implementations.

The evolution and some of the rationale can be seen in an introductory [blog post](https://olivergondza.github.io/2019/10/01/bash-strict-mode.html).

## Usage
[The preamble](https://github.com/olivergondza/bash-strict-mode/blob/master/strict-mode.sh) needs to be placed at the top of every executable bash script.
There is one exception: sourced library files.
It is not needed there provided those only contain functions for other script, and are never executed directly.

It is recommended not to change the preamble manually.
Keeping it as it is makes it easier to locate the scripts declaring bash strict mode, and simplified mass updates to a new version of the strict mode.
If there are changes to do per individual script, declare them after the strict mode preamble.

## Overcoming common difficulties

Frequently used bash code is sometimes unusable when bash strict mode is used.
This might be surprising or even annoying to newcomers.
Rather than avoiding or turning off the strict mode, here are the examples of correct bash code working in strict mode.

### Commands that are expected to fail (sometimes)

For such anticipated failures, stopping the script is not desirable.

#### `or-true`

Tolerating the eventual failures is ok in cases it is known the non-zero status does not indicate real problem:
```bash
# grep can fail if output contains no error
grep "Error:" ./out.log || true
```
It is a good practice to document _why_ it is desirable to tolerate command failures, and _when_ they can occur.

---

#### `if-command`

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
  To avoid that, wrap the command in a descriptively named function - it will make the code self-documenting as well.
- Reversing the conditional (`if ! command ...`) will also reverse the exit code.
  That will effectively turn the exit code into `0` throwing away meaningful information.
  Using the `!` is tempting when there is no meaningful action to do in case of command success, when the `if` branche would be efectively empty.
  It might be adequate in case the command's exit code is not needed.
  Otherwise, consult `or-block` pattern.
---

#### `or-block`

To provide handling for command failure only:

```bash
potentialy-failing-command || {
    command_status=$?
    echo "Failed with $command_status"
}
```
There are several downsides:
- The value of `$?` needs to be captured early in the block, before it get overwritten by other statements.
- Complicated or long commands can obscure the `||` at the end, making it hard to understand the program flow.
  To avoid that, wrap the command in a descriptively named function - it will make the code self-documenting as well.
