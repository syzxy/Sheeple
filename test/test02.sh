#!/bin/sh
# test echo
a='shell'
b='perl'
c="sheeple"
d="$a$b"

# double quotes
echo "with double quotes"
echo "$c converts $a to $b\n"

# single quotes
echo 'with single quotes'
echo '$c converts $a to $b\n'

# echo -n
echo "with echo -n"
echo -n $c      # trailing whitespace
echo -n ' converts '
echo -n "$a "
echo -n to
echo -n " $b" "\n"

