using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace StyleSync.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddProjectRequests : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ProjectRequests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Description = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    RoomType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    BudgetMin = table.Column<decimal>(type: "numeric(12,2)", nullable: true),
                    BudgetMax = table.Column<decimal>(type: "numeric(12,2)", nullable: true),
                    PreferredStartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PreferredEndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    StylePreferences = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    SpecialRequirements = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    AssignedDesignerId = table.Column<string>(type: "text", nullable: true),
                    RejectionReason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProjectRequests_Users_ClientId",
                        column: x => x.ClientId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ProjectRequests_ClientId",
                table: "ProjectRequests",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectRequests_CreatedAtUtc",
                table: "ProjectRequests",
                column: "CreatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectRequests_Status",
                table: "ProjectRequests",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ProjectRequests");
        }
    }
}
