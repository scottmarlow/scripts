#!/bin/sh

current = $PWD

if [ ! -d $1 ]; then
    mkdir $1
fi
cd $1
echo "downloading for $1"
curl -O $1/ws/work/logs/*zip*/logs.zip
echo "download complete for $1, time to unzip"
unzip -o logs.zip
echo "processing complete for $1"
cd $current
