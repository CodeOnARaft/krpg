const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Editor = @import("editor.zig");

pub fn main() anyerror!void {
    raylib.initWindow(1280, 720, "krpg Editor");
    defer raylib.closeWindow();

    raylib.setExitKey(.f10);
    // raylib.toggleFullscreen();
    raygui.guiLoadStyle("resources/style_cyber.rgs");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var editor = Editor.EditorWindow{};
    try editor.init();

    while (!raylib.windowShouldClose()) {
        defer _ = arena.reset(.retain_capacity);

        try editor.update(arena.allocator());
        try editor.draw(arena.allocator());
    }
}
