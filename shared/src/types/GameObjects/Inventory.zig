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
    open: bool = false,

    pub fn init(self: *Inventory, gameManager: *shared.managers.GameManager, capacity: u32) void {
        self.capacity = capacity;
        self.items = ArrayList(shared.types.GameObjects.Item).init(inventoryAlloc);
        self.gameManager = gameManager;
    }

    pub fn update(self: *Inventory) void {
        if (raylib.isKeyReleased(.i) or raylib.isKeyReleased(.escape)) {
            self.open = !self.open;
        }
    }

    pub fn draw(self: *Inventory) void {
        _ = self.items;
        raylib.clearBackground(raylib.Color.brown);
    }
};
