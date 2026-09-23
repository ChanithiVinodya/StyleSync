using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StyleSync.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddQuotesAndContracts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Quotes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectRequestId = table.Column<Guid>(type: "uuid", nullable: false),
                    DesignerId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    IsAiGenerated = table.Column<bool>(type: "boolean", nullable: false),
                    ScopeSummary = table.Column<string>(type: "text", nullable: true),
                    TotalCost = table.Column<decimal>(type: "numeric(12,2)", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Quotes", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Contracts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    QuoteId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectRequestId = table.Column<Guid>(type: "uuid", nullable: false),
                    DesignerId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    TotalAmount = table.Column<decimal>(type: "numeric(12,2)", nullable: false),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    SignedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    TermsSummary = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Contracts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Contracts_Quotes_QuoteId",
                        column: x => x.QuoteId,
                        principalTable: "Quotes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "QuoteItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    QuoteId = table.Column<Guid>(type: "uuid", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    UnitCost = table.Column<decimal>(type: "numeric(12,2)", nullable: false),
                    LineTotal = table.Column<decimal>(type: "numeric(12,2)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_QuoteItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_QuoteItems_Quotes_QuoteId",
                        column: x => x.QuoteId,
                        principalTable: "Quotes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Contracts_ClientId",
                table: "Contracts",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_Contracts_DesignerId",
                table: "Contracts",
                column: "DesignerId");

            migrationBuilder.CreateIndex(
                name: "IX_Contracts_ProjectRequestId",
                table: "Contracts",
                column: "ProjectRequestId");

            migrationBuilder.CreateIndex(
                name: "IX_Contracts_QuoteId",
                table: "Contracts",
                column: "QuoteId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Contracts_Status",
                table: "Contracts",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_QuoteItems_QuoteId",
                table: "QuoteItems",
                column: "QuoteId");

            migrationBuilder.CreateIndex(
                name: "IX_Quotes_DesignerId",
                table: "Quotes",
                column: "DesignerId");

            migrationBuilder.CreateIndex(
                name: "IX_Quotes_ProjectRequestId",
                table: "Quotes",
                column: "ProjectRequestId");

            migrationBuilder.CreateIndex(
                name: "IX_Quotes_Status",
                table: "Quotes",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Contracts");

            migrationBuilder.DropTable(
                name: "QuoteItems");

            migrationBuilder.DropTable(
                name: "Quotes");
        }
    }
}
