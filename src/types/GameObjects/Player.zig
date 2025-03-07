const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const ArrayList = std.ArrayList;
const map = @import("map");
const settings = @import("settings");
const types = @import("types");
const managers = @import("managers");

pub const Player = struct {
    gameManager: *managers.GameManager = undefined,

    pub fn init(self: *Player, gameManager: *managers.GameManager) void {
        self.gameManager = gameManager;
    }

    pub fn update(self: *Player) void {
        _ = self.gameManager.console;
    }
};
