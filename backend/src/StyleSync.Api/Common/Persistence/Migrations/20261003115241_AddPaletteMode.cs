using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StyleSync.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPaletteMode : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DELETE FROM \"SuggestedPalettes\";");

            migrationBuilder.AddColumn<string>(
                name: "PaletteBaseHex",
                table: "ProjectRequests",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaletteMode",
                table: "ProjectRequests",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PalettePresetId",
                table: "ProjectRequests",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PaletteBaseHex",
                table: "ProjectRequests");

            migrationBuilder.DropColumn(
                name: "PaletteMode",
                table: "ProjectRequests");

            migrationBuilder.DropColumn(
                name: "PalettePresetId",
                table: "ProjectRequests");
        }
    }
}
