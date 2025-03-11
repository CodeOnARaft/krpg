const raylib = @import("raylib");
const std = @import("std");

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
