using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StyleSync.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPreferredDesignerId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "PreferredDesignerId",
                table: "ProjectRequests",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProjectRequests_PreferredDesignerId",
                table: "ProjectRequests",
                column: "PreferredDesignerId");

            migrationBuilder.AddForeignKey(
                name: "FK_ProjectRequests_Users_PreferredDesignerId",
                table: "ProjectRequests",
                column: "PreferredDesignerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProjectRequests_Users_PreferredDesignerId",
                table: "ProjectRequests");

            migrationBuilder.DropIndex(
                name: "IX_ProjectRequests_PreferredDesignerId",
                table: "ProjectRequests");

            migrationBuilder.DropColumn(
                name: "PreferredDesignerId",
                table: "ProjectRequests");
        }
    }
}
