const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Constants = @import("Constants.zig");
const EditorWindow = @import("../editor.zig").EditorWindow;

pub const Menu = struct {
    menuLocation: raylib.Rectangle = undefined,
    editor: *EditorWindow = undefined,

    pub fn init(self: *Menu, currentEditor: *EditorWindow) void {
        self.menuLocation = raylib.Rectangle{ .x = 0, .y = 0, .height = Constants.MenuHeight, .width = 1280 };
        self.editor = currentEditor;
    }

    pub fn update(self: *Menu) bool {
        const mouse = raylib.getMousePosition();
        if (raylib.isMouseButtonReleased(.left) and raylib.checkCollisionPointRec(mouse, raylib.Rectangle{ .x = 5, .y = 5, .height = 16, .width = 16 })) {
            try self.editor.openFile();
            return true;
        }

        return raylib.checkCollisionPointRec(mouse, self.menuLocation);
    }

    pub fn draw(self: *Menu) void {
        const style = raygui.guiGetStyle(raygui.GuiControl.default, raygui.GuiDefaultProperty.background_color);
        const color = raylib.fade(raylib.getColor(@intCast(style)), 1);
        raylib.drawRectangle(@intFromFloat(self.menuLocation.x), @intFromFloat(self.menuLocation.y), @intFromFloat(self.menuLocation.width), Constants.MenuHeight, color);

        const openIcon = @intFromEnum(raygui.GuiIconName.icon_file_open);
        raygui.guiDrawIcon(openIcon, 5, 5, 1, raylib.Color.gray);
    }
};
