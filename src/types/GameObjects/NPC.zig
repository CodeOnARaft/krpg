const raylib = @import("raylib");
const types = @import("types");
const settings = @import("settings");
pub const NPC = struct {
    name: []const u8,
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    heading: raylib.Vector2 = raylib.Vector2{ .x = 0.0, .y = 0.0 },
    texture: raylib.Texture2D = undefined,
    trigger: types.Trigger = types.Trigger{ .type = types.TriggerTypes.Test, .description = "Test" },

    active: bool = true,

    pub fn setPosition(self: *NPC, x: f32, y: f32, z: f32) void {
        self.position = raylib.Vector3{ .x = x, .y = y, .z = z };
        self.trigger.setPosition(x, y, z);
    }

    pub fn draw(self: *NPC, camera: raylib.Camera3D) void {
        if (self.texture.id == 0 or !self.active) {
            return;
        }

        raylib.drawBillboard(camera, self.texture, self.position, 0.5, raylib.Color.white);
        if (settings.gameSettings.debug) {
            self.trigger.draw();
        }
    }
};
