# Initialize variables
from_file=""
ports=""
servers=""
roots=""
docker=""
ZSH=false
BREW=false
RUBY=false
NODE=false
NGINX=false

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
    --server|-s)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        servers=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --root|-r)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        roots=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --docker)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        docker=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --zsh)
      ZSH=true
      shift
      ;;
    --nginx)
      NGINX=true
      shift
      ;;
    --ruby)
      RUBY=true
      shift
      ;;
    --node)
      NODE=true
      shift
      ;;
    --brew)
      BREW=true
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

install_and_build_rust_packages() {
    # Check if curl, rustup, and cargo are installed
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing..."
        sudo apt-get install curl
    fi

    if ! command -v rustup &> /dev/null; then
        echo "rustup is not installed. Installing..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        source $HOME/.cargo/env
    fi

    if ! command -v cargo &> /dev/null; then
        echo "cargo is not installed. Please install cargo and try again."
        exit 1
    fi

    # Build packages
    for package in "$@"; do
        echo "Building package $package..."
        cargo install $package
    done
}

install_brew_packages() {
    # Check if brew is installed
    if ! command -v brew &> /dev/null; then
        echo "brew is not installed. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install packages
    for package in "$@"; do
        echo "Installing package $package..."
        brew install $package
    done
}

install_npm_packages() {
    # Check if node and npm are installed
    if ! command -v node &> /dev/null; then
        echo "node is not installed. Installing..."
        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if ! command -v npm &> /dev/null; then
        echo "npm is not installed. Please install npm and try again."
        exit 1
    fi

    # Install packages
    for package in "$@"; do
        echo "Installing package $package..."
        npm install -g $package
    done
}

install_gem_packages() {
    # Check if ruby and gem are installed
    if ! command -v ruby &> /dev/null; then
        echo "ruby is not installed. Installing..."
        sudo apt-get install ruby-full
    fi

    if ! command -v gem &> /dev/null; then
        echo "gem is not installed. Please install gem and try again."
        exit 1
    fi

    # Install packages
    for package in "$@"; do
        echo "Installing package $package..."
        gem install $package
    done
}

# Set positional arguments in their proper place
eval set -- "$PARAMS"

# Check that either from-file is present or the other three arguments are, but not all four
if [[ -n "$from_file" && (-n "$ports" || -n "$servers" || -n "$roots" || -n "$docker") ]]; then
    echo "Error: Either --from-file should be provided or --port, --server, --root, and --docker should be provided, but not all five."
    exit 1
fi