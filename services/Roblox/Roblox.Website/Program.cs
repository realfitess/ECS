using System.Diagnostics;
using System.Text.Json;
using Microsoft.AspNetCore.Http.Json;
using Roblox.Rendering;
using Roblox.Website.Middleware;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Extensions.FileProviders;
using Microsoft.Net.Http.Headers;
using Roblox;
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

// =========================
// DB / CONFIG (twoje)
// =========================
Roblox.Services.Database.Configure(configuration.GetSection("Postgres").Value);
Roblox.Services.Cache.Configure(configuration.GetSection("Redis").Value);

Roblox.Configuration.CdnBaseUrl = configuration.GetSection("CdnBaseUrl").Value;
Roblox.Configuration.AssetDirectory = configuration.GetSection("Directories:Asset").Value;
Roblox.Configuration.StorageDirectory = configuration.GetSection("Directories:Storage").Value;
Roblox.Configuration.ThumbnailsDirectory = configuration.GetSection("Directories:Thumbnails").Value;
Roblox.Configuration.GroupIconsDirectory = configuration.GetSection("Directories:GroupIcons").Value;
Roblox.Configuration.PublicDirectory = configuration.GetSection("Directories:Public").Value;
Roblox.Configuration.XmlTemplatesDirectory = configuration.GetSection("Directories:XmlTemplates").Value;
Roblox.Configuration.JsonDataDirectory = configuration.GetSection("Directories:JsonData").Value;
Roblox.Configuration.AdminBundleDirectory = configuration.GetSection("Directories:AdminBundle").Value;
Roblox.Configuration.EconomyChatBundleDirectory = configuration.GetSection("Directories:EconomyChatBundle").Value;

// =========================
// 🔧 FIX: ensure directories exist (CRASH FIX)
// =========================
void EnsureDir(string path)
{
    if (!string.IsNullOrWhiteSpace(path) && !Directory.Exists(path))
        Directory.CreateDirectory(path);
}

EnsureDir(Roblox.Configuration.AssetDirectory);
EnsureDir(Roblox.Configuration.StorageDirectory);
EnsureDir(Roblox.Configuration.ThumbnailsDirectory);
EnsureDir(Roblox.Configuration.GroupIconsDirectory);
EnsureDir(Roblox.Configuration.PublicDirectory);

// =========================
// SERVICES
// =========================
builder.Services.AddRazorPages();

builder.Services.AddControllers().AddJsonOptions(o =>
{
    o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    o.JsonSerializerOptions.PropertyNamingPolicy = null;
});

builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SchemaGeneratorOptions.SchemaIdSelector = type => type.ToString();
    c.OperationFilter<SwaggerFileOperationFilter>();
});

var app = builder.Build();

app.UseRouting();

// =========================
// cache headers
// =========================
var prepareResponseForCache = (StaticFileResponseContext ctx) =>
{
    const int durationInSeconds = 86400 * 365;
    ctx.Context.Response.Headers[HeaderNames.CacheControl] = "public,max-age=" + durationInSeconds;
    ctx.Context.Response.Headers.Remove(HeaderNames.LastModified);
};

// =========================
// static files SAFE MODE
// =========================
if (Directory.Exists(Roblox.Configuration.PublicDirectory + "UnsecuredContent"))
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(Roblox.Configuration.PublicDirectory + "UnsecuredContent"),
        RequestPath = "/UnsecuredContent",
        OnPrepareResponse = prepareResponseForCache,
    });
}

if (string.IsNullOrWhiteSpace(Roblox.Configuration.CdnBaseUrl))
{
    if (Directory.Exists(Roblox.Configuration.ThumbnailsDirectory))
    {
        app.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = new PhysicalFileProvider(Roblox.Configuration.ThumbnailsDirectory),
            RequestPath = "/images/thumbnails",
            OnPrepareResponse = prepareResponseForCache,
        });
    }

    if (Directory.Exists(Roblox.Configuration.GroupIconsDirectory))
    {
        app.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = new PhysicalFileProvider(Roblox.Configuration.GroupIconsDirectory),
            RequestPath = "/images/groups",
            OnPrepareResponse = prepareResponseForCache,
        });
    }
}

if (Directory.Exists(Roblox.Configuration.PublicDirectory + "img/"))
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(Roblox.Configuration.PublicDirectory + "img/"),
        RequestPath = "/img",
        OnPrepareResponse = prepare
