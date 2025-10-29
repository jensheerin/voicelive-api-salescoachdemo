#!/bin/bash

# Script to fetch Azure configuration values for .env file

echo "Fetching Azure configuration values..."
echo ""

# Get subscription ID
echo "=== Subscription Info ==="
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
echo ""

# Set resource names based on the resources you have
AI_RESOURCE_NAME="aifoundry-voicelab-3ogp2nvam3xzm"
AI_RESOURCE_GROUP="rg-dev"
SPEECH_RESOURCE_NAME="speech-voicelab-3ogp2nvam3xzm"
SPEECH_RESOURCE_GROUP="rg-dev"
OPENAI_RESOURCE_NAME="admin-m9ix20yx-eastus2"
OPENAI_RESOURCE_GROUP="rg-multiagent-azureopenai"

# Get AI Services info
echo "=== AI Services Info ==="
echo "AZURE_AI_RESOURCE_NAME=$AI_RESOURCE_NAME"
echo "RESOURCE_GROUP_NAME=$AI_RESOURCE_GROUP"
AI_REGION=$(az cognitiveservices account show --name $AI_RESOURCE_NAME --resource-group $AI_RESOURCE_GROUP --query "location" -o tsv)
echo "AZURE_AI_REGION=$AI_REGION"
AI_ENDPOINT=$(az cognitiveservices account show --name $AI_RESOURCE_NAME --resource-group $AI_RESOURCE_GROUP --query "properties.endpoint" -o tsv)
echo "PROJECT_ENDPOINT=$AI_ENDPOINT"
AI_KEY=$(az cognitiveservices account keys list --name $AI_RESOURCE_NAME --resource-group $AI_RESOURCE_GROUP --query "key1" -o tsv)
echo "AI_KEY=$AI_KEY"
echo ""

# Get OpenAI info
echo "=== Azure OpenAI Info ==="
OPENAI_ENDPOINT=$(az cognitiveservices account show --name $OPENAI_RESOURCE_NAME --resource-group $OPENAI_RESOURCE_GROUP --query "properties.endpoint" -o tsv)
echo "AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT"
OPENAI_KEY=$(az cognitiveservices account keys list --name $OPENAI_RESOURCE_NAME --resource-group $OPENAI_RESOURCE_GROUP --query "key1" -o tsv)
echo "AZURE_OPENAI_API_KEY=$OPENAI_KEY"

# List OpenAI deployments
echo ""
echo "=== Available OpenAI Deployments ==="
az cognitiveservices account deployment list --name $OPENAI_RESOURCE_NAME --resource-group $OPENAI_RESOURCE_GROUP --query "[].{name:name, model:properties.model.name, version:properties.model.version}" -o table
echo ""

# Get Speech Services info
echo "=== Speech Services Info ==="
echo "AZURE_SPEECH_RESOURCE_NAME=$SPEECH_RESOURCE_NAME"
SPEECH_REGION=$(az cognitiveservices account show --name $SPEECH_RESOURCE_NAME --resource-group $SPEECH_RESOURCE_GROUP --query "location" -o tsv)
echo "AZURE_SPEECH_REGION=$SPEECH_REGION"
SPEECH_KEY=$(az cognitiveservices account keys list --name $SPEECH_RESOURCE_NAME --resource-group $SPEECH_RESOURCE_GROUP --query "key1" -o tsv)
echo "AZURE_SPEECH_KEY=$SPEECH_KEY"
echo ""

echo "=== Summary for .env file ==="
echo ""
echo "SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
echo "RESOURCE_GROUP_NAME=$AI_RESOURCE_GROUP"
echo "AZURE_AI_RESOURCE_NAME=$AI_RESOURCE_NAME"
echo "AZURE_AI_REGION=$AI_REGION"
echo "PROJECT_ENDPOINT=$AI_ENDPOINT"
echo "AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT"
echo "AZURE_OPENAI_API_KEY=$OPENAI_KEY"
echo "AZURE_SPEECH_KEY=$SPEECH_KEY"
echo "AZURE_SPEECH_REGION=$SPEECH_REGION"
echo ""
echo "Note: Check the deployments table above for MODEL_DEPLOYMENT_NAME"
echo "Note: AZURE_AI_PROJECT_NAME and AGENT_ID need to be set manually if using Azure AI Agents"
