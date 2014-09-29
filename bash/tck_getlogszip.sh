#!/bin/sh

if [ ! -d $2 ]; then
    mkdir $2
fi
cd $2

echo "downloading logs for $2"
curl -O $1/ws/work/logs/*zip*/logs.zip
echo "downloading consoleText for $2"
curl -O $1/lastCompletedBuild/consoleText

unzip -o logs.zip
echo "processing complete for $2"
