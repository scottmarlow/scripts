#!/bin/sh

current = $PWD

if [ ! -d $2 ]; then
    mkdir $2
fi
cd $2
echo "downloading for $2"
curl -O $1/ws/work/logs/*zip*/logs.zip
echo "download complete for $2, time to unzip"
unzip -o logs.zip
echo "processing complete for $2"
cd $current
