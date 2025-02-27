const gui = @import("raygui");
const raylib = @import("raylib");
const settings = @import("settings");
const std = @import("std");

pub fn drawConsole() void {
    if (settings.gameSettings.consoleOpen) {
        std.debug.print("updating game settings {}\n", .{settings.gameSettings.consoleOpen});
        const panelRec: raylib.Rectangle = raylib.Rectangle{ .x = 20, .y = 40, .width = 200, .height = 150 };
        const panelContentRec: raylib.Rectangle = raylib.Rectangle{ .x = 0, .y = 0, .width = 340, .height = 340 };
        var panelView: raylib.Rectangle = raylib.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 };
        var panelScroll: raylib.Vector2 = raylib.Vector2{ .x = 99, .y = -20 };

        _ = gui.guiScrollPanel(panelRec, null, panelContentRec, &panelScroll, &panelView);
    }
}
