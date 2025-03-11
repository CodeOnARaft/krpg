const raylib = @import("raylib");
const raygui = @import("raygui");

pub var camera = raylib.Camera3D{
    .position = raylib.Vector3.init(20, 25, 20),
    .target = raylib.Vector3.init(30, 25, 30),
    .up = raylib.Vector3.init(0, 1, 0),
    .fovy = 60,
    .projection = .perspective,
};

pub fn main() anyerror!void {
    raylib.initWindow(1280, 720, "Editor");
    defer raylib.closeWindow();
    raylib.maximizeWindow();

    raygui.guiLoadStyle("resources/style_cyber.rgs");

    while (!raylib.windowShouldClose()) {
        camera.update(.free);
        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        {
            camera.begin();
            defer camera.end();

            raylib.drawGrid(100, 10);
        }
        drawMenu();
    }
}

fn drawMenu() void {
    const style = raygui.guiGetStyle(raygui.GuiControl.default, raygui.GuiDefaultProperty.background_color);
    raylib.drawRectangle(0, 0, 1280, 50, raylib.fade(raylib.getColor(@intCast(style)), 1));
}
