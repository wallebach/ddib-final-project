#!/bin/bash

set -e

echo "🚀 Starting deployment to Anvil local chain..."

if ! curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' > /dev/null 2>&1; then
  echo "Anvil is not running. Please start it first with: anvil"
  echo "Run 'anvil' in another terminal to start the local blockchain"
  exit 1
fi

echo "Anvil is running on http://localhost:8545"

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Loaded environment variables from .env file"
    
    if [[ ! "$PRIVATE_KEY" =~ ^0x ]]; then
        export PRIVATE_KEY="0x$PRIVATE_KEY"
    fi
    
    echo "Using deployer private key: ${PRIVATE_KEY:0:6}...${PRIVATE_KEY: -4}"
else
    echo ".env file not found. Please create one with PRIVATE_KEY variable"
    exit 1
fi

echo "Deploying contracts..."
DEPLOYMENT_OUTPUT=$(forge script script/DeployAll.s.sol --rpc-url http://localhost:8545 --broadcast --legacy 2>&1)

echo "Full deployment output:"
echo "$DEPLOYMENT_OUTPUT"

STR_TOKEN_ADDRESS=$(echo "$DEPLOYMENT_OUTPUT" | grep "STRToken:" | tail -1 | awk '{print $2}')
GRN_TOKEN_ADDRESS=$(echo "$DEPLOYMENT_OUTPUT" | grep "GRNToken:" | tail -1 | awk '{print $2}')
SUBSCRIPTION_PLATFORM_ADDRESS=$(echo "$DEPLOYMENT_OUTPUT" | grep "SubscriptionPlatform:" | tail -1 | awk '{print $2}')
PLATFORM_GOVERNANCE_ADDRESS=$(echo "$DEPLOYMENT_OUTPUT" | grep "PlatformGovernance:" | tail -1 | awk '{print $2}')

echo ""
echo "Extracted contract addresses:"
echo "  STRToken: $STR_TOKEN_ADDRESS"
echo "  GRNToken: $GRN_TOKEN_ADDRESS"
echo "  SubscriptionPlatform: $SUBSCRIPTION_PLATFORM_ADDRESS"
echo "  PlatformGovernance: $PLATFORM_GOVERNANCE_ADDRESS"

if [[ ! "$STR_TOKEN_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "Invalid STRToken address extracted: $STR_TOKEN_ADDRESS"
    exit 1
fi

if [[ ! "$GRN_TOKEN_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "Invalid GRNToken address extracted: $GRN_TOKEN_ADDRESS"
    exit 1
fi

if [[ ! "$SUBSCRIPTION_PLATFORM_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "Invalid SubscriptionPlatform address extracted: $SUBSCRIPTION_PLATFORM_ADDRESS"
    exit 1
fi

if [[ ! "$PLATFORM_GOVERNANCE_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "Invalid PlatformGovernance address extracted: $PLATFORM_GOVERNANCE_ADDRESS"
    exit 1
fi

echo ""
echo "🔧 Saving contract addresses to file..."

cat > contracts.json << EOF
{
  "STRToken": "$STR_TOKEN_ADDRESS",
  "GRNToken": "$GRN_TOKEN_ADDRESS", 
  "SubscriptionPlatform": "$SUBSCRIPTION_PLATFORM_ADDRESS",
  "PlatformGovernance": "$PLATFORM_GOVERNANCE_ADDRESS",
  "deployerAddress": "$(cast wallet address --private-key $PRIVATE_KEY 2>/dev/null || echo 'Unable to derive address')",
  "network": "localhost",
  "chainId": 31337
}
EOF

echo "Contract addresses saved to contracts.json"

echo ""
echo "Deployment completed successfully!"
echo ""
echo "Contract Addresses for Frontend Integration:"
echo "{"
echo "  \"STRToken\": \"$STR_TOKEN_ADDRESS\","
echo "  \"GRNToken\": \"$GRN_TOKEN_ADDRESS\","
echo "  \"SubscriptionPlatform\": \"$SUBSCRIPTION_PLATFORM_ADDRESS\","
echo "  \"PlatformGovernance\": \"$PLATFORM_GOVERNANCE_ADDRESS\""
echo "}"
echo ""
echo "Contract Details:"
echo "Contract Name: STRToken"
echo "Address: $STR_TOKEN_ADDRESS"
echo ""
echo "Contract Name: GRNToken"
echo "Address: $GRN_TOKEN_ADDRESS"
echo ""
echo "Contract Name: SubscriptionPlatform"
echo "Address: $SUBSCRIPTION_PLATFORM_ADDRESS"
echo ""
echo "Contract Name: PlatformGovernance"
echo "Address: $PLATFORM_GOVERNANCE_ADDRESS"
echo ""
echo "Deployer Address: $(cast wallet address --private-key $PRIVATE_KEY 2>/dev/null || echo 'Unable to derive address')"
echo ""
echo "Tip: You can run './deploy.sh' again to redeploy if needed"