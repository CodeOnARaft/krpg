const raylib = @import("raylib");
const std = @import("std");
const ArrayList = std.ArrayList;
const shared = @import("../../root.zig");
const types = shared.types;
const managers = shared.managers;
const basic = types.Basic;
const util = shared.utility;

pub const Player = struct {
    gameManager: *managers.GameManager = undefined,

    pub fn init(self: *Player, gameManager: *managers.GameManager) void {
        self.gameManager = gameManager;
    }

    pub fn update(self: *Player) void {
        _ = self.gameManager.console;
    }
};
