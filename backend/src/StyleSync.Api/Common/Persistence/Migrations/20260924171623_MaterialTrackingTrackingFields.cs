using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StyleSync.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class MaterialTrackingTrackingFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ExpectedDeliveryDate",
                table: "ProjectMaterials",
                newName: "RequiredDate");

            migrationBuilder.AddColumn<DateTime>(
                name: "DeliveredDate",
                table: "ProjectMaterials",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "ProjectMaterials",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "OrderedDate",
                table: "ProjectMaterials",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "TaskId",
                table: "ProjectMaterials",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Unit",
                table: "ProjectMaterials",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectMaterials_TaskId",
                table: "ProjectMaterials",
                column: "TaskId");

            migrationBuilder.AddForeignKey(
                name: "FK_ProjectMaterials_ProjectTasks_TaskId",
                table: "ProjectMaterials",
                column: "TaskId",
                principalTable: "ProjectTasks",
                principalColumn: "TaskId",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProjectMaterials_ProjectTasks_TaskId",
                table: "ProjectMaterials");

            migrationBuilder.DropIndex(
                name: "IX_ProjectMaterials_TaskId",
                table: "ProjectMaterials");

            migrationBuilder.DropColumn(
                name: "DeliveredDate",
                table: "ProjectMaterials");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "ProjectMaterials");

            migrationBuilder.DropColumn(
                name: "OrderedDate",
                table: "ProjectMaterials");

            migrationBuilder.DropColumn(
                name: "TaskId",
                table: "ProjectMaterials");

            migrationBuilder.DropColumn(
                name: "Unit",
                table: "ProjectMaterials");

            migrationBuilder.RenameColumn(
                name: "RequiredDate",
                table: "ProjectMaterials",
                newName: "ExpectedDeliveryDate");
        }
    }
}
