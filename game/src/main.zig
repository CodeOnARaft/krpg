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

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    while (!raylib.windowShouldClose() or gameManager.closeWindow) {
        defer _ = arena.reset(.retain_capacity);
        const frame_allocator = arena.allocator();

        try gameManager.update(frame_allocator);

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        try gameManager.draw(frame_allocator);
    }
}
