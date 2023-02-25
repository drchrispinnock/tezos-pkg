#!/bin/sh

# Stop a node, vacuum it and start it again
# Designed to work with the Octez Packages - run as root
# Chris Pinnock 2022
# MIT license

# Defaults - override in the configuration file
#
user=`whoami`
group=`groups | awk -F' ' '{print $1}'`
configstore="$HOME/_configs"
network=mainnet
nodedir="$HOME/.tezos-node"

[ -f /etc/octez/node.conf ] && . /etc/octez/node.conf

snapfile=""
snapshot=""
cliurl=""

# exit function
#
leave() {
	_code="$1"
	_msg="$2"
	echo "$_msg" >&2
	exit $_code
}

[ -z "$1" ] && leave 1 "Usage: $0 http(s)://path_to_snapshot"
cliurl=$1

[ ! -d "$nodedir" ] && leave 4 "Cannot find $nodedir"

echo "===> Setting up for node refresh from $cliurl"

snapfile="tezos-snapshot"
snapshot="$cliurl -O $snapfile"

echo "===> Fetching snapshot $snapfile"

if [ -f "$snapfile" ]; then
	echo "Already present $snapfile"
else
	wget -q $snapshot
	[ "$?" != "0" ] && leave 6 "Failed to get snapshot - fetch $snapfile manually"
fi

echo "===> Stopping baker"
systemctl stop octez-baker
sleep 10
echo "===> Stopping node"
systemctl stop octez-node
sleep 10

echo "===> Preserving current node directory"
[ -d "${nodedir}.1" ] && mv "${nodedir}.1" "${nodedir}.d"
mv "${nodedir}" "${nodedir}.1"
[ "$?" != "0" ] && leave 7 "Cannot preserve $nodedir"

mkdir -p $configstore
cp -p "${nodedir}.1/config.json" $configstore
cp -p "${nodedir}.1/peers.json" $configstore
cp -p "${nodedir}.1/identity.json" $configstore

mkdir -p ${nodedir}
chown $user:$group ${nodedir}
cp -p "${configstore}/config.json" $nodedir

echo "===> Importing snapshot"
su $user -c "/usr/bin/octez-node snapshot import "$snapfile" --data-dir ${nodedir} --network $network"
[ "$?" != "0" ] && leave 8 "Import failed"

echo "===> Restoring configuration"
cp -p "${configstore}/config.json" $nodedir
cp -p "${configstore}/peers.json" $nodedir
cp -p "${configstore}/identity.json" $nodedir

echo "===> Restarting node"
systemctl start octez-node
sleep 10
while [ 1 = 1 ]; do
        /usr/bin/octez-client bootstrapped
        [ "$?" = "0" ] && break;
        echo "===> Sleeping for node to come up"
        sleep 30
done
systemctl start octez-baker

echo "===> Cleaning up"
rm -rf "${nodedir}.d"
echo "If you are happy, you can remove"
echo "   ${nodedir}.1"
echo "   ${snapfile}"
