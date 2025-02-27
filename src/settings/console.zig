const gui = @import("raygui");
const raylib = @import("raylib");
const settings = @import("settings");
const std = @import("std");
const util = @import("utility");

var consoleOpening = false;
var consoleOpen = false;
var consoleClosing = false;

const consoleMinHeight = 10.0;
const consoleMaxHeight = settings.screenHeightf32 / 2.0;
var consoleHeight: f32 = 0.0;
var consoleSpeed: f32 = 750.0;

var typedText: []const u8 = "";
const generalAllocator = std.heap.page_allocator;

fn toSentinel(allocator: std.mem.Allocator, text: []const u8) anyerror![*:0]const u8 {
    if (text.len == 0) {
        return "";
    }
    var buffer = try allocator.alloc(u8, text.len + 1); // Allocate new memory
    std.mem.copyForwards(u8, buffer[0..text.len], text); // Copy safely
    buffer[text.len] = 0; // Add null terminator
    return @as([*:0]const u8, @ptrCast(buffer.ptr)); // Cast to sentinel pointer
}

fn appendChar(allocator: std.mem.Allocator, text: []const u8, new_char: u8) ![]const u8 {
    std.debug.print("Appending char: {}\n", .{new_char});
    const new_text = try std.fmt.allocPrint(allocator, "{s}{c}", .{ text, new_char });
    allocator.free(text); // Free the old memory
    return new_text;
}

fn removeChar(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    if (text.len == 0) {
        return text;
    }
    const new_text = try std.fmt.allocPrint(allocator, "{s}", .{text[0 .. text.len - 1]});
    allocator.free(text); // Free the old memory
    return new_text;
}
pub fn drawConsole() void {
    if (consoleOpening or consoleClosing) {
        consoleUpdate();
    }

    if (consoleOpen) {
        if (!consoleOpening and !consoleClosing) {
            const released = util.findKeyReleased();
            if (released.isPressed) {
                if (released.isBackspace) {
                    typedText = removeChar(generalAllocator, typedText) catch |err| {
                        std.debug.print("Error removing char: {}\n", .{err});
                        return;
                    };
                } else if (released.isEnter) {
                    std.debug.print("Typed text: {s}\n", .{typedText});
                    handleCommand(typedText);
                    generalAllocator.free(typedText);
                    typedText = "";
                } else {
                    typedText = appendChar(generalAllocator, typedText, released.value) catch |err| {
                        std.debug.print("Error appending char: {}\n", .{err});
                        return;
                    };
                }
            }
        }

        const terminal: []const u8 = std.fmt.allocPrint(generalAllocator, "> {s}", .{typedText}) catch |err| {
            std.debug.print("Error allocating terminal: {}\n", .{err});
            return;
        };
        defer generalAllocator.free(terminal);
        const tt = toSentinel(generalAllocator, terminal) catch |err| {
            std.debug.print("Error allocating typedText: {}\n", .{err});
            return;
        };

        _ = gui.guiPanel(raylib.Rectangle{ .x = 0, .y = 0, .width = settings.screenWidthf32, .height = consoleHeight }, "Console");
        _ = gui.guiLabel(raylib.Rectangle{ .x = 5, .y = settings.screenHeightf32 / 2 - 25, .width = settings.screenWidthf32 - 10, .height = 20 }, tt);
    }
}

fn consoleUpdate() void {
    const deltaTime = raylib.getFrameTime() * consoleSpeed;
    if (consoleOpening) {
        consoleHeight += deltaTime;
        if (consoleHeight >= consoleMaxHeight) {
            consoleHeight = consoleMaxHeight;
            consoleOpening = false;
            consoleOpen = true;
        }
    } else if (consoleClosing) {
        consoleHeight -= deltaTime;
        if (consoleHeight <= consoleMinHeight) {
            consoleHeight = consoleMinHeight;
            consoleClosing = false;
            consoleOpen = false;
            settings.gameSettings.paused = false;
        }
    }
}

pub fn consoleToggle() void {
    if (consoleOpening or consoleClosing) {
        return;
    }

    if (consoleOpen) {
        closeConsole();
    } else {
        openConsole();
    }
}

fn openConsole() void {
    if (consoleOpening or consoleClosing) {
        return;
    }

    settings.gameSettings.paused = true;
    consoleHeight = consoleMinHeight;
    consoleOpening = true;
    consoleOpen = true;
    consoleClosing = false;
}

fn closeConsole() void {
    if (consoleOpening or consoleClosing) {
        return;
    }

    consoleOpening = false;
    consoleClosing = true;
}

fn handleCommand(command: []const u8) void {
    std.debug.print("Handling command: {s}\n", .{command});
    if (std.mem.eql(u8, command, "EXIT")) {
        closeConsole();
        return;
    }

    if (command.len >= "REGEN-SEC".len and std.mem.eql(u8, command[0.."REGEN-SEC".len], "REGEN-SEC")) {
        const sec = command["REGEN-SEC".len..];
        if (sec.len == 0) {
            std.debug.print("No seconds provided\n", .{});
            return;
        }

        std.debug.print("Seconds provided: {s}\n", .{sec});

        return;
    }
}
