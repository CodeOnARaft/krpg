const std = @import("std");
const raylib = @import("raylib");
const shared = @import("../root.zig");
const types = shared.types;
const managers = shared.managers;
const basic = types.Basic;
const util = shared.utility;

pub const TriggerTypes = enum {
    Empty,
    SceneChange,
    Conversation,
    Inventory,
};

pub const emptyTrigger: types.Trigger = types.Trigger{ .type = types.TriggerTypes.Empty, .description = @constCast("empty") };
pub const emptyTriggerPtr: *types.Trigger = @constCast(&emptyTrigger);

pub const Trigger = struct {
    type: TriggerTypes = TriggerTypes.Empty,
    boundingBox: raylib.BoundingBox = undefined,
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    size: f32 = 0.4,
    size_height: f32 = 0.8,
    description: []u8 = undefined,

    pub fn setPosition(self: *Trigger, x: f32, y: f32, z: f32) void {
        self.position = raylib.Vector3{ .x = x, .y = y, .z = z };
        self.boundingBox = raylib.BoundingBox{
            .min = raylib.Vector3{ .x = x - self.size, .y = y - self.size_height, .z = z - self.size },
            .max = raylib.Vector3{ .x = x + self.size, .y = y + self.size_height, .z = z + self.size },
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
