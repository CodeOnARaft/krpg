const std = @import("std");
const ArrayList = std.ArrayList;
const raylib = @import("raylib");
const shared = @import("../../root.zig");
const types = shared.types;

const inventoryAlloc = std.heap.page_allocator;
pub const Inventory = struct {
    items: ArrayList(shared.types.GameObjects.Item) = undefined,
    capacity: u32 = 0,
    gameManager: *shared.managers.GameManager = undefined,

    pub fn init(self: *Inventory, gameManager: *shared.managers.GameManager, capacity: u32) void {
        self.capacity = capacity;
        self.items = ArrayList(shared.types.GameObjects.Item).init(inventoryAlloc);
        self.gameManager = gameManager;
    }

    pub fn update(self: *Inventory) anyerror!void {
        if (raylib.isKeyReleased(.i) or raylib.isKeyReleased(.escape)) {
            try self.gameManager.changeView(.Scene);
        }

        if (raylib.isKeyReleased(.c)) {
            try self.gameManager.changeView(.Character);
        }
    }

    pub fn draw(self: *Inventory) anyerror!void {
        _ = self.items;
        raylib.clearBackground(raylib.Color.brown);
    }
};
