const std = @import("std");
const v3 = @import("vector3_functions.zig");
const rl = @import("raylib");

const cameraDefaultY = 3.0;

pub var camera = rl.Camera3D{
    .position = rl.Vector3.init(50, cameraDefaultY, 50),
    .target = rl.Vector3.init(100, cameraDefaultY, 100),
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
