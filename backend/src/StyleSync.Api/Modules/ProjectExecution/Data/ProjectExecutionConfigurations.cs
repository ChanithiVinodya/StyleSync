using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StyleSync.Api.Modules.ProjectExecution.Models;

namespace StyleSync.Api.Modules.ProjectExecution.Data;

public class ProjectMilestoneConfiguration : IEntityTypeConfiguration<ProjectMilestone>
{
    public void Configure(EntityTypeBuilder<ProjectMilestone> builder)
    {
        builder.HasKey(m => m.MilestoneId);
        
        builder.Property(m => m.Name)
            .IsRequired()
            .HasMaxLength(200);

        // A project can have many milestones (Project entity might not be in the DbContext yet, so just map the FK)
        // If there was a Project entity, it would be builder.HasOne(p => p.Project).WithMany(p => p.Milestones).HasForeignKey(m => m.ProjectId);
        
        // Milestone to Tasks (One to Many)
        builder.HasMany(m => m.Tasks)
            .WithOne(t => t.Milestone)
            .HasForeignKey(t => t.MilestoneId)
            .OnDelete(DeleteBehavior.Cascade); // Deleting a milestone deletes its tasks

        // Milestone to Materials (One to Many, optional)
        builder.HasMany(m => m.Materials)
            .WithOne(mat => mat.Milestone)
            .HasForeignKey(mat => mat.MilestoneId)
            .OnDelete(DeleteBehavior.SetNull); // Deleting milestone keeps materials but clears the reference
            
        // Milestone to ProgressPhotos (One to Many, optional)
        builder.HasMany(m => m.ProgressPhotos)
            .WithOne(p => p.Milestone)
            .HasForeignKey(p => p.MilestoneId)
            .OnDelete(DeleteBehavior.SetNull); // Deleting milestone keeps photos but clears the reference
    }
}

public class ProjectTaskConfiguration : IEntityTypeConfiguration<ProjectTask>
{
    public void Configure(EntityTypeBuilder<ProjectTask> builder)
    {
        builder.HasKey(t => t.TaskId);
        
        builder.Property(t => t.Name)
            .IsRequired()
            .HasMaxLength(200);

        // Task to Dependencies (Many to Many self-referencing via TaskDependency)
        builder.HasMany(t => t.Prerequisites)
            .WithOne(d => d.Task)
            .HasForeignKey(d => d.TaskId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasMany(t => t.Dependents)
            .WithOne(d => d.PrerequisiteTask)
            .HasForeignKey(d => d.PrerequisiteTaskId)
            .OnDelete(DeleteBehavior.Restrict); // Avoid multiple cascade paths
    }
}

public class TaskDependencyConfiguration : IEntityTypeConfiguration<TaskDependency>
{
    public void Configure(EntityTypeBuilder<TaskDependency> builder)
    {
        builder.HasKey(d => d.TaskDependencyId);
        
        // Ensure unique dependency pairs
        builder.HasIndex(d => new { d.TaskId, d.PrerequisiteTaskId }).IsUnique();
    }
}

public class ProjectMaterialConfiguration : IEntityTypeConfiguration<ProjectMaterial>
{
    public void Configure(EntityTypeBuilder<ProjectMaterial> builder)
    {
        builder.HasKey(m => m.MaterialId);
        
        builder.Property(m => m.Name)
            .IsRequired()
            .HasMaxLength(200);
    }
}

public class ProgressPhotoConfiguration : IEntityTypeConfiguration<ProgressPhoto>
{
    public void Configure(EntityTypeBuilder<ProgressPhoto> builder)
    {
        builder.HasKey(p => p.ProgressPhotoId);
        
        builder.Property(p => p.ImageUrl)
            .IsRequired()
            .HasMaxLength(1000);
            
        // Photo to User
        builder.HasOne(p => p.Uploader)
            .WithMany()
            .HasForeignKey(p => p.UploadedBy)
            .OnDelete(DeleteBehavior.Restrict); // Do not delete users when photos are deleted, and vice versa
    }
}
