#!/bin/bash

echo "🔧 Starting Anvil with deterministic addresses..."

# Kill any existing anvil process
pkill -f anvil

# Start anvil with a fixed seed for deterministic addresses
anvil --host 0.0.0.0 --port 8545 --chain-id 31337 --accounts 10 --balance 10000