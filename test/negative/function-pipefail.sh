function f() {
    # Gotcha: The pipeline will not be aborted early when it fails
    # Gotcha: The trap will print the last sub-command no matter which one has failed
    true | false | echo "executed anyway"
}
f
