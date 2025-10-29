using Azure.Identity;
using Microsoft.Extensions.Options;
using VoiceLive.Api.Configuration;
using VoiceLive.Api.Models;

namespace VoiceLive.Api.Services;

public class AgentManager : IAgentManager
{
    private readonly Dictionary<string, Agent> _agents = new();
    private readonly IScenarioManager _scenarioManager;
    private readonly AzureSettings _azureSettings;
    private readonly ILogger<AgentManager> _logger;

    public AgentManager(
        IScenarioManager scenarioManager,
        IOptions<AzureSettings> azureSettings,
        ILogger<AgentManager> logger)
    {
        _scenarioManager = scenarioManager;
        _azureSettings = azureSettings.Value;
        _logger = logger;
    }

    public async Task<Agent> CreateAgentAsync(string scenarioId)
    {
        var scenario = _scenarioManager.GetScenario(scenarioId);
        if (scenario == null)
        {
            throw new ArgumentException($"Scenario not found: {scenarioId}");
        }

        var agentId = _azureSettings.AI.UseAzureAIAgents
            ? $"agent-{scenarioId}-{Guid.NewGuid()}"
            : $"local-agent-{scenarioId}-{Guid.NewGuid()}";

        var instructions = string.Join("\n\n", scenario.Messages
            .Where(m => m.Role.ToLower() == "system")
            .Select(m => m.Content));

        var agent = new Agent
        {
            Id = agentId,
            ScenarioId = scenarioId,
            IsAzureAgent = _azureSettings.AI.UseAzureAIAgents,
            Instructions = instructions,
            Model = scenario.Model,
            Temperature = scenario.ModelParameters.Temperature,
            MaxTokens = scenario.ModelParameters.MaxTokens,
            CreatedAt = DateTime.UtcNow
        };

        if (_azureSettings.AI.UseAzureAIAgents)
        {
            try
            {
                agent.AzureAgentId = await CreateAzureAgentAsync(scenario, instructions);
                _logger.LogInformation($"Created Azure AI agent: {agent.AzureAgentId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create Azure AI agent");
                throw;
            }
        }

        _agents[agentId] = agent;
        _logger.LogInformation($"Created agent: {agentId} for scenario: {scenarioId}");

        return agent;
    }

    public Agent? GetAgent(string agentId)
    {
        return _agents.TryGetValue(agentId, out var agent) ? agent : null;
    }

    public async Task DeleteAgentAsync(string agentId)
    {
        if (_agents.TryGetValue(agentId, out var agent))
        {
            if (agent.IsAzureAgent && !string.IsNullOrEmpty(agent.AzureAgentId))
            {
                try
                {
                    await DeleteAzureAgentAsync(agent.AzureAgentId);
                    _logger.LogInformation($"Deleted Azure AI agent: {agent.AzureAgentId}");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Failed to delete Azure AI agent: {agent.AzureAgentId}");
                }
            }

            _agents.Remove(agentId);
            _logger.LogInformation($"Deleted agent: {agentId}");
        }
    }

    private async Task<string> CreateAzureAgentAsync(Scenario scenario, string instructions)
    {
        // TODO: Implement Azure AI Projects agent creation when SDK is stable
        // For now, return a placeholder
        await Task.CompletedTask;
        return $"azure-agent-{Guid.NewGuid()}";

        /*
        var credential = new DefaultAzureCredential();
        var projectClient = new AIProjectClient(
            new Uri(_azureSettings.AI.ProjectEndpoint),
            credential);

        var agent = await projectClient.CreateAgentAsync(
            model: scenario.Model,
            name: scenario.Name,
            instructions: instructions,
            tools: new[] { new CodeInterpreterTool() });

        return agent.Value.Id;
        */
    }

    private async Task DeleteAzureAgentAsync(string azureAgentId)
    {
        // TODO: Implement Azure AI Projects agent deletion
        await Task.CompletedTask;

        /*
        var credential = new DefaultAzureCredential();
        var projectClient = new AIProjectClient(
            new Uri(_azureSettings.AI.ProjectEndpoint),
            credential);

        await projectClient.DeleteAgentAsync(azureAgentId);
        */
    }
}
