const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Constants = @import("Constants.zig");

pub const SceneWindow = struct {
    windowLocation: raylib.Rectangle = undefined,

    pub fn init(self: *SceneWindow) void {
        self.windowLocation = raylib.Rectangle{ .x = 0, .y = Constants.MenuHeight, .height = @as(f32, @floatFromInt(raylib.getScreenHeight())) - Constants.MenuHeightf, .width = Constants.SceneWidth };
    }

    pub fn update(self: *SceneWindow) bool {
        const mouse = raylib.getMousePosition();

        return raylib.checkCollisionPointRec(mouse, self.windowLocation);
    }

    pub fn draw(self: *SceneWindow) void {
        //  const style = raygui.guiGetStyle(raygui.GuiControl.default, raygui.GuiDefaultProperty.background_color);
        // const color = raylib.fade(raylib.getColor(@intCast(style)), 1);
        //    raylib.drawRectangle(0, Constants.MenuHeight, Constants.SceneWidth, @intFromFloat(self.windowLocation.height), color);
        var vec2 = raylib.Vector2{ .x = 0, .y = 0 };
        var rec2 = raylib.Rectangle{ .x = self.windowLocation.x + 5.0, .y = self.windowLocation.y + 5.0, .height = self.windowLocation.height - 10.0, .width = self.windowLocation.width - 10.0 };
        if (raygui.guiScrollPanel(self.windowLocation, "Scene", rec2, &vec2, &rec2) > 0) {}
        // const openIcon = @intFromEnum(raygui.GuiIconName.icon_file_open);
        // raygui.guiDrawIcon(openIcon, 5, 5, 1, raylib.Color.gray);
    }
};
