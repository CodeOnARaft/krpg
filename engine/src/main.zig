const raylib = @import("raylib");
const types = @import("types");
const managers = @import("managers");

pub fn main() anyerror!void {
    raylib.initWindow(types.Constants.screenWidth, types.Constants.screenHeight, types.Constants.title);
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
