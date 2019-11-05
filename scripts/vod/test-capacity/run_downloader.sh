#!/bin/bash

home=`dirname $(readlink -e $0)`

usage="$(basename '$0') -s|--source -f|--file [-h] -- download data from bitflow tcp or http endpoint and save as file 

where:
    -s|--source  remote bitflow tcp source to download from
    -f|--file    path to file where downloaded sample data should be saved
    -h           show this help message"

SOURCE=""
FILE_PATH=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -s|--source)
        SOURCE="$2"
        shift # past argument
        shift # past value
        ;;
        -f|--file)
        FILE_PATH="$2"
        shift 
        shift 
        ;;
        -h)
        echo $usage
        exit
        *)    # unknown option
        echo "Bad parametrization"
        echo $usage
        exit -1
        ;;
    esac
done

if [ -z "$SOURCE" ]; then
    echo "Source parameter is requires."
    echo "$usage"
fi

if [ -z "$FILE_PATH" ]; then
    echo "File parameter is requires."
    echo "$usage"
fi

DIR_PATH=$(dirname $FILE_PATH)
if [ ! -d "$DIR_PATH" ]; then
  mkdir -p $DIR_PATH
fi

bitflow-pipeline "$SOURCE -> $FILE_PATH"


