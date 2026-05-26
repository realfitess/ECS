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

var builder = WebApplication.CreateBuilder(args);

IConfiguration configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json", optional: true)
    .Build();

// =========================
// SAFE CONFIG (NO CRASH)
// =========================
static string Safe(IConfiguration cfg, string key)
    => cfg.GetSection(key).Value ?? "";

// DB
Roblox.Services.Database.Configure(Safe(configuration, "Postgres"));
Roblox.Services.Cache.Configure(Safe(configuration, "Redis"));

// CONFIG SAFETY
Roblox.Configuration.CdnBaseUrl = Safe(configuration, "CdnBaseUrl");
Roblox.Configuration.AssetDirectory = Safe(configuration, "Directories:Asset");
Roblox.Configuration.StorageDirectory = Safe(configuration, "Directories:Storage");
Roblox.Configuration.ThumbnailsDirectory = Safe(configuration, "Directories:Thumbnails");
Roblox.Configuration.GroupIconsDirectory = Safe(configuration, "Directories:GroupIcons");
Roblox.Configuration.PublicDirectory = Safe(configuration, "Directories:Public");
Roblox.Configuration.XmlTemplatesDirectory = Safe(configuration, "Directories:XmlTemplates");
Roblox.Configuration.JsonDataDirectory = Safe(configuration, "Directories:JsonData");

Roblox.Configuration.BaseUrl = Safe(configuration, "BaseUrl");

// =========================
// FIX: CREATE MISSING DIRS
// =========================
void EnsureDir(string path)
{
    if (!string.IsNullOrWhiteSpace(path))
        Directory.CreateDirectory(path);
}

EnsureDir(Roblox.Configuration.ThumbnailsDirectory);
EnsureDir(Roblox.Configuration.GroupIconsDirectory);
EnsureDir(Roblox.Configuration.PublicDirectory + "UnsecuredContent");
EnsureDir("/app/api/public/images/thumbnails");

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
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseRouting();

var cacheHeaders = (StaticFileResponseContext ctx) =>
{
    ctx.Context.Response.Headers[HeaderNames.CacheControl] = "public,max-age=86400";
};

// =========================
// STATIC FILES SAFE MODE
// =========================
if (Directory.Exists(Roblox.Configuration.ThumbnailsDirectory))
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(Roblox.Configuration.ThumbnailsDirectory),
        RequestPath = "/images/thumbnails",
        OnPrepareResponse = cacheHeaders,
    });
}

if (Directory.Exists(Roblox.Configuration.GroupIconsDirectory))
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(Roblox.Configuration.GroupIconsDirectory),
        RequestPath = "/images/groups",
        OnPrepareResponse = cacheHeaders,
    });
}

app.UseStaticFiles();

app.UseSwagger();
app.UseSwaggerUI();

app.UseRobloxSessionMiddleware();
app.UseRobloxPlayerCorsMiddleware();
app.UseRobloxCsrfMiddleware();
app.UseApplicationGuardMiddleware();

app.UseMiddleware<FrontendProxyMiddleware>();
app.UseRobloxLoggingMiddleware();

app.UseExceptionHandler("/error");

SessionMiddleware.Configure(Safe(configuration, "Jwt:Sessions"));
app.UseTimerMiddleware();

app.UseEndpoints(e =>
{
    e.MapHub<ChatHub>("/chat");
    e.MapControllers();
    e.MapRazorPages();
});

app.Run();
