const std = @import("std");
const ArrayList = std.ArrayList;
const raylib = @import("raylib");
const raygui = @import("raygui");
const ui = @import("../_ui.zig");
const shared = @import("shared");
const EditorWindow = @import("../../editor.zig").EditorWindow;

const allocator = std.heap.c_allocator;
pub const OpenFileDialog = struct {
    open: bool = false,
    file: []const u8 = undefined,
    cwd: []const u8 = undefined,
    location: raylib.Rectangle = undefined,
    editor: *EditorWindow = undefined,
    currentDirectory: std.fs.Dir = undefined,
    currentDirectoryName: [:0]const u8 = undefined,
    currentDirectoryFileCount: f32 = 0,
    currentDirectoryDirCount: f32 = 0,
    dblClickTime: f32 = 0.0,

    scrollDirectoriesV2: raylib.Vector2 = raylib.Vector2{ .x = 0, .y = 0 },
    scrollFilesV2: raylib.Vector2 = raylib.Vector2{ .x = 0, .y = 0 },

    callBackFunction: *const fn (*OpenFileDialog, []const u8) anyerror!void = undefined,

    pub fn init(self: *OpenFileDialog, editor: *EditorWindow) !void {
        self.editor = editor;
        self.open = false;
        self.file = undefined;
        self.cwd = shared.settings.gameSettings.resourceDirectory;

        const x = (ui.Constants.WINDOW_WIDTHf - ui.Constants.OFD_WIDTHf) / 2;
        const y = (ui.Constants.WINDOW_HEIGHTf - ui.Constants.OFD_HEIGHTf) / 2;
        self.location = raylib.Rectangle{ .x = x, .y = y, .width = ui.Constants.OFD_WIDTHf, .height = ui.Constants.OFD_HEIGHTf };

        self.currentDirectory = std.fs.cwd();
        try self.changeSubDirectory(shared.settings.gameSettings.resourceDirectory);
    }

    pub fn openDialog(self: *OpenFileDialog, callBackFunction: *const fn (*OpenFileDialog, []const u8) anyerror!void) !void {
        self.open = true;
        self.callBackFunction = callBackFunction;
    }

    pub fn setDirectoryText(self: *OpenFileDialog) !void {
        if (self.currentDirectoryName.len > 1) {
            allocator.free(self.currentDirectoryName);
        }
        var buf: [std.fs.max_path_bytes]u8 = undefined;
        const fs_cwd = try self.currentDirectory.realpath(".", &buf);

        const buffer = try allocator.allocSentinel(u8, fs_cwd.len, 0);
        std.mem.copyForwards(u8, buffer[0..fs_cwd.len], fs_cwd);
        self.currentDirectoryName = buffer;
    }

    pub fn update(self: *OpenFileDialog) !bool {
        var handled = false;
        if (!self.open) {
            return handled;
        }

        handled = true;

        self.dblClickTime += raylib.getFrameTime();
        return handled;
    }

    pub fn draw(self: *OpenFileDialog) !void {
        if (!self.open) {
            return;
        }

        // black background
        raylib.drawRectangleRec(raylib.Rectangle{ .x = 0, .y = 0, .width = ui.Constants.WINDOW_WIDTHf, .height = ui.Constants.WINDOW_HEIGHTf }, raylib.Color{ .r = 0, .g = 0, .b = 0, .a = 200 });

        const title = "Open File";
        const windowValue = raygui.guiWindowBox(self.location, title);

        const directoryLabelLocation = raylib.Rectangle{ .x = self.location.x + 10, .y = self.location.y + 25, .width = ui.Constants.OFD_WIDTHf - 20, .height = 20 };
        _ = raygui.guiLabel(directoryLabelLocation, self.currentDirectoryName);

        try self.drawDirectories();
        try self.drawFiles();

        if (windowValue != 0) {
            std.debug.print("Open File Dialog Closed {}\n", .{windowValue});
            self.open = false;
            self.editor.module = false;
        }
    }
    fn changeSubDirectory(self: *OpenFileDialog, name: []const u8) !void {
        self.currentDirectory = try self.currentDirectory.openDir(name, std.fs.Dir.OpenOptions{ .iterate = true });
        try self.setDirectoryText();

        self.currentDirectoryFileCount = 0;
        self.currentDirectoryDirCount = 1;

        var iter = self.currentDirectory.iterate();

        while (try iter.next()) |entry| {
            if (entry.kind == .file) {
                self.currentDirectoryFileCount += 1;
            } else if (entry.kind == .directory) {
                self.currentDirectoryDirCount += 1;
            }
        }
    }
    pub fn drawDirectories(self: *OpenFileDialog) !void {
        const mousePos = raylib.getMousePosition();
        const width = ui.Constants.OFD_WIDTHf * 0.4;
        var rec2 = raylib.Rectangle{ .x = self.location.x + 10.0, .y = self.location.y + 50.0, .height = self.location.height - 60.0, .width = width };

        const contentHeight: f32 = self.currentDirectoryDirCount * 20;
        const contentRec = raylib.Rectangle{ .x = self.location.x + 10.0, .y = self.location.y + 50.0, .height = contentHeight, .width = width };
        if (raygui.guiScrollPanel(rec2, "Directories", contentRec, &self.scrollDirectoriesV2, &rec2) > 0) {
            std.debug.print("Scrolling {}\n", .{self.scrollDirectoriesV2.y});
        }

        raylib.beginScissorMode(@as(i32, @intFromFloat(rec2.x)), @as(i32, @intFromFloat(rec2.y)), @as(i32, @intFromFloat(rec2.width)), @as(i32, @intFromFloat(rec2.height)));

        var iter = self.currentDirectory.iterate();
        var yy: f32 = 40 + self.scrollDirectoriesV2.y;
        const directoryX = self.location.x + 15;

        var location = raylib.Rectangle{ .x = directoryX, .y = self.location.y + 75 + self.scrollDirectoriesV2.y, .width = width, .height = 20 };
        _ = raygui.guiLabel(location, "..");
        if (raylib.checkCollisionPointRec(mousePos, rec2) and self.testDoubleClick(location)) {
            try self.changeSubDirectory("..");
        }

        while (try iter.next()) |entry| {
            if (entry.kind == .directory) {
                location = raylib.Rectangle{ .x = directoryX, .y = self.location.y + 55 + yy, .width = width, .height = 20 };

                const buffer = try allocator.allocSentinel(u8, entry.name.len, 0);
                std.mem.copyForwards(u8, buffer[0..entry.name.len], entry.name);

                if (raylib.checkCollisionPointRec(mousePos, rec2) and self.testDoubleClick(location)) {
                    try self.changeSubDirectory(entry.name);
                }

                if (raygui.guiLabel(location, buffer) > 0) {}
                allocator.free(buffer);
                yy = yy + 20;
            }
        }

        raylib.endScissorMode();
    }

    pub fn drawFiles(self: *OpenFileDialog) !void {
        const mousePos = raylib.getMousePosition();
        const xwidth = ui.Constants.OFD_WIDTHf * 0.4;
        const width = ui.Constants.OFD_WIDTHf - 20 - xwidth;
        const contentHeight: f32 = self.currentDirectoryFileCount * 20;
        const contentRec = raylib.Rectangle{ .x = self.location.x + 20 + xwidth, .y = self.location.y + 50.0, .height = contentHeight, .width = width };
        var rec2 = raylib.Rectangle{ .x = self.location.x + 20 + xwidth, .y = self.location.y + 50.0, .height = self.location.height - 60.0, .width = width };
        if (raygui.guiScrollPanel(rec2, "Files", contentRec, &self.scrollFilesV2, &rec2) > 0) {}

        var iter = self.currentDirectory.iterate();
        var yy: f32 = 20 + self.scrollFilesV2.y;
        const fileX = self.location.x + 25 + xwidth;

        raylib.beginScissorMode(@as(i32, @intFromFloat(rec2.x)), @as(i32, @intFromFloat(rec2.y)), @as(i32, @intFromFloat(rec2.width)), @as(i32, @intFromFloat(rec2.height)));

        while (try iter.next()) |entry| {
            //std.debug.print("File {s} ({})\n", .{ entry.name, entry.kind });
            if (entry.kind == .file) {
                const fileLocation = raylib.Rectangle{ .x = fileX, .y = self.location.y + 55 + yy, .width = width, .height = 20 };

                const buffer = try allocator.allocSentinel(u8, entry.name.len, 0);
                std.mem.copyForwards(u8, buffer[0..entry.name.len], entry.name);

                if (raylib.checkCollisionPointRec(mousePos, rec2) and self.testDoubleClick(fileLocation)) {
                    // const buffer2 = try allocator.allocSentinel(u8, entry.name.len + self.currentDirectoryName.len + 1, 0);
                    // std.mem.copyForwards(u8, buffer2[0..self.currentDirectoryName.len], self.currentDirectoryName);
                    // buffer2[self.currentDirectoryName.len] = '/';
                    // std.mem.copyForwards(u8, buffer2[self.currentDirectoryName.len + 1 ..], entry.name);

                    var parts: ArrayList([]const u8) = ArrayList([]const u8).init(std.heap.page_allocator);
                    var it = std.mem.splitScalar(u8, entry.name, '.');

                    while (it.next()) |commandPart| {
                        try parts.append(commandPart);
                    }

                    try (self.callBackFunction)(self, parts.items[0]);
                    self.open = false;
                    //allocator.free(buffer2);
                }

                if (raygui.guiLabel(fileLocation, buffer) > 0) {}
                allocator.free(buffer);
                yy = yy + 20;
            }
        }

        raylib.endScissorMode();
    }

    pub fn testDoubleClick(self: *OpenFileDialog, rec: raylib.Rectangle) bool {
        if (!raylib.isMouseButtonReleased(.left)) {
            return false;
        }

        if (!raylib.checkCollisionPointRec(raylib.getMousePosition(), rec)) {
            return false;
        }

        const testd = self.dblClickTime > 0.5;
        self.dblClickTime = 0.0;

        if (testd) {
            return false;
        }

        return true;
    }
};
