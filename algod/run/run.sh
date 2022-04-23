#!/usr/bin/env bash

set -ex

# Script to configure or resume a network. Based on environment settings the
# node will be setup with a private network or connect to a public network.
#
# Environment Parameters
#
# ALGORAND_DATA  Path to data directory.
# ALGOD_PORT     Address to expose algorand REST API.
# NETWORK        Blank (private network) or mainnet|betanet|testnet|devnet.
# FAST_CATCHUP   If set, attempt to start fast-catchup during initial config.
# DEV_MODE       If set, and in private network mode, enable dev mode.
# TOKEN          If set, overrides the REST API Token.

####################
# Helper functions #
####################

function catchup() {
  local FAST_CATCHUP_URL="https://algorand-catchpoints.s3.us-east-2.amazonaws.com/channel/CHANNEL/latest.catchpoint"
  local CATCHPOINT=$(curl -s ${FAST_CATCHUP_URL/CHANNEL/$NETWORK})
  if [[ "$(echo $CATCHPOINT | wc -l | tr -d ' ')" != "1" ]]; then
    echo "Problem starting fast catchup."
    exit 1
  fi

  sleep 5
  #goal node catchup "$CATCHPOINT"
  goal node catchup 20560000#EHT74WWSMRVUW5XMLFTG533G7CXKMXPG7EWUKX7OFZG3MBS6OGPA
}

function start_public_network() {
  cd "$ALGORAND_DATA"

  if [ $FAST_CATCHUP ]; then
    catchup&
  fi

  # on each start, check for a config file override.
  if [ -f "/etc/config.json" ]; then
    cp /etc/config.json config.json
  fi
  if [ -f "/etc/algod.token" ]; then
    cp /etc/algod.token algod.token
  fi
  if [ -f "/etc/algod.admin.token" ]; then
    cp /etc/algod.admin.token algod.admin.token
  fi

  # Make sure log file exists. We tail this so it outputs to stdout in docker
  # TODO: switch to -o when available
  [ -f "node.log" ] || touch "node.log"
  tail -F "node.log" &

  # Fork process so that it is pid 1 for the container
  exec algod 2> "algod-err.log" > "algod-out.log"
}

# Should be inside the data directory when calling this.
function configure_data_dir() {
  algocfg -d . set -p GossipFanout -v 1
  algocfg -d . set -p EndpointAddress -v "0.0.0.0:${ALGOD_PORT:-4190}"
  algocfg -d . set -p IncomingConnectionsLimit -v 0
  algocfg -d . set -p Archival -v false
  algocfg -d . set -p IsIndexerActive -v false
  algocfg -d . set -p EnableDeveloperAPI -v true

  if [ "$TOKEN" != "" ]; then
    echo "$TOKEN" > algod.token
  fi
}

function start_new_public_network() {
  cd /node
  if [ ! -d "run/genesis/$NETWORK" ]; then
    echo "No genesis file for '$NETWORK' is available."
    exit 1
  fi

  mkdir -p "$ALGORAND_DATA"
  mv dataTemplate/* "$ALGORAND_DATA"
  rm -rf dataTemplate

  cp "run/genesis/$NETWORK/genesis.json" "$ALGORAND_DATA/genesis.json"
  cd "$ALGORAND_DATA"

  mv config.json.example config.json
  configure_data_dir

  local ID
  case $NETWORK in
    mainnet) ID="<network>.algorand.network";;
    testnet) ID="<network>.algorand.network";;
    betanet) ID="<network>.algodev.network";;
    devnet)  ID="<network>.algodev.network";;
    *)       echo "Unknown network"; exit 1;;
  esac
  set -p DNSBootstrapID -v "$ID"

  start_public_network
}

function start_private_network() {
  goal network start -r "$ALGORAND_DATA/private_network"
  tail -f "$ALGORAND_DATA/private_network/Node/node.log"
}

function start_new_private_network() {
  local TEMPLATE="template.json"
  if [ "$DEV_MODE" ]; then
    TEMPLATE="devmode_template.json"
  fi
  goal network create -n dockernet -r "$ALGORAND_DATA/private_network" -t "run/$TEMPLATE"
  cd "$ALGORAND_DATA/private_network/Node"
  configure_data_dir
  start_private_network
}

##############
# Entrypoint #
##############

echo "Starting Algod Docker Container"
echo "   ALGORAND_DATA: $ALGORAND_DATA"
echo "   NETWORK:       $NETWORK"
echo "   ALGOD_PORT:    $ALGOD_PORT"
echo "   FAST_CATCHUP:  $FAST_CATCHUP"
echo "   DEV_MODE:      $DEV_MODE"
echo "   TOKEN:         $TOKEN"

# Check if data directory is initialized, start environment.
if [ -f "$ALGORAND_DATA/network.json" ]; then
  start_private_network
  exit 1
elif [ -f "$ALGORAND_DATA/genesis.json" ]; then
  start_public_network
  exit 1
fi

# Initialize and start network.
if [ "$NETWORK" == "" ]; then
  start_new_private_network
else
  start_new_public_network
fi
