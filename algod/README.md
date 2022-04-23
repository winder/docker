# Algod Container

Container to run an algorand node.

Image is built using two stages. In the first stage, binaries are generated with the `install.sh` script. Resulting artifacts are copied into the second stage for final packaging.

## Build Arguments

Binaries are generated using the following build arguments.
| Argument | Description |
| -------- | ----------- |
| CHANNEL  | Download latest binaries for a given release channel. |
| URL      | Git URL to download sources from. |
| BRANCH   | Git branch to checkout. |
| SHA      | Git commit hash to checkout. |

# Image Usage

There are a number of special files and environment variables used to control which network to connect to, and how to initalize. If a persistent data directory is desired, a volume can be attached.

## Default Configuration

By default the following config.json overrides are applied:

| Setting | Value |
| ------- | ----- |
| GossipFanout | 1 |
| EndpointAddress | 0.0.0.0:4190 |
| IncomingConnectionsLimit | 0 |
| Archival | false |
| IsIndexerActive | false |
| EnavleDeveloperAPI | true |

## Environment Variables

When starting the image, environment variables are used to configure what
mode algod will run in.

| Variable | Description |
| -------- | ----------- |
| NETWORK  | Leave blank to start a private network, otherwise specify one of (mainnet, testnet, betanet, devnet) |
| FAST_CATCHUP | When starting a production network, setting this will attempt to start a fast catchup. |
| DEV_MODE     | When running a private network, setting this will enable dev mode. |
| TOKEN        | Specify a REST API token to use. |

## Special files

Configuration can be modified by specifying certian files. These can be changed each time you start the container. This allows you to do things like toggle EnableDeveloperAPI temporarily.

| File | Description |
| ---- | ----------- |
| /etc/config.json | Override default configurations by providing your own file. |
| /etc/algod.token | Override default randomized REST API token. |
| /etc/algod.admin.token | Override default randomized REST API admin token. |

## Data directory

The data directory is mounted at `/node/data`. Mounting a volume at that location will allow you to shutdown and resume the node.

When running a private network, a `private_network` directory is stored at that location. By default the installation at `/node/data/private_network/Node` is exposed on port 4190.

TODO: After #3911 is widely available, we can play some games with the data directory so that ALGORAND_DATA points to the primary data directory for public and private networks.
