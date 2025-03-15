const std = @import("std");
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

    scrollDirectoriesV2: raylib.Vector2 = raylib.Vector2{ .x = 0, .y = 0 },
    scrollFilesV2: raylib.Vector2 = raylib.Vector2{ .x = 0, .y = 0 },

    pub fn init(self: *OpenFileDialog, editor: *EditorWindow) !void {
        self.editor = editor;
        self.open = false;
        self.file = undefined;
        self.cwd = shared.settings.gameSettings.resourceDirectory;

        const x = (ui.Constants.WINDOW_WIDTHf - ui.Constants.OFD_WIDTHf) / 2;
        const y = (ui.Constants.WINDOW_HEIGHTf - ui.Constants.OFD_HEIGHTf) / 2;
        self.location = raylib.Rectangle{ .x = x, .y = y, .width = ui.Constants.OFD_WIDTHf, .height = ui.Constants.OFD_HEIGHTf };

        const cwd = std.fs.cwd();
        self.currentDirectory = try cwd.openDir(shared.settings.gameSettings.resourceDirectory, std.fs.Dir.OpenOptions{ .iterate = true });

        try self.setDirectoryText();
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

    pub fn drawDirectories(self: *OpenFileDialog) !void {
        const width = ui.Constants.OFD_WIDTHf * 0.4;
        var rec2 = raylib.Rectangle{ .x = self.location.x + 10.0, .y = self.location.y + 50.0, .height = self.location.height - 60.0, .width = width };

        if (raygui.guiScrollPanel(rec2, "Scene", rec2, &self.scrollDirectoriesV2, &rec2) > 0) {}

        var iter = self.currentDirectory.iterate();
        var yy: f32 = 20;
        while (try iter.next()) |entry| {
            if (entry.kind == .directory) {
                //std.debug.print("File {s} ({})\n", .{ entry.name, entry.kind });
                const fileLocation = raylib.Rectangle{ .x = self.location.x + 10, .y = self.location.y + 50 + yy, .width = width, .height = 20 };

                const buffer = try allocator.allocSentinel(u8, entry.name.len, 0);
                std.mem.copyForwards(u8, buffer[0..entry.name.len], entry.name);

                if (raygui.guiButton(fileLocation, buffer) > 0) {}
                allocator.free(buffer);
                yy = yy + 20;
            }
        }
    }

    pub fn drawFiles(self: *OpenFileDialog) !void {
        const xwidth = ui.Constants.OFD_WIDTHf * 0.4;
        const width = ui.Constants.OFD_WIDTHf - 20 - xwidth;
        var rec2 = raylib.Rectangle{ .x = self.location.x + 10 + xwidth, .y = self.location.y + 50.0, .height = self.location.height - 60.0, .width = width };
        if (raygui.guiScrollPanel(rec2, "Scene", rec2, &self.scrollDirectoriesV2, &rec2) > 0) {}

        var iter = self.currentDirectory.iterate();
        var yy: f32 = 20;
        while (try iter.next()) |entry| {
            //std.debug.print("File {s} ({})\n", .{ entry.name, entry.kind });
            if (entry.kind == .file) {
                const fileLocation = raylib.Rectangle{ .x = self.location.x + 10 + xwidth, .y = self.location.y + 50 + yy, .width = width, .height = 20 };

                const buffer = try allocator.allocSentinel(u8, entry.name.len, 0);
                std.mem.copyForwards(u8, buffer[0..entry.name.len], entry.name);

                if (raygui.guiButton(fileLocation, buffer) > 0) {}
                allocator.free(buffer);
                yy = yy + 20;
            }
        }
    }
};
