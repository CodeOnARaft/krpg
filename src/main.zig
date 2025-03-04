const raylib = @import("raylib");
const settings = @import("settings");
const managers = @import("managers");

pub fn main() anyerror!void {
    raylib.initWindow(settings.screenWidth, settings.screenHeight, "krpg");
    defer raylib.closeWindow();

    raylib.disableCursor();
    var gameManager = managers.GameManager{};
    try gameManager.initialize();

    while (!raylib.windowShouldClose() or gameManager.closeWindow) {
        gameManager.update();

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        gameManager.draw();
    }
}
