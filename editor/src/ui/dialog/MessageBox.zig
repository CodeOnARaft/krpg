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
    title: [:0]const u8 = undefined,
    message: [:0]const u8 = undefined,
    location: raylib.Rectangle = undefined,
    editor: *EditorWindow = undefined,
    callBackFunction: *const fn (*MessageBox, result: i32) anyerror!void = undefined,
    type: MessageBoxType = MessageBoxType.Info,
    borderColor: raylib.Color = undefined,
    backgroundColor: raylib.Color = undefined,

    pub fn openDialog(self: *MessageBox, title: [:0]const u8, message: [:0]const u8, boxType: MessageBoxType, callBackFunction: *const fn (*MessageBox, i32) anyerror!void) !void {
        self.open = true;
        self.callBackFunction = callBackFunction;
        self.title = title;
        self.message = message;
        self.type = boxType;
    }

    pub fn update(self: *MessageBox) !bool {
        var handled = false;
        if (!self.open) {
            return handled;
        }

        handled = true;

        return handled;
    }

    pub fn init(self: *MessageBox, editor: *EditorWindow) !void {
        const x = (ui.Constants.WINDOW_WIDTHf - ui.Constants.MB_WIDTHf) / 2;
        const y = (ui.Constants.WINDOW_HEIGHTf - ui.Constants.MB_HEIGHTf) / 2;

        self.editor = editor;
        self.open = false;
        self.title = "Message Box";
        self.message = "Message";
        self.location = raylib.Rectangle{ .x = x, .y = y, .width = ui.Constants.MB_WIDTHf, .height = ui.Constants.MB_HEIGHTf };

        const style = raygui.guiGetStyle(raygui.GuiControl.default, raygui.GuiDefaultProperty.background_color);
        self.backgroundColor = raylib.fade(raylib.getColor(@intCast(style)), 1);

        const style2 = raygui.guiGetStyle(raygui.GuiControl.dropdownbox, raygui.GuiControlProperty.border_color_normal);
        self.borderColor = raylib.fade(raylib.getColor(@intCast(style2)), 1);
    }

    pub fn draw(self: *MessageBox) !void {
        // const allocator = std.heap.page_allocator;
        if (!self.open) {
            return;
        }

        raylib.drawRectangle(
            @intFromFloat(self.location.x),
            @intFromFloat(self.location.y),
            @intFromFloat(self.location.width),
            26,
            self.backgroundColor,
        );
        raylib.drawRectangle(
            @intFromFloat(self.location.x),
            @intFromFloat(self.location.y + 26),
            @intFromFloat(self.location.width),
            @intFromFloat(self.location.height - 26),
            raylib.Color.black,
        );

        raylib.drawRectangleLines(@intFromFloat(self.location.x), @intFromFloat(self.location.y), @intFromFloat(self.location.width), @intFromFloat(self.location.height), self.borderColor);

        raylib.drawText(self.title, @intFromFloat(self.location.x + 10), @intFromFloat(self.location.y + 5), 16, raylib.Color.white);

        raylib.drawText(self.message, @intFromFloat(self.location.x + 10), @intFromFloat(self.location.y + 30), 20, raylib.Color.white);

        var result: i32 = 0;
        const buttonY: f32 = self.location.y + self.location.height - 40;
        if (self.type == MessageBoxType.Confirm) {
            const ok = raygui.guiButton(
                raylib.Rectangle{ .x = @as(f32, self.location.x + 10), .y = buttonY, .width = 100, .height = 30 },
                "OK",
            );
            const cancel = raygui.guiButton(
                raylib.Rectangle{ .x = @as(f32, self.location.x + 120), .y = buttonY, .width = 100, .height = 30 },
                "Cancel",
            );

            if (ok > 0) {
                result = 1;
            } else if (cancel > 0) {
                result = 2;
            }
        } else {
            const ok = raygui.guiButton(
                raylib.Rectangle{ .x = @as(f32, self.location.x + 10), .y = buttonY, .width = 100, .height = 30 },
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
