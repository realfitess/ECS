using System.Diagnostics;
using System.Text.Json;
using Microsoft.AspNetCore.Http.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Extensions.FileProviders;
using Microsoft.Net.Http.Headers;

using Roblox;
using Roblox.Rendering;
using Roblox.Website.Middleware;
using Roblox.Services;
using Roblox.Services.App.FeatureFlags;
using Roblox.Website.Hubs;
using Roblox.Website.WebsiteModels;

var domain = AppDomain.CurrentDomain;
domain.SetData("REGEX_DEFAULT_MATCH_TIMEOUT", TimeSpan.FromSeconds(5));

IConfiguration configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();

var builder = WebApplication.CreateBuilder(args);

// ================= DB / CACHE =================
Roblox.Services.Database.Configure(configuration.GetSection("Postgres").Value);
Roblox.Services.Cache.Configure(configuration.GetSection("Redis").Value);

// ================= CONFIG =================
Roblox.Configuration.CdnBaseUrl = configuration.GetSection("CdnBaseUrl").Value;
Roblox.Configuration.AssetDirectory = configuration.GetSection("Directories:Asset").Value;
Roblox.Configuration.StorageDirectory = configuration.GetSection("Directories:Storage").Value;
Roblox.Configuration.ThumbnailsDirectory = configuration.GetSection("Directories:Thumbnails").Value;
Roblox.Configuration.GroupIconsDirectory = configuration.GetSection("Directories:GroupIcons").Value;
Roblox.Configuration.PublicDirectory = configuration.GetSection("Directories:Public").Value;

Roblox.Configuration.BaseUrl = configuration.GetSection("BaseUrl").Value;
Roblox.Configuration.HCaptchaPublicKey = configuration.GetSection("HCaptcha:Public").Value;
Roblox.Configuration.HCaptchaPrivateKey = configuration.GetSection("HCaptcha:Private").Value;

// game servers
IConfiguration gameServerConfig = new ConfigurationBuilder()
    .AddJsonFile("game-servers.json")
    .Build();

Roblox.Configuration.GameServerIpAddresses =
    gameServerConfig.GetSection("GameServers").Get<IEnumerable<GameServerConfigEntry>>();

// ================= SERVICES =================
builder.Services.AddRazorPages();
builder.Services.AddControllers().AddJsonOptions(o =>
{
    o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    o.JsonSerializerOptions.PropertyNamingPolicy = null;
});

builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ================= APP =================
var app = builder.Build();

app.UseRouting();

// ================= STATIC FILES =================
var cache = new StaticFileResponseContext(ctx =>
{
    ctx.Context.Response.Headers[HeaderNames.CacheControl] = "public,max-age=31536000";
});

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(Roblox.Configuration.PublicDirectory + "UnsecuredContent"),
    RequestPath = "/UnsecuredContent"
});

if (string.IsNullOrWhiteSpace(Roblox.Configuration.CdnBaseUrl))
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(Roblox.Configuration.ThumbnailsDirectory),
        RequestPath = "/images/thumbnails"
    });

    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(Roblox.Configuration.GroupIconsDirectory),
        RequestPath = "/images/groups"
    });
}

// ================= MIDDLEWARE =================
app.UseRobloxSessionMiddleware();
app.UseRobloxPlayerCorsMiddleware();
app.UseRobloxCsrfMiddleware();
app.UseApplicationGuardMiddleware();

Roblox.Website.Middleware.ApplicationGuardMiddleware.Configure(
    configuration.GetSection("Authorization").Value);

Roblox.Website.Middleware.CsrfMiddleware.Configure(Guid.NewGuid().ToString());

app.UseSwagger();
app.UseSwaggerUI();

app.UseMiddleware<FrontendProxyMiddleware>();
app.UseRobloxLoggingMiddleware();

app.UseExceptionHandler("/error");

// ================= SERVICES INIT =================
CommandHandler.Configure(
    configuration.GetSection("Render:BaseUrl").Value,
    configuration.GetSection("Render:Authorization").Value);

SessionMiddleware.Configure(configuration.GetSection("Jwt:Sessions").Value);

app.UseTimerMiddleware();

// ================= BACKGROUND TASK =================
Task.Run(async () =>
{
    await Task.Delay(5000);
    using var assets = Roblox.Services.ServiceProvider.GetOrCreate<AssetsService>();
    await assets.FixAssetImagesWithoutMetadata();
});

// ================= ENDPOINTS =================
app.UseEndpoints(endpoints =>
{
    endpoints.MapHub<ChatHub>("/chat");
    endpoints.MapControllers();
    endpoints.MapRazorPages();
});

app.Run();
