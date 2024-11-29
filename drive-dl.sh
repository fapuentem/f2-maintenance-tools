#!/bin/bash

url=$1
FILENAME=$2
FILEID=$(echo $url | grep -oP 'file/d/\K[^/]+')
echo $FILEID

wget --no-check-certificate "https://docs.google.com/uc?export=download&id=$FILEID" -O $FILENAME

unzip $FILENAME
