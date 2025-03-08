const types = @import("types");
const std = @import("std");
const raylib = @import("raylib");
const util = @import("utility");
const settings = @import("settings");

pub const TriggerTypes = enum {
    Test,
    SceneChange,
    Conversation,
};

pub const Trigger = struct {
    type: TriggerTypes = TriggerTypes.Test,
    boundingBox: raylib.BoundingBox = undefined,
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    size: f32 = 0.1,
    description: []u8 = undefined,

    pub fn setPosition(self: *Trigger, x: f32, y: f32, z: f32) void {
        self.position = raylib.Vector3{ .x = x, .y = y, .z = z };
        self.boundingBox = raylib.BoundingBox{
            .min = raylib.Vector3{ .x = x - self.size, .y = y - self.size, .z = z - self.size },
            .max = raylib.Vector3{ .x = x + self.size, .y = y + self.size, .z = z + self.size },
        };
    }

    pub fn draw(self: *Trigger) void {
        raylib.drawBoundingBox(self.boundingBox, raylib.Color.blue);
    }

    pub fn checkCollision(self: *Trigger, ray: raylib.Ray) bool {
        var hit = false;

        const col: raylib.RayCollision = raylib.getRayCollisionBox(ray, self.boundingBox);

        if (col.hit) {
            const dis = util.vector3.distanceVector3_XZ(self.position, util.camera.position);
            if (dis < types.Constants.interactDistance) {
                hit = true;
            }
        }

        return hit;
    }
};
