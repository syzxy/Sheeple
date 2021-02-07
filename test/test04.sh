#!/bin/sh
# test translation of $* and $@

echo '$@'
for a in "$@"
do
    echo "$a"
done
echo
echo '$*'
for a in "$*"
do
    echo "$a"
done
