using VoiceLive.Api.Configuration;
using VoiceLive.Api.Hubs;
using VoiceLive.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Configure Kestrel to listen on all interfaces
builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.ListenAnyIP(5000);
});

// Add services to the container
builder.Services.AddControllers();

// Configure Azure services settings
builder.Services.Configure<AzureSettings>(builder.Configuration.GetSection("Azure"));

// Register application services
builder.Services.AddSingleton<IScenarioManager, ScenarioManager>();
builder.Services.AddSingleton<IAgentManager, AgentManager>();
builder.Services.AddScoped<IConversationAnalyzer, ConversationAnalyzer>();
builder.Services.AddScoped<IPronunciationAssessor, PronunciationAssessor>();
builder.Services.AddScoped<IGraphScenarioGenerator, GraphScenarioGenerator>();

// Add SignalR for WebSocket support
builder.Services.AddSignalR();

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:5173", "http://localhost:3000")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.UseCors();

// Serve static files (React frontend)
app.UseDefaultFiles();
app.UseStaticFiles();

app.UseRouting();
app.UseAuthorization();

app.MapControllers();
app.MapHub<VoiceProxyHub>("/ws/voice");

// Fallback to index.html for client-side routing
app.MapFallbackToFile("index.html");

app.Run();
