#!/bin/bash

# Script to fetch Azure configuration and update .env file
# Run this script to automatically populate your .env file with Azure values

set -e

echo "================================================"
echo "Azure Configuration Fetcher"
echo "================================================"
echo ""

# Define resource names based on your Azure resources
AI_RESOURCE_NAME="aifoundry-voicelab-3ogp2nvam3xzm"
AI_RESOURCE_GROUP="rg-dev"
SPEECH_RESOURCE_NAME="speech-voicelab-3ogp2nvam3xzm"
SPEECH_RESOURCE_GROUP="rg-dev"
OPENAI_RESOURCE_NAME="admin-m9ix20yx-eastus2"
OPENAI_RESOURCE_GROUP="rg-multiagent-azureopenai"

echo "Fetching Azure configuration values..."
echo ""

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "✓ Subscription ID: $SUBSCRIPTION_ID"

# Get AI Services info
AI_REGION=$(az cognitiveservices account show --name "$AI_RESOURCE_NAME" --resource-group "$AI_RESOURCE_GROUP" --query "location" -o tsv)
AI_ENDPOINT=$(az cognitiveservices account show --name "$AI_RESOURCE_NAME" --resource-group "$AI_RESOURCE_GROUP" --query "properties.endpoint" -o tsv)
echo "✓ AI Resource: $AI_RESOURCE_NAME (Region: $AI_REGION)"

# Get OpenAI info
OPENAI_ENDPOINT=$(az cognitiveservices account show --name "$OPENAI_RESOURCE_NAME" --resource-group "$OPENAI_RESOURCE_GROUP" --query "properties.endpoint" -o tsv)
OPENAI_KEY=$(az cognitiveservices account keys list --name "$OPENAI_RESOURCE_NAME" --resource-group "$OPENAI_RESOURCE_GROUP" --query "key1" -o tsv)
echo "✓ OpenAI Endpoint: $OPENAI_ENDPOINT"

# Get Speech Services info
SPEECH_REGION=$(az cognitiveservices account show --name "$SPEECH_RESOURCE_NAME" --resource-group "$SPEECH_RESOURCE_GROUP" --query "location" -o tsv)
SPEECH_KEY=$(az cognitiveservices account keys list --name "$SPEECH_RESOURCE_NAME" --resource-group "$SPEECH_RESOURCE_GROUP" --query "key1" -o tsv)
echo "✓ Speech Key retrieved (Region: $SPEECH_REGION)"

# Get OpenAI deployments
echo ""
echo "Fetching OpenAI model deployments..."
DEPLOYMENTS=$(az cognitiveservices account deployment list --name "$OPENAI_RESOURCE_NAME" --resource-group "$OPENAI_RESOURCE_GROUP" --query "[].name" -o tsv)
echo "Available deployments:"
echo "$DEPLOYMENTS"
echo ""

# Select first deployment as default (or you can manually specify)
MODEL_DEPLOYMENT_NAME=$(echo "$DEPLOYMENTS" | head -n 1)
if [ -z "$MODEL_DEPLOYMENT_NAME" ]; then
    MODEL_DEPLOYMENT_NAME="gpt-4o"
    echo "⚠ No deployments found. Using default: $MODEL_DEPLOYMENT_NAME"
else
    echo "✓ Using deployment: $MODEL_DEPLOYMENT_NAME"
fi

echo ""
echo "================================================"
echo "Creating backup of current .env file..."
echo "================================================"
cp .env .env.backup
echo "✓ Backup created: .env.backup"

echo ""
echo "================================================"
echo "Updating .env file..."
echo "================================================"

# Create updated .env file
cat > .env << EOF
AZURE_AI_RESOURCE_NAME=$AI_RESOURCE_NAME
AZURE_AI_REGION=$AI_REGION
AZURE_AI_PROJECT_NAME=$AI_RESOURCE_NAME
PROJECT_ENDPOINT=$AI_ENDPOINT
USE_AZURE_AI_AGENTS=false # set to true to enable Azure AI Agents
AGENT_ID=__YOUR_AGENT_ID__ # required if USE_AZURE_AI_AGENTS is true
AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$OPENAI_KEY
MODEL_DEPLOYMENT_NAME=$MODEL_DEPLOYMENT_NAME
SUBSCRIPTION_ID=$SUBSCRIPTION_ID
RESOURCE_GROUP_NAME=$AI_RESOURCE_GROUP
AZURE_SPEECH_KEY=$SPEECH_KEY
AZURE_SPEECH_REGION=$SPEECH_REGION
AZURE_SPEECH_LANGUAGE=en-US
AZURE_INPUT_TRANSCRIPTION_MODEL=azure-speech
AZURE_INPUT_TRANSCRIPTION_LANGUAGE=en-US
AZURE_INPUT_NOISE_REDUCTION_TYPE=azure_deep_noise_suppression
AZURE_VOICE_NAME=en-US-Ava:DragonHDLatestNeural
AZURE_VOICE_TYPE=azure-standard
AZURE_AVATAR_CHARACTER=lisa
AZURE_AVATAR_STYLE=casual-sitting
EOF

echo "✓ .env file updated successfully!"
echo ""
echo "================================================"
echo "Configuration Summary"
echo "================================================"
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Resource Group: $AI_RESOURCE_GROUP"
echo "AI Resource: $AI_RESOURCE_NAME"
echo "AI Region: $AI_REGION"
echo "OpenAI Endpoint: $OPENAI_ENDPOINT"
echo "Speech Region: $SPEECH_REGION"
echo "Model Deployment: $MODEL_DEPLOYMENT_NAME"
echo ""
echo "================================================"
echo "Next Steps"
echo "================================================"
echo "1. Review the updated .env file"
echo "2. If using Azure AI Agents, update AGENT_ID manually"
echo "3. Verify MODEL_DEPLOYMENT_NAME matches your OpenAI deployment"
echo "4. Run your application!"
echo ""
echo "✓ Done!"
