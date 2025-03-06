const raylib = @import("raylib");
const types = @import("types");

pub const NPC = struct {
    name: []const u8,
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    heading: raylib.Vector2 = raylib.Vector2{ .x = 0.0, .y = 0.0 },
    texture: raylib.Texture2D = undefined,
    trigger: types.Trigger = types.Trigger{ .type = types.TriggerTypes.Test, .boundingBox = types.Cube{ .position = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, .width = 0.5, .height = 0.5, .depth = 0.5 }, .description = "Test" },

    active: bool = true,

    pub fn setPosition(self: *NPC, x: f32, y: f32, z: f32) void {
        self.position = raylib.Vector3{ .x = x, .y = y, .z = z };
        self.trigger.boundingBox = types.Cube{ .position = raylib.Vector3{ .x = x, .y = y, .z = z }, .width = 0.5, .height = 0.5, .depth = 0.5 };
    }

    pub fn draw(self: *NPC, camera: raylib.Camera3D, debug: bool) void {
        if (self.texture.id == 0 or !self.active) {
            return;
        }

        raylib.drawBillboard(camera, self.texture, self.position, 0.5, raylib.Color.white);
        if (debug) {
            self.trigger.draw();
        }
    }
};
