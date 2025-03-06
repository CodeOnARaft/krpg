const std = @import("std");
const v3 = @import("vector3_functions.zig");
const rl = @import("raylib");
const settings = @import("settings");

const cameraDefaultY = 3.0;

pub fn constU8toU8(inString: []const u8) ![]u8 {
    const outString = try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{inString});
    return outString;
}

pub fn trimSpaceEOL(inString: []const u8) []u8 {
    const d: []u8 = undefined;
    const v = constU8toU8(std.mem.trim(u8, inString, " \n")) catch |err| {
        std.debug.print("Error trimming string: {}\n", .{err});
        return d;
    };

    return v;
}

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
    const direction = rl.Vector3{
        .x = camera.target.x - camera.position.x,
        .y = camera.target.y - camera.position.y,
        .z = camera.target.z - camera.position.z,
    };

    const ray = rl.Ray{
        .position = camera.position,
        .direction = rl.Vector3{
            .x = direction.x * settings.interactDistance,
            .y = direction.y * settings.interactDistance,
            .z = direction.z * settings.interactDistance,
        },
    };

    return ray;
}
