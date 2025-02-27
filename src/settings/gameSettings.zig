const raylib = @import("raylib");
const std = @import("std");

pub const screenWidth = 1280;
pub const screenHeight = 720;

pub const screenWidthf32: f32 = 1280.0;
pub const screenHeightf32: f32 = 720.0;

const Settings = struct {
    paused: bool = false,
    consoleOpen: bool = false,

    pub fn update(self: *Settings) void {
        if (raylib.isKeyReleased(raylib.KeyboardKey.f11)) {
            self.consoleOpen = !self.consoleOpen;
            std.debug.print("updating game settings {}\n", .{self.consoleOpen});
        }
    }
};

pub var gameSettings = Settings{};
