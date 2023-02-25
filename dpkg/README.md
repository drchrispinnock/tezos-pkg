
How to use these packages.

## Installation

Install the packages with dpkg. For example:

```
dpkg -i octez-client_15.1-1_amd64.deb
```

Note that the baking package depends on the node package, which depends on
the client package.

## Setting up a node

Check /etc/octez/node.conf. By default we have assumed that you will
run the software with user tezos and group tezos in a directory called
/var/tezos/node. 

Similarly we will log into /var/log/tezos.

/var/tezos/node will need to be a large partition capable of storing the 
blockchain. For a full node you may need 100-150GB. For an archive node
you will need at least 1TB (growth is approx 1GB a week).

Setup the user and group and make the node directory (if needed):

```
addgroup tezos
adduser --group tezos tezos
mkdir -p /var/tezos/node
chown -R tezos:tezos /var/tezos/node
```

(Note that the wallet (e.g. for baking) will reside in the tezos home
directory - this should be backed up regularly.)

Assume the role of tezos and initialise the node. These are sensible defaults
for a rolling node on mainnet with a local RPC server. Your requirements
may be different.

```
sudo su - tezos
octez-node config init --data-dir /var/tezos \
			--network mainnet \
			--history-mode=rolling \
			--net-addr="[::]:9732" \
			--rpc-addr="127.0.0.1:8732"
```

If you were to start the node now, it would start to download the blockchain
from the very first block. On a test network this will be quick, but on
mainnet it will be very slow. To give yourself a headstart, fetch a snapshot 
and import it, e.g.:

```
sudo su - tezos
wget -O /tmp/snap https://mainnet.xtz-shots.io/rolling
octez-node snapshot import /tmp/snap --data-dir /var/tezos/node
rm /tmp/snap
```

As root, start the node

```
systemctl enable octez-node.service
systemctl start octez-node.service
```

Examine the logs

```
tail -f /var/log/tezos/node.log
```

## Baking

You need to have a synced node and a wallet with at least 6000tz.

Assume the role of tezos & setup your wallet.  At this point, you may want to connect a ledger. See LEDGER.md for more details
on this. To setup a simple wallet on the machine (not recommended on mainnet),
do the following:

```
sudo su - tezos
octez-client gen keys alice
octez-client list known addresses
```

Go and get funds for alice (e.g. purchase from an exchange on mainnet or 
a faucet on a test network (see https://teztnets.xyz )).

Self-delegate

```
octez-client register key alice as delegate
```

4. Edit /etc/octez/baker.conf and make sure that ```baking_key``` is set (e.g.
to alice) and that you choose an appropriate value for ```lq_vote```. It
is mandatory to vote on liquidity baking.

5. Start the bakers

```
systemctl enable octez-baker.service
systemctl start octez-baker.service
```

Note that if the node is not synced, the baker start script will wait for it
to sync and as a result, starting the baker may time out.

## VDF packages

Work in progress

## SCORU packages

Work in progress
