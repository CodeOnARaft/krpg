const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Constants = @import("Constants.zig");
const edW = @import("../editor.zig");

pub const PropertiesWindow = struct {
    windowLocation: raylib.Rectangle = undefined,
    editor: *edW.EditorWindow = undefined,

    pub fn init(self: *PropertiesWindow, editor: *edW.EditorWindow) void {
        self.editor = editor;
        self.windowLocation = raylib.Rectangle{ .x = @as(f32, @floatFromInt(raylib.getScreenWidth())) - Constants.SceneWidthf32, .y = Constants.MenuHeight, .height = @as(f32, @floatFromInt(raylib.getScreenHeight())) - Constants.MenuHeightf, .width = Constants.SceneWidth };
    }

    pub fn update(self: *PropertiesWindow) bool {
        const mouse = raylib.getMousePosition();

        return raylib.checkCollisionPointRec(mouse, self.windowLocation);
    }

    pub fn draw(self: *PropertiesWindow) !void {
        var vec2 = raylib.Vector2{ .x = 0, .y = 0 };
        var rec2 = raylib.Rectangle{ .x = self.windowLocation.x + 5.0, .y = self.windowLocation.y + 5.0, .height = self.windowLocation.height - 10.0, .width = self.windowLocation.width - 10.0 };
        if (raygui.guiScrollPanel(self.windowLocation, "Properties", rec2, &vec2, &rec2) > 0) {}

        const position = raylib.Rectangle{ .x = vec2.x + rec2.x, .y = vec2.y + rec2.y, .width = rec2.width, .height = rec2.height };
        if (self.editor.objectSelected) {
            try self.editor.selectedObject.drawProperties(position);
        }
    }
};
