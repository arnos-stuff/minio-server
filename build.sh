#!/bin/sh

set -e

NAME=arnovdev/nginx-default

rm -f Dockerfile;
building=false;
push=false;
action="build";
help_msg="Usage: $0 [tag|push|build] [[Dockerfile] [name] | [name] [tag-prec] [tag]] [--push]\
\n\
\tCOMMAND = tag : change the docker tag of the current docker image with a new one\
\n\
\t\ttag-prec: tag of the existing image\
\n\
\t\ttag: tag of the new image\
\n\
\tCOMMAND = push : push the current docker image to docker hub\
\n\
\tCOMMAND = build : build the docker image\
\n\
\t\tdockerfile: the name of the dockerfile when building\
\n\
\t\tname: the name of the docker image\
\n\
\t--push: push the docker image to docker hub after processing\
\n\
\n\
Example: $0 tag zi --push\
\n\
Example: $0 build zi --push\
\n\
Example: $0 push zi\
"

build_msg="Usage: $0 build [Dockerfile] [name] [--push]\
\n\
COMMAND = build : build the docker image\
\n\
\t\tdockerfile: the name of the dockerfile when building\
\n\
\t\tname: the name of the docker image\
\n\
\t--push: push the docker image to docker hub after processing\
"

tag_msg="Usage: $0 tag [name] [tag-prec] [tag]\
\n\
COMMAND = tag : change the docker tag of the current docker image with a new one\
\n\
\tname: the name of the docker image\
\n\
\ttag: tag the current docker image with a new name\
\n\
\ttag-prec: tag of the existing image\
\n\
"


if [ "$1" = "--help" ]; then
    echo $help_msg
    exit 0
fi

if [ "$#" -eq 0 ]; then
    echo $help_msg
    exit 1
fi

if [ "$1" = "tag" ]; then
    action="tag";
    help_msg=$tag_msg;
    shift;

elif [ "$1" = "push" ]; then
    action="push";
    shift;

elif [ "$1" = "build" ]; then
    action="build";
    help_msg=$build_msg;
    shift;
fi


if [ "$action" != "push" ] && [ "$#" -eq 0 ]; then
    echo $help_msg
    exit 1
elif [ "$action" = "build" ] && [ "$#" -ge 1 ]; then
    if [ -f "./Dockerfiles/$1.Dockerfile" ]; then
        echo "🚀 Building docker image $1"
        cp ./Dockerfiles/$1.Dockerfile Dockerfile;
        if [ "$#" -ge 2 ]; then
            if [ "$2" != "--push" ];then
                NAME="$2";
            fi
            if [ "$2"  = "--push" ];then
                push=true;
            fi
            if [ "$2"  = "--push" ] && [ "$#" -ge 3 ]; then
                if [ "$3" != "--push" ];then
                    NAME="$3";
                fi
                if [ "$3"  = "--push" ];then
                    push=true;
                fi
            fi
        fi
        building=true;
    else
        echo $help_msg;
        exit 1
    fi
elif [ "$action" = "tag" ] && [ "$#" -ge 1 ]; then
    if [ "$#" -ge 1 ]; then
        docker tag $NAME:$1 $NAME:$2;
    fi
elif [ "$action" = "push" ]; then
    if [ "$#" -ge 1 ]; then
        docker push $NAME:$1;
    else
        docker push $NAME;
    fi
else
    echo $help_msg
    exit 1
fi

if [ "$action" = "build" ] && [ "$building" = "true" ]; then
    docker build -t $NAME .
fi