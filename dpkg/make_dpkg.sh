#!/bin/sh

# Debian/Ubuntu package build for Octez
#
# (c) Chris Pinnock 2022, Supplied under a MIT license. 

# Packages
#
# A better way to do this would be to build the package from source
# but given the various hurdles of Rust and OPAM during the build
# we construct packages afterwards.
#
# Place files in the dpkg directory to declare a package
#
# baker-control.in	- a template for the Debian control file
# baker-binaries	- the list of binaries to include
# baker.conf		- an example configuration file (optional)
# baker.initd		- System V init script (optional)
#
# Edit scripts/dpkg/maintainer for your maintenance e-mail and
# scripts/dpkg/pkgname to change the base name from octez to something else
#

# Setup
#
staging_root=_dpkgstage
myhome=scripts/dpkg

# Checking prerequisites
#
which dpkg-deb >/dev/null 2>&1
if [ "$?" != "0" ]; then
	echo "Needs to run on a system with dpkg-deb in path" >&2
	exit 2
fi

# Maintainer
#
dpkg_maintainer="Root <root@localhost>"
if [ -f "$myhome/maintainer" ]; then
	dpkg_maintainer=$(cat "$myhome/maintainer")
else
	echo "WARNING: maintainer file does not exist"
	echo "Using $dpkg_maintainer"
	sleep 5
fi

# Package name
#
dpkg_base="octez"
dpkg_real="octez"
[ -f "$myhome/pkgname" ] && dpkg_base=$(cat "$myhome/pkgname")

# Revision (set DPKG_REV in the environment)
#
[ -z "$DPKG_REV" ] && DPKG_REV=1
dpkg_rev="$DPKG_REV"

# Get Octez version from the build
#
dpkg_vers=`dune exec tezos-version 2>/dev/null | sed -e 's/\~//' -e 's/\+//'`
if [ $? != 0 ]; then
	echo "Cannot get version. Try eval `opam env`?"
	exit 1
fi

# Get the local architecture
#
eval `dpkg-architecture `
dpkg_arch=$DEB_BUILD_ARCH

# For each control file in the directory, build a package
#
for control_file in `ls $myhome/*control.in`; do
	pg=$(basename $control_file | sed -e 's/-control.in$//g')
	echo "===> Building package $pg v$dpkg_vers rev $dpkg_rev"

	# Derivative variables
	#
	dpkg_name=${dpkg_base}-${pg}
	init_name=${dpkg_real}-${pg}
	dpkg_dir="${dpkg_name}_${dpkg_vers}-${dpkg_rev}_${dpkg_arch}"
	dpkg_fullname="${dpkg_dir}.deb"
	binaries=`cat scripts/dpkg/${pg}-binaries 2>/dev/null`
	zcashstuff=`cat scripts/dpkg/${pg}-zcash 2>/dev/null`

	if [ -f "$dpkg_fullname" ]; then
		echo "built already - skipping"
		continue
	fi

	# Populate the staging directory with control scripts
	# binaries and configuration as appropriate
	#
	staging_dir="$staging_root/$dpkg_dir"

	rm -rf "${staging_dir}"
	mkdir -p "${staging_dir}/DEBIAN"

	if [ ! -z "$binaries" ]; then	
		echo "=> Populating directory with binaries"
		mkdir -p "${staging_dir}/usr/bin"
		for bin in ${binaries}; do
			echo ${bin}
			cp ${bin} "${staging_dir}/usr/bin"
			chmod +x "${staging_dir}/usr/bin/$bin"
		done

		# Shared libraries
		#
		mkdir -p "${staging_dir}/debian"
		touch "${staging_dir}/debian/control"

		echo "=> Finding shared library dependencies"

		deps=$(cd ${staging_dir} && dpkg-shlibdeps -O usr/bin/* | sed -e 's/^shlibs://g' -e 's/^Depends=//g') 
		rm "${staging_dir}/debian/control"
		rmdir "${staging_dir}/debian"
	
	fi

	# Edit the control file to contain real values
	#
	sed -e "s/@ARCH@/${dpkg_arch}/g" -e "s/@VERSION@/$dpkg_vers/g" \
		-e "s/@MAINT@/${dpkg_maintainer}/g" \
		-e "s/@PKG@/${dpkg_name}/g" \
		-e "s/@DPKG@/${dpkg_base}/g" \
		-e "s/@DEPENDS@/${deps}/g" < $control_file \
		> "${staging_dir}/DEBIAN/control"

	# Install hook scripts (not used initially)
	#
	for scr in postin preinst postrm prerm; do
		if [ -f "${myhome}/${pg}.$scr" ]; then
			cp "${myhome}/${pg}.$scr" ${staging_dir}/DEBIAN/$scr
			chmod +x ${staging_dir}/DEBIAN/$scr
		fi
	done

	# init.d scripts
	#
	if [ -f "${myhome}/${pg}.initd" ]; then
		mkdir -p ${staging_dir}/etc/init.d
		cp ${myhome}/${pg}.initd ${staging_dir}/etc/init.d/${init_name}
		chmod +x ${staging_dir}/etc/init.d/${init_name}
	fi

	# Configuration files
	#
	if [ -f "${myhome}/${pg}.conf" ]; then
		mkdir -p ${staging_dir}/etc/octez
		cp ${myhome}/${pg}.conf ${staging_dir}/etc/octez
		echo "/etc/octez/${pg}.conf" > ${staging_dir}/DEBIAN/conffiles
	fi


	# Zcash parameters must ship with the node
	#
	if [ ! -z "${zcashstuff}" ]; then
		mkdir -p "${staging_dir}/usr/share/zcash-params"
		for shr in ${zcashstuff}; do
			cp _opam/share/zcash-params/${shr} "${staging_dir}/usr/share/zcash-params"
		done
	fi

	# Build the package
	#
	echo "=> Constructing package ${dpkg_fullname}"
	dpkg-deb -v --build --root-owner-group ${staging_dir}
	mv ${staging_root}/${dpkg_fullname} .
done

# Output rev for next time
#
echo "$dpkg_rev" > "${staging_root}/.rev"

