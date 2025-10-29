using Microsoft.AspNetCore.SignalR;
using Microsoft.CognitiveServices.Speech;
using Microsoft.Extensions.Options;
using System.Text;
using System.Text.Json;
using VoiceLive.Api.Configuration;

namespace VoiceLive.Api.Hubs;

public class VoiceProxyHub : Hub
{
    private readonly AzureSettings _azureSettings;
    private readonly ILogger<VoiceProxyHub> _logger;
    private static readonly Dictionary<string, SpeechSynthesizer> _activeSessions = new();

    public VoiceProxyHub(
        IOptions<AzureSettings> azureSettings,
        ILogger<VoiceProxyHub> logger)
    {
        _azureSettings = azureSettings.Value;
        _logger = logger;
    }

    public async Task ConfigureSession(string sessionConfig)
    {
        try
        {
            var config = JsonSerializer.Deserialize<SessionConfiguration>(sessionConfig);
            if (config == null)
            {
                _logger.LogError("Failed to deserialize session configuration");
                await Clients.Caller.SendAsync("error", new { message = "Invalid session configuration" });
                return;
            }

            var speechConfig = SpeechConfig.FromSubscription(
                _azureSettings.Speech.Key,
                _azureSettings.Speech.Region);

            // Configure voice settings
            speechConfig.SpeechSynthesisVoiceName = config.Voice?.Name ?? "en-US-AvaMultilingualNeural";

            // Create speech synthesizer with default audio output
            var synthesizer = new SpeechSynthesizer(speechConfig, null);            // Store the session
            var sessionId = Context.ConnectionId;
            _activeSessions[sessionId] = synthesizer;

            _logger.LogInformation($"Session configured for connection: {sessionId}");
            await Clients.Caller.SendAsync("session.created", new { sessionId });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error configuring session");
            await Clients.Caller.SendAsync("error", new { message = ex.Message });
        }
    }

    public async Task SendAudioData(byte[] audioData)
    {
        try
        {
            var sessionId = Context.ConnectionId;
            if (!_activeSessions.TryGetValue(sessionId, out var synthesizer))
            {
                _logger.LogWarning($"No active session found for connection: {sessionId}");
                await Clients.Caller.SendAsync("error", new { message = "No active session" });
                return;
            }

            // In a real implementation, this would handle incoming audio for speech recognition
            // For now, we'll just log it
            _logger.LogDebug($"Received audio data: {audioData.Length} bytes");

            // Echo back acknowledgment
            await Clients.Caller.SendAsync("audio.received", new { size = audioData.Length });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing audio data");
            await Clients.Caller.SendAsync("error", new { message = ex.Message });
        }
    }

    public async Task SynthesizeText(string text)
    {
        try
        {
            var sessionId = Context.ConnectionId;
            if (!_activeSessions.TryGetValue(sessionId, out var synthesizer))
            {
                _logger.LogWarning($"No active session found for connection: {sessionId}");
                await Clients.Caller.SendAsync("error", new { message = "No active session" });
                return;
            }

            _logger.LogInformation($"Synthesizing text: {text}");

            // Synthesize speech
            var result = await synthesizer.SpeakTextAsync(text);

            if (result.Reason == ResultReason.SynthesizingAudioCompleted)
            {
                _logger.LogInformation($"Speech synthesized: {result.AudioData.Length} bytes");

                // Send audio data back to client in chunks
                const int chunkSize = 8192;
                for (int i = 0; i < result.AudioData.Length; i += chunkSize)
                {
                    var chunk = result.AudioData.Skip(i).Take(chunkSize).ToArray();
                    await Clients.Caller.SendAsync("audio.data", chunk);
                }

                await Clients.Caller.SendAsync("audio.completed", new { duration = result.AudioDuration.TotalSeconds });
            }
            else if (result.Reason == ResultReason.Canceled)
            {
                var cancellation = SpeechSynthesisCancellationDetails.FromResult(result);
                _logger.LogError($"Speech synthesis canceled: {cancellation.Reason}, {cancellation.ErrorDetails}");
                await Clients.Caller.SendAsync("error", new { message = cancellation.ErrorDetails });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error synthesizing text");
            await Clients.Caller.SendAsync("error", new { message = ex.Message });
        }
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var sessionId = Context.ConnectionId;

        if (_activeSessions.TryGetValue(sessionId, out var synthesizer))
        {
            synthesizer.Dispose();
            _activeSessions.Remove(sessionId);
            _logger.LogInformation($"Session cleaned up for connection: {sessionId}");
        }

        if (exception != null)
        {
            _logger.LogError(exception, $"Client disconnected with error: {sessionId}");
        }
        else
        {
            _logger.LogInformation($"Client disconnected: {sessionId}");
        }

        await base.OnDisconnectedAsync(exception);
    }
}

public class SessionConfiguration
{
    public string? Modalities { get; set; }
    public string? Instructions { get; set; }
    public VoiceConfiguration? Voice { get; set; }
    public string? InputAudioFormat { get; set; }
    public string? OutputAudioFormat { get; set; }
    public InputAudioTranscription? InputAudioTranscription { get; set; }
    public TurnDetection? TurnDetection { get; set; }
    public List<Tool>? Tools { get; set; }
    public string? ToolChoice { get; set; }
    public double? Temperature { get; set; }
    public int? MaxResponseOutputTokens { get; set; }
}

public class VoiceConfiguration
{
    public string Name { get; set; } = "en-US-AvaMultilingualNeural";
}

public class InputAudioTranscription
{
    public string? Model { get; set; }
}

public class TurnDetection
{
    public string? Type { get; set; }
    public double? Threshold { get; set; }
    public int? PrefixPaddingMs { get; set; }
    public int? SilenceDurationMs { get; set; }
}

public class Tool
{
    public string? Type { get; set; }
    public string? Name { get; set; }
    public string? Description { get; set; }
    public object? Parameters { get; set; }
}
