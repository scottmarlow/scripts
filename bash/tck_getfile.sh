#!/bin/sh

if [ ! -d $2 ]; then
    mkdir $2
fi
cd $2

echo "downloading file $2"
curl -O $1/lastCompletedBuild/consoleText

echo "processing complete for $2"
