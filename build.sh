#!/bin/sh

# This is clunky and not designed for production use
# The future intention is that 'dpkg' will go into tezos/scripts
# and be called from the Makefile.
#

# Download Tezos sources, build them and make packages
#
mastersite="https://gitlab.com/tezos/tezos.git"

whereami=`basename $0`

[ -z "$1" ] && echo "Usage: $0 tag/branch [revision]" && exit 1
tag="$1"

DPKG_REV=1
[ ! -z "$2"] && DPKG_REV=$2
export DPKG_REV

directory="tezos_build_$tag"
mkdir -p ${directory}
cd ${directory}

sudo apt-get install -y rsync git m4 build-essential patch unzip wget opam jq bc

# Rust
#
wget https://sh.rustup.rs/rustup-init.sh
chmod +x rustup-init.sh
./rustup-init.sh --profile minimal --default-toolchain 1.60.0 -y
. $HOME/.cargo/env

# Source code
#
git clone ${mastersite}
[ "$?" != "0" ] && echo "Git failed" && exit 1
cd tezos
git checkout $tag
[ "$?" != "0" ] && echo "Git checkout failed" && exit 1

# Link my stuff into the source directory
#
cd scripts
ln -s $whereami/dpkg .
cd ..

# Opam
#
opam init --bare --yes
[ "$?" != "0" ] && echo "Opam init failed" && exit 1


# Build process
#
make build-deps
[ "$?" != "0" ] && echo "Build-deps failed" && exit 1
eval $(opam env)
make
[ "$?" != "0" ] && echo "Build failed" && exit 1

# Make packages
#
sh scripts/dpkg/make_dpkg.sh
echo
echo
pwd
ls -l *deb

