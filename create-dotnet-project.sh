#!/bin/bash

# Create .NET 9.0 Backend Migration Script
# Run this from /workspaces/voicelive-api-salescoachdemo

cd /workspaces/voicelive-api-salescoachdemo

# Create backend-dotnet directory
mkdir -p backend-dotnet
cd backend-dotnet

# Initialize .NET projects
dotnet new webapi -n VoiceLive.Api --framework net9.0 -o VoiceLive.Api
dotnet new xunit -n VoiceLive.Api.Tests --framework net9.0 -o VoiceLive.Api.Tests
dotnet new sln -n VoiceLive
dotnet sln add VoiceLive.Api/VoiceLive.Api.csproj
dotnet sln add VoiceLive.Api.Tests/VoiceLive.Api.Tests.csproj
cd VoiceLive.Api.Tests
dotnet add reference ../VoiceLive.Api/VoiceLive.Api.csproj
cd ..

# Add NuGet packages to API project
cd VoiceLive.Api
dotnet add package Azure.AI.OpenAI --version 2.1.0
dotnet add package Azure.AI.Projects --version 1.0.0-beta.2
dotnet add package Azure.Identity --version 1.13.1
dotnet add package Microsoft.CognitiveServices.Speech --version 1.45.0
dotnet add package Microsoft.AspNetCore.SignalR.Client --version 9.0.0
dotnet add package YamlDotNet --version 16.2.1
cd ..

# Add NuGet packages to test project
cd VoiceLive.Api.Tests
dotnet add package Moq --version 4.20.72
dotnet add package FluentAssertions --version 7.0.0
dotnet add package Microsoft.AspNetCore.Mvc.Testing --version 9.0.0
cd ..

echo "✓ .NET 9.0 project structure created successfully!"
echo ""
echo "Next steps:"
echo "1. Enable file editing tools in Copilot"
echo "2. I'll create all the service, controller, and model files"
echo "3. Copy your scenario YAML files to backend-dotnet/VoiceLive.Api/Data/"