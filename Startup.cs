using System.Collections.Generic;
using System.IO;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Ngcli.NetCore.Extensions;

// ReSharper disable ClassNeverInstantiated.Global
// ReSharper disable UnusedMember.Global

namespace Ngcli.NetCore
{
    internal class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddMvc()
                .SetCompatibilityVersion(CompatibilityVersion.Version_2_1);
        }

        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            // Registered before static files to always set header.
            app.UseNwebsec();

            // To support Angular routing, we need to handle 404 errors.
            // In case a requested resource was not found on the server, it could be a Angular route.
            // This means we should redirect request, which results in a error 404, to the index.html.
            app.Use(async (context, next) =>
            {
                await next();
                if (context.Response.StatusCode == StatusCodes.Status404NotFound &&
                    !Path.HasExtension(context.Request.Path.Value))
                {
                    context.Request.Path = "/";
                    context.Response.StatusCode = StatusCodes.Status200OK;
                    await next();
                }
            });

            app.UseDefaultFiles(new DefaultFilesOptions
            {
                DefaultFileNames = new List<string> { "index.html" }
            });

            app.UseStaticFiles();
            app.UseMvcWithDefaultRoute();
        }
    }
}
