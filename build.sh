#!/bin/sh

NAME=shaes-minio

set -e

rm -f Dockerfile;
building=false;
if [ "$1" = "omz" ]; then
    cp ./Dockerfiles/omz.Dockerfile Dockerfile;
    building=true;
elif [ "$1" = "zi" ]; then
    cp ./Dockerfiles/zi.Dockerfile Dockerfile;
    building=true;
elif [ "$1" = "lean" ]; then
    cp ./Dockerfiles/lean.Dockerfile Dockerfile;
    building=true;
elif [ "$1" = "run" ]; then
    docker run -p 0.0.0.0:9000:9000 -p 0.0.0.0:9090:9090 $NAME;
else
    echo "Usage: $0 zi|omz"
fi

if [ "$building" = "true" ]; then
    docker build -t $NAME .;
    building=false;
fi

