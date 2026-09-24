using System;
using System.Collections.Generic;
using StyleSync.Api.Modules.ProjectExecution.DTOs;

namespace StyleSync.Api.Modules.ProjectExecution.Exceptions;

public class DependencyGuardException : Exception
{
    public Guid TaskId { get; }
    public IEnumerable<TaskDependencyTaskDto> IncompletePrerequisites { get; }

    public DependencyGuardException(Guid taskId, IEnumerable<TaskDependencyTaskDto> incompletePrerequisites)
        : base("Task cannot start because prerequisite tasks are incomplete.")
    {
        TaskId = taskId;
        IncompletePrerequisites = incompletePrerequisites;
    }
}
