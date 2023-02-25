
# Setting up the ledger

## Prerequisites

Using Ledger Live, setup your key, install the Tezos Client app and the
Tezos Baking app. For the second app, you may need to enable developer mode.

## Connect the ledger on the machine

You will need to change the permissions on the relevant USB device otherwise
only root will have access to the ledger.

Add a file 20-hw1.rules in /etc/udev/rules.d/ containing for the Nano S
(assuming user tezos and group tezos).

```
# All ledger devices
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", GROUP="tezos", OWNER="tezos", MODE="0600"
# or specific: Nano S
#SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0001|1000|1001|1002|1003|1004|1005|1006|1007|1008|1009|100a|100b|100c|100d|100e|100f|1010|1011|1012|1013|1014|1015|1016|1017|1018|1019|101a|101b|101c|101d|101e|101f", GROUP="tezos", OWNER="tezos", MODE="0600"
```

cf. for more detail
https://www.xmodulo.com/change-usb-device-permission-linux.html

You must connect the ledger to the machine using the same port everytime.

## Setting up Octez to use the ledger

1. Run the Tezos Client App on the ledger. Import the key reference into the 
machine wallet. Here we use ledger_tezos as the name. 

```
sudo su - tezos
octez-client list connected ledgers
octez-client import secret key ledger_tezos \
	"ledger://kaleidoscopic-uguisu-gripping-nightingale/ed25519/0h/0h"
octez-client list known addresses
```

Respond on the ledger as necessary.

You must use the right path and cipher. Note the 0h/0h. Check the 
key hash you get is the expected one. If you have setup the key on Ledger
Live, it is usually the ed25519 key you need.

2. Switch to the Tezos Baking App on the ledger & register the key for baking:

```
octez-client setup ledger to bake for ledger_tezos
octez-client register key ledger_tezos as delegate
```

Respond on the ledger to each command.

## Normal operation

For baking, make sure that the ledger is running the Tezos Baking application.
This application is capable of supporting baking and endorsing operations.

When you want to make transfers or vote, switch the ledger to the Tezos
Client application before you run the commands on the baking machine.

(As a layer of protection, you could use separate ledgers for these functions.)


