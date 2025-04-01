const std = @import("std");
const ArrayList = std.ArrayList;
const raylib = @import("raylib");
const raygui = @import("raygui");
const ui = @import("../_ui.zig");
const shared = @import("shared");
const EditorWindow = @import("../../editor.zig").EditorWindow;

pub const MessageBoxType = enum {
    Info,
    Warning,
    Error,
    Confirm,
};

pub const MessageBox = struct {
    open: bool = false,
    title: []const u8 = undefined,
    message: []const u8 = undefined,
    location: raylib.Rectangle = undefined,
    editor: *EditorWindow = undefined,
    callBackFunction: *const fn (*MessageBox, result: i32) anyerror!void = undefined,
    type: MessageBoxType = MessageBoxType.Info,

    pub fn openDialog(self: *MessageBox, title: []const u8, message: []const u8, boxType: MessageBoxType, callBackFunction: *const fn (*MessageBox, i32) anyerror!void) !void {
        self.open = true;
        self.callBackFunction = callBackFunction;
        self.title = title;
        self.message = message;
        self.type = boxType;
    }

    pub fn init(self: *MessageBox, editor: *EditorWindow) !void {
        const x = (ui.Constants.WINDOW_WIDTHf - ui.Constants.MB_WIDTHf) / 2;
        const y = (ui.Constants.WINDOW_HEIGHTf - ui.Constants.MB_HEIGHTf) / 2;

        self.editor = editor;
        self.open = false;
        self.title = "Message Box";
        self.message = "Message";
        self.location = raylib.Rectangle{ .x = x, .y = y, .width = ui.Constants.MB_WIDTHf, .height = ui.Constants.MB_HEIGHTf };
    }

    pub fn draw(self: *MessageBox) !void {
        const allocator = std.heap.page_allocator;
        if (!self.open) {
            return;
        }

        raylib.drawRectangle(
            @intFromFloat(self.location.x),
            @intFromFloat(self.location.y),
            @intFromFloat(self.location.width),
            26,
            raylib.Color.dark_green,
        );
        raylib.drawRectangle(
            @intFromFloat(self.location.x),
            @intFromFloat(self.location.y + 26),
            @intFromFloat(self.location.width),
            @intFromFloat(self.location.height - 26),
            raylib.Color.black,
        );

        raylib.drawRectangleLines(@intFromFloat(self.location.x), @intFromFloat(self.location.y), @intFromFloat(self.location.width), @intFromFloat(self.location.height), raylib.Color.green);

        const buffer = try allocator.allocSentinel(u8, self.title.len, 0);
        std.mem.copyForwards(u8, buffer[0..self.title.len], self.title);
        raylib.drawText(buffer, @intFromFloat(self.location.x + 10), @intFromFloat(self.location.y + 5), 16, raylib.Color.white);
        allocator.free(buffer);

        const buffer2 = try allocator.allocSentinel(u8, self.message.len, 0);
        std.mem.copyForwards(u8, buffer2[0..self.message.len], self.message);
        raylib.drawText(buffer2, @intFromFloat(self.location.x + 10), @intFromFloat(self.location.y + 30), 16, raylib.Color.white);
        allocator.free(buffer2);

        var result: i32 = 0;
        if (self.type == MessageBoxType.Confirm) {
            const ok = raygui.guiButton(
                raylib.Rectangle{ .x = @as(f32, self.location.x + 10), .y = @as(f32, self.location.y + 50), .width = 100, .height = 30 },
                "OK",
            );
            const cancel = raygui.guiButton(
                raylib.Rectangle{ .x = @as(f32, self.location.x + 120), .y = @as(f32, self.location.y + 50), .width = 100, .height = 30 },
                "Cancel",
            );

            if (ok > 0) {
                result = 1;
            } else if (cancel > 0) {
                result = 2;
            }
        } else if (self.type == MessageBoxType.Error) {} else {
            const ok = raygui.guiButton(
                raylib.Rectangle{ .x = @as(f32, self.location.x + 10), .y = @as(f32, self.location.y + 50), .width = 100, .height = 30 },
                "OK",
            );

            if (ok > 0) {
                result = 1;
            }
        }

        if (result > 0) {
            self.open = false;
            try self.callBackFunction(self, result);
        }
    }
};
