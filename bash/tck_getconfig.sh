#!/bin/sh

current = $PWD

if [ ! -d $1 ]; then
    mkdir $1
fi
cd $1
echo "downloading for $1"
curl -O $1/configure
echo "download complete for $1"
cd $current
