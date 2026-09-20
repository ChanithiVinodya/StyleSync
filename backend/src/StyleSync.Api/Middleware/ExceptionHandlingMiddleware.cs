using System.Net;
using System.Text.Json;
using StyleSync.Api.DTOs;

namespace StyleSync.Api.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred during request execution.");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";

        var (statusCode, message) = exception switch
        {
            UnauthorizedAccessException unauth => ((int)HttpStatusCode.Unauthorized, unauth.Message),
            BadHttpRequestException badReq => ((int)HttpStatusCode.BadRequest, badReq.Message),
            InvalidOperationException conflict => ((int)HttpStatusCode.Conflict, conflict.Message),
            KeyNotFoundException notFound => ((int)HttpStatusCode.NotFound, notFound.Message),
            _ => ((int)HttpStatusCode.InternalServerError, "An unexpected error occurred.")
        };

        context.Response.StatusCode = statusCode;

        var response = new ErrorResponse(
            statusCode,
            message,
            context.TraceIdentifier
        );

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        return context.Response.WriteAsync(JsonSerializer.Serialize(response, options));
    }
}
