using System;
using System.Collections.Generic;
using StyleSync.Api.Modules.ProjectExecution.DTOs;

namespace StyleSync.Api.Modules.ProjectExecution.Exceptions;

public class MaterialCompletionGuardException : Exception
{
    public Guid MilestoneId { get; }
    public IEnumerable<IncompleteMaterialDto> IncompleteMaterials { get; }

    public MaterialCompletionGuardException(Guid milestoneId, IEnumerable<IncompleteMaterialDto> incompleteMaterials)
        : base("Milestone cannot be completed because required materials have not been delivered.")
    {
        MilestoneId = milestoneId;
        IncompleteMaterials = incompleteMaterials;
    }
}
