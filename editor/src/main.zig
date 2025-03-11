const raylib = @import("raylib");
const raygui = @import("raygui");

pub fn main() anyerror!void {
    raylib.initWindow(1280, 720, "Editor");
    defer raylib.closeWindow();
    var showMessageBox: bool = false;
    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        if (raygui.guiButton(raylib.Rectangle{ .x = 24, .y = 24, .width = 120, .height = 30 }, "#191#Show Message") > 0) {
            showMessageBox = true;
        }

        var result: i32 = -1;
        if (showMessageBox) {
            result = raygui.guiMessageBox(raylib.Rectangle{ .x = 85, .y = 70, .width = 250, .height = 100 }, "#191#Message Box", "Hi! This is a message!", "Nice;Cool");

            if (result >= 0) showMessageBox = false;
        }
    }
}
