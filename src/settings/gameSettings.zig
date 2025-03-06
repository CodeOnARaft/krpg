const raylib = @import("raylib");
const std = @import("std");
const settings = @import("settings");

pub const screenWidth = 1280;
pub const screenHeight = 720;

pub const screenWidthf32: f32 = 1280.0;
pub const screenHeightf32: f32 = 720.0;

pub const interactDistance: f32 = 4.0;

const Settings = struct {
    paused: bool = false,
    debug: bool = false,

    pub fn update(self: *Settings) void {
        if (raylib.isKeyReleased(raylib.KeyboardKey.p)) {
            self.paused = !self.paused;
        }
    }
};

pub var gameSettings = Settings{};
