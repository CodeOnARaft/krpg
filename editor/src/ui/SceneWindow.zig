const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Constants = @import("Constants.zig");

pub const SceneWindow = struct {
    windowLocation: raylib.Rectangle = undefined,
    ddActive: i32 = 0,
    ddEditMode: bool = false,

    pub fn init(self: *SceneWindow) void {
        self.windowLocation = raylib.Rectangle{ .x = 0, .y = Constants.MenuHeight, .height = @as(f32, @floatFromInt(raylib.getScreenHeight())) - Constants.MenuHeightf, .width = Constants.SceneWidth };
    }

    pub fn update(self: *SceneWindow) bool {
        const mouse = raylib.getMousePosition();

        return raylib.checkCollisionPointRec(mouse, self.windowLocation);
    }

    pub fn draw(self: *SceneWindow) void {
        var vec2 = raylib.Vector2{ .x = 0, .y = 0 };
        var rec2 = raylib.Rectangle{ .x = self.windowLocation.x + 5.0, .y = self.windowLocation.y + 5.0, .height = self.windowLocation.height - 10.0, .width = self.windowLocation.width - 10.0 };
        if (raygui.guiScrollPanel(self.windowLocation, "Scene", rec2, &vec2, &rec2) > 0) {}

        const ddBounds = raylib.Rectangle{ .x = self.windowLocation.x + 10, .y = self.windowLocation.y + 30, .height = 20, .width = self.windowLocation.width - 30.0 };
        const ddValue = raygui.guiDropdownBox(ddBounds, "Objects;NPCs;Triggers", &self.ddActive, self.ddEditMode);
        if (ddValue > 0) {
            self.ddEditMode = !self.ddEditMode;
            std.debug.print("Dropdown value: {}\n", .{ddValue});
            std.debug.print("Dropdown active: {}\n", .{self.ddActive});
            std.debug.print("Dropdown edit mode: {}\n", .{self.ddEditMode});
        }
    }
};
