const std = @import("std");
const raylib = @import("raylib");
const shared = @import("shared");
const types = shared.types;
const managers = shared.managers;

pub fn main() anyerror!void {
    raylib.initWindow(types.Constants.screenWidth, types.Constants.screenHeight, std.mem.span(types.Constants.title));
    defer raylib.closeWindow();
    raylib.setExitKey(.f10);

    raylib.disableCursor();
    var gameManager = managers.GameManager{};
    try gameManager.initialize();

    while (!raylib.windowShouldClose() or gameManager.closeWindow) {
        try gameManager.update();

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        try gameManager.draw();
    }
}
