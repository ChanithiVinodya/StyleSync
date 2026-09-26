using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StyleSync.Api.Modules.ProjectExecution.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddProgressPhotoTimelineFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ContentType",
                table: "ProgressPhotos",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "FileName",
                table: "ProgressPhotos",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<long>(
                name: "FileSize",
                table: "ProgressPhotos",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<Guid>(
                name: "TaskId",
                table: "ProgressPhotos",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProgressPhotos_TaskId",
                table: "ProgressPhotos",
                column: "TaskId");

            migrationBuilder.AddForeignKey(
                name: "FK_ProgressPhotos_ProjectTasks_TaskId",
                table: "ProgressPhotos",
                column: "TaskId",
                principalTable: "ProjectTasks",
                principalColumn: "TaskId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProgressPhotos_ProjectTasks_TaskId",
                table: "ProgressPhotos");

            migrationBuilder.DropIndex(
                name: "IX_ProgressPhotos_TaskId",
                table: "ProgressPhotos");

            migrationBuilder.DropColumn(
                name: "ContentType",
                table: "ProgressPhotos");

            migrationBuilder.DropColumn(
                name: "FileName",
                table: "ProgressPhotos");

            migrationBuilder.DropColumn(
                name: "FileSize",
                table: "ProgressPhotos");

            migrationBuilder.DropColumn(
                name: "TaskId",
                table: "ProgressPhotos");
        }
    }
}
