const raylib = @import("raylib");
const raygui = @import("raygui");
const Editor = @import("editor.zig");

pub fn main() anyerror!void {
    raylib.initWindow(1280, 720, "krpg Editor");
    defer raylib.closeWindow();

    raylib.setExitKey(.f10);
    // raylib.toggleFullscreen();
    raygui.guiLoadStyle("resources/style_cyber.rgs");

    var editor = Editor.EditorWindow{};
    try editor.init();

    while (!raylib.windowShouldClose()) {
        try editor.update();
        try editor.draw();
    }
}
