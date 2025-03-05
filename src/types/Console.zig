const settings = @import("settings");
const std = @import("std");
const util = @import("utility");
const raylib = @import("raylib");
const gui = @import("raygui");
const types = @import("types");
const managers = @import("managers");

pub const ConsoleState = enum {
    Opening,
    Closing,
    Open,
    Closed,

    pub fn isSliding(self: ConsoleState) bool {
        return self == ConsoleState.Closing or self == ConsoleState.Opening;
    }
};

const consoleMinHeight = 10.0;
const consoleMaxHeight = settings.screenHeightf32 / 2.0;
const consoleSpeed: f32 = 750.0;

pub const Console = struct {
    state: ConsoleState = ConsoleState.Closed,
    height: f32 = consoleMinHeight,
    typedText: []const u8 = "",
    game_manager: *managers.GameManager = undefined,

    pub fn init(self: *Console, game_manager: *managers.GameManager) void {
        self.game_manager = game_manager;
    }

    pub fn drawConsole(self: *Console) void {
        if (self.state.isSliding()) {
            self.consoleUpdate();
        }

        if (self.state == ConsoleState.Open or self.state.isSliding()) {
            if (!self.state.isSliding()) {
                const released = util.findKeyReleased();
                if (released.isPressed) {
                    if (released.isBackspace) {
                        self.typedText = removeChar(std.heap.page_allocator, self.typedText) catch |err| {
                            std.debug.print("Error removing char: {}\n", .{err});
                            return;
                        };
                    } else if (released.isEnter) {
                        std.debug.print("Typed text: {s}\n", .{self.typedText});
                        self.handleCommand(self.typedText);
                        std.heap.page_allocator.free(self.typedText);
                        self.typedText = "";
                    } else {
                        self.typedText = appendChar(std.heap.page_allocator, self.typedText, released.value) catch |err| {
                            std.debug.print("Error appending char: {}\n", .{err});
                            return;
                        };
                    }
                }
            }

            const terminal: []const u8 = std.fmt.allocPrint(std.heap.page_allocator, "> {s}", .{self.typedText}) catch |err| {
                std.debug.print("Error allocating terminal: {}\n", .{err});
                return;
            };
            defer std.heap.page_allocator.free(terminal);
            const tt = toSentinel(std.heap.page_allocator, terminal) catch |err| {
                std.debug.print("Error allocating typedText: {}\n", .{err});
                return;
            };

            _ = gui.guiPanel(raylib.Rectangle{ .x = 0, .y = 0, .width = settings.screenWidthf32, .height = self.height }, "Console");
            _ = gui.guiLabel(raylib.Rectangle{ .x = 5, .y = settings.screenHeightf32 / 2 - 25, .width = settings.screenWidthf32 - 10, .height = 20 }, tt);
        }
    }

    fn consoleUpdate(self: *Console) void {
        const deltaTime = raylib.getFrameTime() * consoleSpeed;
        if (self.state == ConsoleState.Opening) {
            self.height += deltaTime;
            if (self.height >= consoleMaxHeight) {
                self.height = consoleMaxHeight;
                self.state = ConsoleState.Open;
            }
        } else if (self.state == ConsoleState.Closing) {
            self.height -= deltaTime;
            if (self.height <= consoleMinHeight) {
                self.height = consoleMinHeight;
                self.state = ConsoleState.Closed;
                settings.gameSettings.paused = false;
            }
        }
    }

    pub fn consoleToggle(self: *Console) void {
        if (self.state.isSliding()) {
            return;
        }

        if (self.state == ConsoleState.Open) {
            self.closeConsole();
        } else {
            self.openConsole();
        }
    }

    fn openConsole(self: *Console) void {
        if (self.state.isSliding()) {
            return;
        }

        settings.gameSettings.paused = true;
        self.height = consoleMinHeight;
        self.state = ConsoleState.Opening;
    }

    fn closeConsole(self: *Console) void {
        if (self.state.isSliding()) {
            return;
        }

        self.state = ConsoleState.Closing;
    }

    fn handleCommand(self: *Console, command: []const u8) void {
        std.debug.print("Handling command: {s}\n", .{command});
        if (std.mem.eql(u8, command, "EXIT")) {
            self.closeConsole();
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

        if (command.len >= "LOCATION".len and std.mem.eql(u8, command[0.."LOCATION".len], "LOCATION")) {
            const sec = command["LOCATION".len..];
            if (sec.len == 0) {
                std.debug.print("No seconds provided\n", .{});
                return;
            }

            // split command by space with splitSequence
            var newX: f32 = 0.0;
            var newZ: f32 = 0.0;
            var index: u32 = 0;
            var it = std.mem.splitScalar(u8, command, ' ');
            while (it.next()) |commandPart| {
                if (index == 1) {
                    newX = std.fmt.parseFloat(f32, commandPart) catch |err| {
                        std.debug.print("Error parsing x: {}\n", .{err});
                        return;
                    };
                } else if (index == 2) {
                    newZ = std.fmt.parseFloat(f32, commandPart) catch |err| {
                        std.debug.print("Error parsing z: {}\n", .{err});
                        return;
                    };

                    var camera: *raylib.Camera3D = &util.camera;
                    const newY = 0.0; //map.GetYValueBasedOnLocation(newX, newZ);
                    camera.position = raylib.Vector3{ .x = newX, .y = newY, .z = newZ };
                    camera.target = raylib.Vector3{ .x = newX, .y = newY, .z = newZ + 1.0 };
                }

                index += 1;
            }
        }
    }
};

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
