const settings = @import("settings");
const std = @import("std");
const util = @import("utility");
const raylib = @import("raylib");
const gui = @import("raygui");
const types = @import("types");
const managers = @import("managers");
const basic = types.Basic;

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
const consoleMaxHeight = types.Constants.screenHeightf32 / 2.0;
const consoleSpeed: f32 = 750.0;

pub const Console = struct {
    state: ConsoleState = ConsoleState.Closed,
    height: f32 = consoleMinHeight,
    typedText: []const u8 = "",
    game_manager: *managers.GameManager = undefined,
    lastKeyCode: raylib.KeyboardKey = raylib.KeyboardKey.null,
    lastRead: f32 = 0.0,

    pub fn init(self: *Console, game_manager: *managers.GameManager) void {
        self.game_manager = game_manager;
    }

    pub fn drawConsole(self: *Console) void {
        if (self.state.isSliding()) {
            self.consoleUpdate();
        }

        if (self.state == ConsoleState.Open or self.state.isSliding()) {
            if (!self.state.isSliding()) {
                const released = self.findKeyReleased();
                if (released.isPressed) {
                    if (released.isBackspace) {
                        self.typedText = util.String.removeCharConstU8(std.heap.page_allocator, self.typedText) catch |err| {
                            std.debug.print("Error removing char: {}\n", .{err});
                            return;
                        };
                    } else if (released.isEnter) {
                        std.debug.print("Typed text: {s}\n", .{self.typedText});
                        self.handleCommand(self.typedText);
                        std.heap.page_allocator.free(self.typedText);
                        self.typedText = "";
                    } else {
                        self.typedText = util.String.appendCharConstU8(std.heap.page_allocator, self.typedText, released.value) catch |err| {
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
            const tt = util.String.toSentinelConstU8(std.heap.page_allocator, terminal) catch |err| {
                std.debug.print("Error allocating typedText: {}\n", .{err});
                return;
            };

            _ = gui.guiPanel(raylib.Rectangle{ .x = 0, .y = 0, .width = types.Constants.screenWidthf32, .height = self.height }, "Console");
            _ = gui.guiLabel(raylib.Rectangle{ .x = 5, .y = types.Constants.screenHeightf32 / 2 - 25, .width = types.Constants.screenWidthf32 - 10, .height = 20 }, tt);
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

    pub fn findKeyReleased(self: *Console) basic.CharValue {
        self.lastRead += raylib.getFrameTime();
        if (self.lastKeyCode == raylib.KeyboardKey.null or self.lastRead > 1.0) {
            self.lastKeyCode = raylib.getKeyPressed();
            self.lastRead = 0.0;
        }

        if (raylib.isKeyReleased(self.lastKeyCode)) {
            //  std.debug.print("Key released: {}\n", .{lastKeyCode});

            if (self.lastKeyCode == raylib.KeyboardKey.backspace) {
                self.lastKeyCode = raylib.KeyboardKey.null;
                return basic.CharValue{ .value = 0, .isPressed = true, .isBackspace = true };
            }

            if (self.lastKeyCode == raylib.KeyboardKey.enter) {
                self.lastKeyCode = raylib.KeyboardKey.null;
                return basic.CharValue{ .value = 0, .isPressed = true, .isEnter = true };
            }

            const val: i32 = @intFromEnum(self.lastKeyCode);
            self.lastKeyCode = raylib.KeyboardKey.null;

            if (val == 32 or (val >= 32 and val <= 126)) {
                return basic.CharValue{ .value = @intCast(val), .isPressed = true };
            }
        } else {
            // std.debug.print("Key wait: {}\n", .{lastKeyCode});
        }

        return basic.CharValue{ .value = 0, .isPressed = false };
    }
};
