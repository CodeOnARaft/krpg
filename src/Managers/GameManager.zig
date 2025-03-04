const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const ArrayList = std.ArrayList;
const map = @import("map");
const settings = @import("settings");
const types = @import("types");

var mary: types.NPC = types.NPC{
    .name = "Mary",
    .position = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    .active = true,
};

pub const GameManager = struct {
    showDebug: bool = false,
    camera: *raylib.Camera3D = undefined,
    oldCameraPosition: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    npcs: ArrayList(types.NPC) = ArrayList(types.NPC).init(std.heap.page_allocator),

    pub fn initialize(self: *GameManager) !void {
        self.camera = &util.camera;
        map.SetupGround();
        map.UpdateCameraPosition(self.camera);
        self.oldCameraPosition = self.camera.position;

        mary.texture = try raylib.loadTexture("resources/npc.png");
        //const marytextureheight: f32 = @floatFromInt(mary.texture.height);
        const maryY = map.GetYValueBasedOnLocation(10, 10);
        mary.position = raylib.Vector3{ .x = 10, .y = maryY, .z = 10.0 };

        try self.npcs.append(mary);
    }

    pub fn update(self: *GameManager) void {
        if (raylib.isKeyReleased(raylib.KeyboardKey.f5)) {
            self.showDebug = !self.showDebug;
        }

        settings.gameSettings.update();

        if (!settings.gameSettings.paused) {
            self.camera.update(.first_person);
            self.camera.up = raylib.Vector3.init(0, 1, 0);

            if (!util.Vector3sAreEqual(self.camera.position, self.oldCameraPosition)) {
                map.UpdateCameraPosition(self.camera);
                self.oldCameraPosition = self.camera.position;
            }
        }
    }

    pub fn draw(self: *GameManager) void {
        self.camera.begin();
        defer self.camera.end();

        // Draw ground
        map.DrawGround();

        // std.debug.print("NPCs: {d}\n", .{self.npcs.len});
        for (self.npcs.items) |npc| {
            //std.debug.print("NPC: {s}\n", .{npc.name});
            if (npc.active) {
                //std.debug.print("Active NPC: {s}\n", .{npc.name});
                raylib.drawBillboard(self.camera.*, npc.texture, npc.position, 1.5, raylib.Color.white);
            }
        }
    }

    pub fn drawUI(self: *GameManager) void {
        settings.drawConsole();
        if (self.showDebug) {
            raylib.drawRectangle(10, 10, 220, 70, raylib.Color.sky_blue.fade(0.5));
            raylib.drawRectangleLines(10, 10, 220, 70, raylib.Color.blue);

            raylib.drawFPS(5, 5);
        }
    }
};
