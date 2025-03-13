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

var openFile = true;
fn drawMenu() void {
    const style = raygui.guiGetStyle(raygui.GuiControl.default, raygui.GuiDefaultProperty.background_color);
    raylib.drawRectangle(0, 0, 1280, 25, raylib.fade(raylib.getColor(@intCast(style)), 1));

    const openIcon = @intFromEnum(raygui.GuiIconName.icon_file_open);
    raygui.guiDrawIcon(openIcon, 5, 5, 1, raylib.Color.gray);

    if (openFile) {
        if (raygui.guiWindowBox(raylib.Rectangle{ .x = 100, .y = 100, .height = 150, .width = 200 }, "Open Scene") != 0) {
            openFile = false;
        }
    }
}
