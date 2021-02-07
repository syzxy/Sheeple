#!/bin/dash

echo "======== *"
for file in *; do
    echo $file
done

echo "======== ?.*"
for file in ?.*; do
    echo $file
done

echo "======== [ab].*"
for file in [ab].*; do
    echo $file
done

echo ========
for word in Andrew 100% rocks; do
    echo $word
done

