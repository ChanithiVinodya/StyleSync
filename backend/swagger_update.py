import re
import sys

def fix_images_controller():
    file_path = r"d:\SEF_Project\StyleSync\Backend\src\StyleSync.Api\Modules\ProjectRequests\Controllers\ProjectRequestImagesController.cs"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Remove duplicated [HttpPost] and [HttpDelete("{imageId}")]
    content = content.replace("[HttpPost]\n    /// <summary>", "/// <summary>")
    content = content.replace("[HttpDelete(\"{imageId}\")]\n    /// <summary>", "/// <summary>")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)


def inject_swagger_requests():
    file_path = r"d:\SEF_Project\StyleSync\Backend\src\StyleSync.Api\Modules\ProjectRequests\Controllers\ProjectRequestsController.cs"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    replacements = [
        (
            r"    \[HttpGet\]\n    public async Task<IActionResult> GetRequests\(\[FromQuery\] RequestQueryParameters query\)",
            """    /// <summary>
    /// Gets a paginated list of project requests.
    /// </summary>
    /// <response code="200">Returns the paginated list.</response>
    /// <response code="400">If the query parameters are invalid.</response>
    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<RequestSummaryDto>), 200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    public async Task<IActionResult> GetRequests([FromQuery] RequestQueryParameters query)"""
        ),
        (
            r"    \[HttpPost\]\n    \[Authorize\(Roles = \"Client\"\)]\n    public async Task<IActionResult> CreateDraft",
            """    /// <summary>
    /// Creates a new draft project request.
    /// </summary>
    /// <response code="201">Returns the created draft.</response>
    /// <response code="400">If validation fails.</response>
    [HttpPost]
    [ProducesResponseType(typeof(RequestDetailDto), 201)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> CreateDraft"""
        ),
        (
            r"    \[HttpGet\(\"\{id:guid\}\"\)\]\n    public async Task<IActionResult> GetById",
            """    /// <summary>
    /// Gets a project request by its unique identifier.
    /// </summary>
    /// <response code="200">Returns the request details.</response>
    /// <response code="404">If the request is not found.</response>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(RequestDetailDto), 200)]
    [ProducesResponseType(typeof(ProblemDetails), 404)]
    public async Task<IActionResult> GetById"""
        ),
        (
            r"    \[HttpPut\(\"\{id:guid\}\"\)\]\n    \[Authorize\(Roles = \"Client\"\)]\n    public async Task<IActionResult> UpdateDraft",
            """    /// <summary>
    /// Updates an existing draft project request.
    /// </summary>
    /// <response code="204">If the update is successful.</response>
    /// <response code="400">If validation fails.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is not a Draft.</response>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> UpdateDraft"""
        ),
        (
            r"    \[HttpDelete\(\"\{id:guid\}\"\)\]\n    \[Authorize\(Roles = \"Client\"\)]\n    public async Task<IActionResult> DeleteDraft",
            """    /// <summary>
    /// Deletes a draft project request.
    /// </summary>
    /// <response code="204">If deletion is successful.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is not a Draft.</response>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(typeof(ProblemDetails), 404)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> DeleteDraft"""
        ),
        (
            r"    \[HttpPost\(\"\{id:guid\}/submit\"\)]\n    \[Authorize\(Roles = \"Client\"\)]\n    public async Task<IActionResult> SubmitDraft",
            """    /// <summary>
    /// Submits a draft project request for processing.
    /// </summary>
    /// <response code="200">If submission is successful.</response>
    /// <response code="400">If strict submit validation fails.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is not a Draft.</response>
    [HttpPost("{id:guid}/submit")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> SubmitDraft"""
        ),
        (
            r"    \[HttpPost\(\"\{id:guid\}/cancel\"\)]\n    \[Authorize\(Roles = \"Admin\"\)]\n    public async Task<IActionResult> CancelRequest",
            """    /// <summary>
    /// Cancels an active project request. (Admin only)
    /// </summary>
    /// <response code="200">If cancellation is successful.</response>
    /// <response code="400">If the reason is invalid.</response>
    /// <response code="404">If the request is not found.</response>
    /// <response code="409">If the request is in a terminal state.</response>
    [HttpPost("{id:guid}/cancel")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CancelRequest"""
        ),
        (
            r"    \[HttpPost\(\"\{id:guid\}/flag\"\)]\n    \[Authorize\(Roles = \"Admin\"\)]\n    public async Task<IActionResult> FlagRequest",
            """    /// <summary>
    /// Flags or unflags a project request for review. (Admin only)
    /// </summary>
    /// <response code="200">If flagging/unflagging is successful.</response>
    /// <response code="400">If the reason is invalid.</response>
    /// <response code="404">If the request is not found.</response>
    [HttpPost("{id:guid}/flag")]
    [ProducesResponseType(200)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> FlagRequest"""
        ),
        (
            r"    \[HttpGet\(\"analytics\"\)]\n    \[Authorize\(Roles = \"Admin\"\)]\n    public async Task<IActionResult> GetAnalytics",
            """    /// <summary>
    /// Gets aggregated analytics for project requests. (Admin only)
    /// </summary>
    /// <response code="200">Returns the analytics data.</response>
    [HttpGet("analytics")]
    [ProducesResponseType(typeof(AnalyticsResponseDto), 200)]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAnalytics"""
        )
    ]

    for p, repl in replacements:
        content = re.sub(p, repl, content)

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

if __name__ == "__main__":
    fix_images_controller()
    inject_swagger_requests()
    print("Done")
