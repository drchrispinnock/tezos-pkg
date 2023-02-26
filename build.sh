#!/bin/sh

# This is clunky and not designed for production use
# The future intention is that 'dpkg' will go into tezos/scripts
# and be called from the Makefile.
#

# Download Tezos sources, build them and make packages
#
mastersite="https://gitlab.com/tezos/tezos.git"
whereami=`pwd`

[ -z "$1" ] && echo "Usage: $0 tag/branch [revision]" && exit 1
tag="$1"

DPKG_REV=1
[ ! -z "$2"] && DPKG_REV=$2
export DPKG_REV

#directory=`mktemp -d tezos_build_$tag_XXXXXXX`
directory="tezos_build_$tag"
mkdir -p ${directory}
cd ${directory}

sudo apt-get install -y rsync git m4 build-essential patch unzip wget opam jq bc

# Rust
#
echo "===> Building rust"
wget https://sh.rustup.rs/rustup-init.sh
chmod +x rustup-init.sh
./rustup-init.sh --profile minimal --default-toolchain 1.60.0 -y
. $HOME/.cargo/env

# Source code
#
if [ ! -d tezos ]; then
	git clone ${mastersite}
	[ "$?" != "0" ] && echo "Git failed" && exit 1
	cd tezos
else
	cd tezos
	git checkout master
	[ "$?" != "0" ] && echo "Git update failed" && exit 1
	git pull
	[ "$?" != "0" ] && echo "Git pull failed" && exit 1
fi

git checkout $tag
[ "$?" != "0" ] && echo "Git checkout failed" && exit 1

# Link my stuff into the source directory
#
cd scripts
ln -sf $whereami/dpkg .
ln -sf $whereami/rpm .
sleep 5
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
if [ -x /usr/bin/rpm ]; then
	# Redhat style package management on this system
	#
	sh scripts/rpm/make_rpm.sh
	mv *rpm ../..
fi

if [ -x /usr/bin/dpkg ]; then
	# Debian style package management on this system
	#
	sh scripts/dpkg/make_dpkg.sh
	mv *deb ../..
fi

cd $whereami
echo
echo
pwd
ls -l *deb *rpm

