const std = @import("std");
const raylib = @import("raylib");
const gui = @import("raygui");
const shared = @import("../root.zig");
const types = shared.types;
const managers = shared.managers;
const basic = types.Basic;
const util = shared.utility;

pub const ConsoleState = enum {
    Opening,
    Closing,
    Open,
    Closed,

    pub fn isSliding(self: ConsoleState) bool {
        return self == ConsoleState.Closing or self == ConsoleState.Opening;
    }

    pub fn isVisible(self: ConsoleState) bool {
        return self != ConsoleState.Closed;
    }
};

const consoleMinHeight = 10.0;
const consoleMaxHeight = types.Constants.screenHeightf32 / 2.0;
const consoleSpeed: f32 = 750.0;

const CommandType = enum {
    Exit,
    RegenSec,
    Time,
    Location,
    Unknown,

    fn fromString(command_str: []const u8) CommandType {
        if (std.mem.eql(u8, command_str, "EXIT")) return .Exit;
        if (std.mem.startsWith(u8, command_str, "REGEN-SEC")) return .RegenSec;
        if (std.mem.startsWith(u8, command_str, "TIME")) return .Time;
        if (std.mem.startsWith(u8, command_str, "LOCATION")) return .Location;
        return .Unknown;
    }
};

pub const Console = struct {
    state: ConsoleState = ConsoleState.Closed,
    height: f32 = consoleMinHeight,
    typedText: []const u8 = "",
    game_manager: *managers.GameManager = undefined,

    arena: std.heap.ArenaAllocator = undefined,
    allocator: std.mem.Allocator = undefined,
    commandHistory: [10][]const u8 = [_][]const u8{""} ** 10,
    replyHistory: [10][]const u8 = [_][]const u8{""} ** 10,

    historyIndex: usize = 0,
    replyIndex: usize = 0,

    pub fn init(self: *Console, game_manager: *managers.GameManager) void {
        self.game_manager = game_manager;
    }

    fn addCommandToHistory(self: *Console, command: []const u8) void {
        if (command.len == 0) return;

        const command_copy = self.arena.allocator().dupe(u8, command) catch |err| {
            std.debug.print("Error copying command to history: {}\n", .{err});
            return;
        };

        self.commandHistory[self.historyIndex] = command_copy;
        self.historyIndex = (self.historyIndex + 1) % 10;
    }

    pub fn Visible(self: *Console) bool {
        return self.state.isVisible();
    }

    pub fn drawConsole(self: *Console) void {
        if (self.state.isSliding()) {
            self.consoleUpdate();
        }

        if (self.state == ConsoleState.Open or self.state.isSliding()) {
            _ = gui.guiPanel(raylib.Rectangle{ .x = 0, .y = 0, .width = types.Constants.screenWidthf32, .height = self.height }, "Console");

            if (!self.state.isSliding()) {
                const released = self.findKeyReleased();
                if (released.isPressed) {
                    if (released.isBackspace) {
                        self.typedText = util.string.removeCharConstU8(self.arena.allocator(), self.typedText) catch |err| {
                            std.debug.print("Error removing char: {}\n", .{err});
                            return;
                        };
                    } else if (released.isEnter) {
                        std.debug.print("Typed text: {s}\n", .{self.typedText});
                        self.addCommandToHistory(self.typedText);
                        self.handleCommand(self.typedText);
                        // Do this:
                        if (self.typedText.len > 0) {
                            self.allocator.free(self.typedText);
                        }
                        self.typedText = "";
                    } else {
                        self.typedText = util.string.appendCharConstU8(self.arena.allocator(), self.typedText, released.value) catch |err| {
                            std.debug.print("Error appending char: {}\n", .{err});
                            return;
                        };
                    }
                }

                // Draw command history
                var historyY: f32 = 30;
                var displayedCount: usize = 0;
                var i: usize = 0;
                while (i < 10 and i < self.historyIndex) : (i += 1) {
                    if (self.commandHistory[i].len > 0) {
                        const historyLine = std.fmt.allocPrintZ(self.arena.allocator(), "> {s}", .{self.commandHistory[i]}) catch |err| {
                            std.debug.print("Error allocating history line: {}\n", .{err});
                            continue;
                        };
                        _ = gui.guiLabel(raylib.Rectangle{ .x = 5, .y = historyY, .width = types.Constants.screenWidthf32 - 10, .height = 20 }, historyLine);
                        historyY += 22;
                        displayedCount += 1;
                    }
                }

                // Draw current input line
                const terminal = std.fmt.allocPrintZ(self.arena.allocator(), "> {s}", .{self.typedText}) catch |err| {
                    std.debug.print("Error allocating terminal: {}\n", .{err});
                    return;
                };
                _ = gui.guiLabel(raylib.Rectangle{ .x = 5, .y = types.Constants.screenHeightf32 / 2 - 25, .width = types.Constants.screenWidthf32 - 10, .height = 20 }, terminal);
            }
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
                shared.settings.gameSettings.paused = false;
                self.arena.deinit();
                self.typedText = "";
                self.historyIndex = 0;
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

        self.arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        self.allocator = self.arena.allocator();
        shared.settings.gameSettings.paused = true;
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

        const command_type = CommandType.fromString(command);
        switch (command_type) {
            .Exit => {
                self.closeConsole();
            },
            .RegenSec => {
                const sec = command["REGEN-SEC".len..];
                if (sec.len == 0) {
                    std.debug.print("No seconds provided\n", .{});
                    return;
                }
                std.debug.print("Seconds provided: {s}\n", .{sec});
            },
            .Time => {
                const time_str = self.game_manager.gameTimeManager.getCurrentTimeString(self.arena.allocator()) catch |err| {
                    std.debug.print("Error getting time string: {}\n", .{err});
                    return;
                };
                std.debug.print("Current Game Time: {s}\n", .{time_str});
            },
            .Location => {
                const args = command["LOCATION".len..];
                if (args.len == 0) {
                    std.debug.print("No coordinates provided\n", .{});
                    return;
                }

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
            },
            .Unknown => {
                std.debug.print("Unknown command: {s}\n", .{command});
            },
        }
    }

    pub fn findKeyReleased(self: *Console) basic.CharValue {
        _ = self;
        for (65..90) |keyCode| {
            const x: raylib.KeyboardKey = @enumFromInt(keyCode);
            if (raylib.isKeyReleased(x)) {
                return basic.CharValue{ .value = @intCast(keyCode), .isPressed = true };
            }
        }
        for (44..57) |keyCode| {
            const x: raylib.KeyboardKey = @enumFromInt(keyCode);
            if (raylib.isKeyReleased(x)) {
                return basic.CharValue{ .value = @intCast(keyCode), .isPressed = true };
            }
        }
        for ([_]usize{
            32,
        }) |keyCode| {
            const x: raylib.KeyboardKey = @enumFromInt(keyCode);
            if (raylib.isKeyReleased(x)) {
                return basic.CharValue{ .value = @intCast(keyCode), .isPressed = true };
            }
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.backspace)) {
            return basic.CharValue{ .value = 0, .isPressed = true, .isBackspace = true };
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.enter)) {
            return basic.CharValue{ .value = 0, .isPressed = true, .isEnter = true };
        }

        return basic.CharValue{ .value = 0, .isPressed = false };
    }
};
