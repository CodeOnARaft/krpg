const raylib = @import("raylib");
const types = @import("types");
const shared = @import("shared");

pub const NPC = struct {
    name: []u8,
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    heading: raylib.Vector2 = raylib.Vector2{ .x = 0.0, .y = 0.0 },
    texture: raylib.Texture2D = undefined,
    trigger: types.Trigger = types.Trigger{ .type = types.TriggerTypes.Empty, .description = @constCast("empty") },

    active: bool = true,

    pub fn setPosition(self: *NPC, x: f32, y: f32, z: f32) void {
        self.position = raylib.Vector3{ .x = x, .y = y, .z = z };
        self.trigger.setPosition(x, y, z);
        self.trigger.description = self.name;
    }

    pub fn setTriggerType(self: *NPC, triggerType: types.TriggerTypes) void {
        self.trigger.type = triggerType;
    }

    pub fn draw(self: *NPC, camera: raylib.Camera3D) void {
        if (self.texture.id == 0 or !self.active) {
            return;
        }

        raylib.drawBillboard(camera, self.texture, self.position, 0.5, raylib.Color.white);
        if (shared.settings.gameSettings.debug) {
            self.trigger.draw();
        }
    }
};
