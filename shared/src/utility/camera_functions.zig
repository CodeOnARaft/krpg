const std = @import("std");
const rl = @import("raylib");
const shared = @import("../root.zig");
const types = shared.types;
const managers = shared.managers;
const basic = types.Basic;
const util = shared.utility;
const v3 = util.vector3;

pub const cameraDefaultY = 3.0;

pub var camera = rl.Camera3D{
    .position = rl.Vector3.init(20, cameraDefaultY, 20),
    .target = rl.Vector3.init(30, cameraDefaultY, 30),
    .up = rl.Vector3.init(0, 1, 0),
    .fovy = 60,
    .projection = .perspective,
};

const half_fov = 30.0;
const sin_of_fov = std.math.sin(half_fov);
const cos_of_fov = std.math.cos(half_fov);
const neg_cos_of_fov = std.math.cos(-half_fov);
const neg_sin_of_fov = std.math.sin(-half_fov);

pub fn rotateXZLeft(v: rl.Vector3) rl.Vector3 {
    return rl.Vector3{
        .x = v.x * neg_cos_of_fov - v.z * neg_sin_of_fov,
        .y = v.y, // Y remains unchanged.
        .z = v.x * neg_sin_of_fov + v.z * neg_cos_of_fov,
    };
}

pub fn rotateXZRight(v: rl.Vector3) rl.Vector3 {
    return rl.Vector3{
        .x = v.x * cos_of_fov - v.z * sin_of_fov,
        .y = v.y, // Y remains unchanged.
        .z = v.x * sin_of_fov + v.z * cos_of_fov,
    };
}

pub fn getViewingRay() rl.Ray {
    const dx = camera.target.x - camera.position.x;
    const dy = camera.target.y - camera.position.y;
    const dz = camera.target.z - camera.position.z;

    const normal = util.vector3.normalize(rl.Vector3{ .x = dx, .y = dy, .z = dz });

    const ray = rl.Ray{
        .position = camera.position,
        .direction = rl.Vector3{
            .x = normal.x,
            .y = normal.y,
            .z = normal.z,
        },
    };

    return ray;
}
