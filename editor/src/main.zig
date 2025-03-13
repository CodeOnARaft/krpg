const raylib = @import("raylib");
const raygui = @import("raygui");
const Editor = @import("editor.zig");

pub fn main() anyerror!void {
    raylib.initWindow(1280, 720, "krpg Editor");
    defer raylib.closeWindow();

    raylib.setExitKey(.null);

    raygui.guiLoadStyle("resources/style_cyber.rgs");

    var editor = Editor.Editor{};
    editor.init();

    while (!raylib.windowShouldClose()) {
        try editor.update();
        editor.draw();
    }
}
