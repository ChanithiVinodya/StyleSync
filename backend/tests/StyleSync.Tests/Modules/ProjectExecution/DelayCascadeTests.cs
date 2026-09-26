using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.ProjectExecution.Models;
using StyleSync.Api.Modules.ProjectExecution.Services;
using Xunit;
using TaskStatus = StyleSync.Api.Modules.ProjectExecution.Models.TaskStatus;

namespace StyleSync.Tests.Modules.ProjectExecution;

public class DelayCascadeTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly DelayService _delayService;

    public DelayCascadeTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .ConfigureWarnings(x => x.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _context = new AppDbContext(options);
        _delayService = new DelayService(_context);
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }

    private async Task<ProjectTask> CreateTaskAsync(string name, DateTime startDate, DateTime dueDate, TaskStatus status = TaskStatus.InProgress)
    {
        var pId = Guid.NewGuid();
        var mId = Guid.NewGuid();
        var t = new ProjectTask
        {
            TaskId = Guid.NewGuid(),
            MilestoneId = mId,
            Name = name,
            StartDate = startDate,
            DueDate = dueDate,
            Status = status
        };
        _context.ProjectTasks.Add(t);
        await _context.SaveChangesAsync();
        return t;
    }

    private async Task AddDependencyAsync(Guid dependentId, Guid prerequisiteId)
    {
        _context.TaskDependencies.Add(new TaskDependency
        {
            TaskId = dependentId,
            PrerequisiteTaskId = prerequisiteId
        });
        await _context.SaveChangesAsync();
    }

    [Fact]
    public async Task DelayDetection_StatusChangedToDelayed_WhenOverdue()
    {
        var pastDate = DateTime.UtcNow.AddDays(-2);
        var t1 = await CreateTaskAsync("Task A", pastDate.AddDays(-2), pastDate, TaskStatus.InProgress);

        var result = await _delayService.RunDelayDetectionAsync();

        Assert.Equal(1, result.DetectedTasks);
        Assert.Equal(0, result.CascadeUpdatedTasks);

        var updatedT1 = await _context.ProjectTasks.FindAsync(t1.TaskId);
        Assert.Equal(TaskStatus.Delayed, updatedT1!.Status);
        Assert.Equal(2, updatedT1.CascadedDelay);
    }

    [Fact]
    public async Task DelayDetection_IgnoresCompletedTasks()
    {
        var pastDate = DateTime.UtcNow.AddDays(-2);
        var t1 = await CreateTaskAsync("Task A", pastDate.AddDays(-2), pastDate, TaskStatus.Completed);

        var result = await _delayService.RunDelayDetectionAsync();

        Assert.Equal(0, result.DetectedTasks);
    }

    [Fact]
    public async Task DelayCascade_OneLevel_ShiftsDependent()
    {
        var today = DateTime.UtcNow.Date;
        var t1 = await CreateTaskAsync("A", today.AddDays(-5), today.AddDays(-3), TaskStatus.InProgress); // 3 days delayed
        var t2 = await CreateTaskAsync("B", today.AddDays(-1), today.AddDays(2), TaskStatus.NotStarted);

        var originalT2Duration = (t2.DueDate - t2.StartDate).Days;

        await AddDependencyAsync(t2.TaskId, t1.TaskId);

        var result = await _delayService.RunDelayDetectionAsync();

        Assert.Equal(1, result.DetectedTasks);
        Assert.Equal(1, result.CascadeUpdatedTasks);

        var updatedT2 = await _context.ProjectTasks.FindAsync(t2.TaskId);
        Assert.Equal(today.AddDays(-1 + 3), updatedT2!.StartDate);
        Assert.Equal(today.AddDays(2 + 3), updatedT2.DueDate);
        Assert.Equal(originalT2Duration, (updatedT2.DueDate - updatedT2.StartDate).Days);
        Assert.Equal(TaskStatus.NotStarted, updatedT2.Status); // Status unchanged
    }

    [Fact]
    public async Task DelayCascade_MultiLevel_ShiftsAll()
    {
        var today = DateTime.UtcNow.Date;
        var t1 = await CreateTaskAsync("A", today.AddDays(-5), today.AddDays(-4), TaskStatus.InProgress); // 4 days delayed
        var t2 = await CreateTaskAsync("B", today.AddDays(-1), today.AddDays(1), TaskStatus.NotStarted);
        var t3 = await CreateTaskAsync("C", today.AddDays(2), today.AddDays(4), TaskStatus.NotStarted);

        await AddDependencyAsync(t2.TaskId, t1.TaskId);
        await AddDependencyAsync(t3.TaskId, t2.TaskId);

        var result = await _delayService.RunDelayDetectionAsync();

        Assert.Equal(1, result.DetectedTasks);
        Assert.Equal(2, result.CascadeUpdatedTasks);

        var updatedT2 = await _context.ProjectTasks.FindAsync(t2.TaskId);
        var updatedT3 = await _context.ProjectTasks.FindAsync(t3.TaskId);

        Assert.Equal(today.AddDays(-1 + 4), updatedT2!.StartDate);
        Assert.Equal(today.AddDays(2 + 4), updatedT3!.StartDate);
    }

    [Fact]
    public async Task DelayCascade_CompletedDependent_NotShifted()
    {
        var today = DateTime.UtcNow.Date;
        var t1 = await CreateTaskAsync("A", today.AddDays(-5), today.AddDays(-4), TaskStatus.InProgress); // 4 days delayed
        var t2 = await CreateTaskAsync("B", today.AddDays(-1), today.AddDays(1), TaskStatus.Completed);

        await AddDependencyAsync(t2.TaskId, t1.TaskId);

        var result = await _delayService.RunDelayDetectionAsync();

        Assert.Equal(1, result.DetectedTasks);
        Assert.Equal(0, result.CascadeUpdatedTasks); // T2 is completed, so it isn't shifted

        var updatedT2 = await _context.ProjectTasks.FindAsync(t2.TaskId);
        Assert.Equal(today.AddDays(-1), updatedT2!.StartDate); // unchanged
    }

    [Fact]
    public async Task DelayCascade_Idempotency_DoesNotShiftTwice()
    {
        var today = DateTime.UtcNow.Date;
        var t1 = await CreateTaskAsync("A", today.AddDays(-5), today.AddDays(-3), TaskStatus.InProgress); // 3 days delayed
        var t2 = await CreateTaskAsync("B", today.AddDays(-1), today.AddDays(1), TaskStatus.NotStarted);

        await AddDependencyAsync(t2.TaskId, t1.TaskId);

        // Run 1
        var result1 = await _delayService.RunDelayDetectionAsync();
        Assert.Equal(1, result1.DetectedTasks);
        Assert.Equal(1, result1.CascadeUpdatedTasks);

        var updatedT2 = await _context.ProjectTasks.FindAsync(t2.TaskId);
        Assert.Equal(today.AddDays(-1 + 3), updatedT2!.StartDate);

        // Run 2 (simulate running again immediately or on the same day)
        var result2 = await _delayService.RunDelayDetectionAsync();

        // T1 is already delayed, its DueDate is still past, but CascadedDelay = 3. 
        // NewDelayToCascade = TotalDelay(3) - CascadedDelay(3) = 0.
        // Detected tasks is 1 because it finds t1 as overdue (DueDate < today), but it doesn't cascade!
        Assert.Equal(1, result2.DetectedTasks);
        Assert.Equal(0, result2.CascadeUpdatedTasks);

        var updatedT2_run2 = await _context.ProjectTasks.FindAsync(t2.TaskId);
        Assert.Equal(today.AddDays(-1 + 3), updatedT2_run2!.StartDate); // unchanged
    }

    [Fact]
    public async Task DelayCascade_MultiplePaths_MaxDelayApplied()
    {
        var today = DateTime.UtcNow.Date;
        var t1 = await CreateTaskAsync("A", today.AddDays(-5), today.AddDays(-2), TaskStatus.InProgress); // 2 days delayed
        var t2 = await CreateTaskAsync("B", today.AddDays(-6), today.AddDays(-4), TaskStatus.InProgress); // 4 days delayed
        var t3 = await CreateTaskAsync("C", today.AddDays(-1), today.AddDays(1), TaskStatus.NotStarted);

        await AddDependencyAsync(t3.TaskId, t1.TaskId);
        await AddDependencyAsync(t3.TaskId, t2.TaskId);

        var result = await _delayService.RunDelayDetectionAsync();

        Assert.Equal(2, result.DetectedTasks);
        Assert.Equal(1, result.CascadeUpdatedTasks);

        var updatedT3 = await _context.ProjectTasks.FindAsync(t3.TaskId);
        Assert.Equal(today.AddDays(-1 + 4), updatedT3!.StartDate); // Shifted by 4 (max of 2 and 4)
    }

    [Fact]
    public async Task DelayCascade_DiamondGraph_NotDoubleApplied()
    {
        var today = DateTime.UtcNow.Date;
        var t1 = await CreateTaskAsync("A", today.AddDays(-5), today.AddDays(-3), TaskStatus.InProgress); // 3 days delayed
        var t2 = await CreateTaskAsync("B", today.AddDays(-1), today.AddDays(1), TaskStatus.NotStarted);
        var t3 = await CreateTaskAsync("C", today.AddDays(-1), today.AddDays(1), TaskStatus.NotStarted);
        var t4 = await CreateTaskAsync("D", today.AddDays(2), today.AddDays(4), TaskStatus.NotStarted);

        await AddDependencyAsync(t2.TaskId, t1.TaskId);
        await AddDependencyAsync(t3.TaskId, t1.TaskId);
        await AddDependencyAsync(t4.TaskId, t2.TaskId);
        await AddDependencyAsync(t4.TaskId, t3.TaskId);

        var result = await _delayService.RunDelayDetectionAsync();

        Assert.Equal(1, result.DetectedTasks);
        Assert.Equal(3, result.CascadeUpdatedTasks); // B, C, D

        var updatedT4 = await _context.ProjectTasks.FindAsync(t4.TaskId);
        Assert.Equal(today.AddDays(2 + 3), updatedT4!.StartDate); // Shifted by 3, NOT 6!
    }
}
