const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const map = @import("map");
const settings = @import("settings");
const types = @import("types");
const managers = @import("managers");

pub fn main() anyerror!void {
    raylib.initWindow(settings.screenWidth, settings.screenHeight, "krpg");
    defer raylib.closeWindow(); // Close window and OpenGL context

    raylib.disableCursor();
    var gameManager = managers.GameManager{};
    try gameManager.initialize();

    while (!raylib.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------

        gameManager.update();

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        {
            gameManager.draw();
        }

        gameManager.drawUI();

        //----------------------------------------------------------------------------------
    }
}
