#!/bin/sh
# test tests
a=10
if test ! \( \( $a -ge 0 \) -a \( ! \( $a -ge 1 \) \) \)
then
    echo This is printed
else
    echo This is not
fi

if test ! \( -z zero \)
then
    echo This is printed
else
    echo This is not
fi

if test ! \( $a = 0 \) -a \( ! \( $a = 1 \) \)
then
    echo This is printed
else
    echo This is not
fi

if test ! \( $a -ge 0 \)
then
    echo This is not
else
    echo This is printed
fi
