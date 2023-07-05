#!/bin/bash

install_jq() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Attempting to install..."

        # Determine package manager
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y jq
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu jq
        elif command -v apk &> /dev/null; then
            sudo apk add jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y jq
        elif command -v zypper &> /dev/null; then
            sudo zypper install -y jq
        else
            echo "Could not determine package manager. Please install jq manually."
            exit 1
        fi
    fi
}

populate_arrays_from_json() {
    local -n json_file=$1
    local -n names=$2
    local -n ports=$3
    local -n roots=$4

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Please install jq and try again."
        exit 1
    fi

    # Parse JSON and populate arrays
    local length=$(jq '. | length' "$json_file")
    for (( i=0; i<$length; i++ )); do
        names[i]=$(jq -r ".[$i].name" "$json_file")
        ports[i]=$(jq -r ".[$i].port" "$json_file")
        servers[i]=$(jq -r ".[$i].root" "$json_file")
    done
}

generate_nginx_config() {
    local -n names=$1
    local -n ports=$2
    local -n roots=$3
    local -n loc=$4

    # Check if the number of names, ports, and servers are the same
    if [ ${#names[@]} -ne ${#ports[@]} ] || [ ${#names[@]} -ne ${#roots[@]} ]; then
        echo "The number of names, ports, and servers must be the same."
        echo "${#names[@]} ${#ports[@]} ${#roots[@]}"
        exit 1
    fi
    echo "events {"
    echo "    worker_connections  4096;  ## Default: 1024"
    echo "}"
    echo ""
    echo "http {"

    if [ "$loc" = true ]; then
            echo "    server {"
            echo "        server_name 0.0.0.0;"
            echo "        listen 80;"
            echo "        listen [::]:80;"
            for index in ${!names[@]}; do
              local name=${names[index]}
              local port=${ports[index]}
              local root=${root[index]}

              if [ "$root" == "" ]; then
                root="/"
              fi

              if [ "$name" == "" ]; then
                name="0.0.0.0"
              fi

              echo "        location = \"/$name\" {"
              
              echo "            proxy_pass http://0.0.0.0:$port/;"
              echo "            proxy_set_header Host \$host;"
              echo "        }"
              echo ""
            done
            echo "    }"
    else
        # Generate NGINX upstream ports and routes
        for index in ${!names[@]}; do
            local name=${names[index]}
            local port=${ports[index]}
            local root=${root[index]}

            if [ "$root" == "" ]; then
              root="/"
            fi

            if [ "$name" == "" ]; then
              name="0.0.0.0"
            fi

            echo "    server {"
            echo "        server_name $name www.$name;"
            echo "        listen $port;"
            echo "        root $root;"
            echo "    }"
            echo ""
        done
    fi
    echo "}"
    
}

# Initialize variables
from_file=""
ports=""
names=""
roots=""
location=false
outf="nginx.conf"

# Parse arguments
while (( "$#" )); do
  case "$1" in
    --from-file|-f)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        from_file=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --port|-p)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        ports=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --out|-o)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        outf="$2.$outf"
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --names|-n)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        names=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --roots|-r)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        roots=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --loc|-l)
      location=true
      shift
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Set positional arguments in their proper place
eval set -- "$PARAMS"

# Check that either from-file is present or the other three arguments are, but not all four
if [[ -n "$from_file" && (-n "$ports" || -n "$roots" || -n "$names") ]]; then
    echo "Error: Either --from-file should be provided or --port, --names, and --root should be provided, but not all four."
    exit 1
fi

if [[ -z "$from_file" ]] && [[ "$from_file" =~ *.json ]]; then
    # Declare arrays
    declare -a names
    declare -a ports
    declare -a roots

    populate_arrays_from_json $from_file names ports servers
fi

if [[ -z "$ports" && -z "$roots" && -z "$names" ]]; then
    echo "Error: Either --from-file should be provided or at least one of --port, --names, and --root should be provided."
    exit 1
fi

IFS=',' read -ra portArray <<< "${ports:-}"
IFS=',' read -ra nameArray <<< "${names:-}"
IFS=',' read -ra rootArray <<< "${roots:-}"

case 1 in
    $(( ${#portArray[@]} > 0 )))
        len=${#portArray[@]}
        echo "ports is nonempty. Length: $len"
        ;;
    $(( ${#rootArray[@]} > 0 )))
        len=${#rootArray[@]}
        echo "roots is nonempty. Length: $len"
        ;;
    $(( ${#nameArray[@]} > 0 )))
        len=${#nameArray[@]}
        echo "names is nonempty. Length: $len"
        ;;
    *)
        echo "All arrays are empty."
        exit 1
        ;;
esac



if [[ !$roots ]]; then
    # Initialize an empty array
    rootArray=()

    # Fill the array with "/"
    for (( i=0; i<$len; i++ )); do
        rootArray+=("/")
    done
else
  IFS=',' read -ra rootArray <<< "$roots"
fi

if [[ -z "$names" ]]; then
    nameArray=()
    # Fill the array with "/"
    for (( i=0; i<$len; i++ )); do
        nameArray+=("0.0.0.0")
    done
fi

if [[ -z "$ports" ]]; then
    portArray=()
    # Fill the array with "/"
    for (( i=0; i<$len; i++ )); do
        nameArray+=("0.0.0.0")
    done
fi

generate_nginx_config nameArray portArray rootArray location >  $outf
