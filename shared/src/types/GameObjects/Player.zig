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
    health: f32 = 100.0,
    mana: f32 = 100.0,
    stamina: f32 = 100.0,
    level: u32 = 1,

    pub fn init(self: *Player, gameManager: *managers.GameManager) void {
        self.gameManager = gameManager;
    }

    pub fn update(self: *Player, frame_allocator: std.mem.Allocator) anyerror!void {
        _ = frame_allocator;
        if (raylib.isKeyReleased(.i)) {
            try self.gameManager.changeView(.Inventory);
        }

        if (raylib.isKeyReleased(.escape) or raylib.isKeyReleased(.c)) {
            try self.gameManager.changeView(.Scene);
        }
    }

    pub fn draw(self: *Player, frame_allocator: std.mem.Allocator) anyerror!void {
        _ = frame_allocator;
        _ = self.gameManager.console;
        raylib.clearBackground(raylib.Color.gray);
    }
};
