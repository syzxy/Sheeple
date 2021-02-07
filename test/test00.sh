#!/bin/sh
# test nested expr
expr \( \( \( \( $1 \* 2 \) + 10 \) \/ 2 \) - $1 \) # number magic trick
# should print 5 given any int
