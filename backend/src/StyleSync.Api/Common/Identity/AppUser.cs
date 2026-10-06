namespace StyleSync.Api.Common.Identity;

public enum UserRole
{
    Admin = 0,
    Designer = 1,
    Client = 2,
    ProjectManager = 3,
    Administrator = 0
}

public class AppUser
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = default!;
    
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public string FullName
    {
        get => Name;
        set => Name = value;
    }

    public string Email { get; set; } = default!;
    public string PasswordHash { get; set; } = default!;
    public UserRole Role { get; set; } = UserRole.Client;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
