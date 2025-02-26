const rl = @import("raylib");
const std = @import("std");

pub fn GetEdgeVector(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3.init(b.x - a.x, b.y - a.y, b.z - a.z);
}

pub fn CrossProduct(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3.init(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
    );
}

pub fn FindYFromNormal(normal: rl.Vector3, point: rl.Vector3, x: f32, z: f32) f32 {
    const top = normal.x * (x - point.x) + normal.z * (z - point.z);
    const bottom = normal.y;
    return point.y - (top / bottom);
}

/// Adds two vectors.
pub fn addVec3(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
}

/// Subtracts b from a.
pub fn subVec3(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
}

/// Scales a vector by a scalar.
pub fn scaleVec3(v: rl.Vector3, s: f32) rl.Vector3 {
    return rl.Vector3{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
}

pub fn triangleCenter(a: rl.Vector3, b: rl.Vector3, c: rl.Vector3) rl.Vector3 {
    // The centroid is the average of the vertices.
    return scaleVec3(addVec3(addVec3(a, b), c), 1.0 / 3.0);
}
pub fn lengthVec3(v: rl.Vector3) f32 {
    return std.math.sqrt(dotVec3(v, v));
}

pub fn dotVec3(a: rl.Vector3, b: rl.Vector3) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

/// Computes the cross product of two vectors.
pub fn cross(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

pub fn normalizeVec3(v: rl.Vector3) rl.Vector3 {
    return scaleVec3(v, 1.0 / lengthVec3(v));
}

pub fn calculateLightIntensity(
    triangleNormal: rl.Vector3,
    a: rl.Vector3,
    b: rl.Vector3,
    c: rl.Vector3,
    sunPosition: rl.Vector3,
) f32 {
    // Compute the center of the triangle.
    const center = triangleCenter(a, b, c);
    // Compute a normalized light direction from the triangle center to the sun.
    const lightDir = normalizeVec3(subVec3(sunPosition, center));
    std.debug.print("Light direction: {}, {}, {}\n", .{ lightDir.x, lightDir.y, lightDir.z });

    // Compute the diffuse intensity (clamped to zero if the angle is more than 90°).

    var diffuseIntensity = dotVec3(triangleNormal, lightDir);

    if (diffuseIntensity < 0.0) {
        diffuseIntensity = 0.0;
    }

    var ambientIntensity: f32 = 0.15;
    ambientIntensity = ambientIntensity + (1.0 - ambientIntensity) * diffuseIntensity;
    while (ambientIntensity > 1.0) {
        ambientIntensity = ambientIntensity / 10.0;
    }

    return ambientIntensity;
}

pub fn applyIntensity(base: rl.Color, intensity: f32) rl.Color {
    // Clamp intensity to the range [0.0, 1.0] if needed.
    //const clampedIntensity: f32 = std.math.clamp(intensity, 0.0, 1.0);
    //std.debug.print("Intensity: {}\n", .{clampedIntensity});
    const rf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.r))) * intensity, 0, 255);
    const gf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.g))) * intensity, 0, 255);
    const bf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.b))) * intensity, 0, 255);

    // Multiply each color channel (converted to f32) by the intensity.
    // We round the result before casting back to u8.
    const color = rl.Color{
        .r = @as(u8, @intFromFloat(std.math.round(rf32))),
        .g = @as(u8, @intFromFloat(std.math.round(gf32))),
        .b = @as(u8, @intFromFloat(std.math.round(bf32))),
        .a = base.a,
    };

    return color;
}
pub fn TestIfPointInTriangle2D(pp: rl.Vector3, aa: rl.Vector3, bb: rl.Vector3, cc: rl.Vector3) bool {
    const p = rl.Vector2.init(pp.x, pp.z);
    const a = rl.Vector2.init(aa.x, aa.z);
    const b = rl.Vector2.init(bb.x, bb.z);
    const c = rl.Vector2.init(cc.x, cc.z);

    const s = a.y * c.x - a.x * c.y + (c.y - a.y) * p.x + (a.x - c.x) * p.y;
    const t = a.x * b.y - a.y * b.x + (a.y - b.y) * p.x + (b.x - a.x) * p.y;

    if ((s < 0) != (t < 0)) {
        return false;
    }

    const A = -b.y * c.x + a.y * (c.x - b.x) + a.x * (b.y - c.y) + b.x * c.y;

    if (A < 0) {
        return (s <= 0 and (s + t >= A));
    } else {
        return (s >= 0 and (s + t <= A));
    }
}

var viewDistance: f32 = 1000.0;
pub fn TriangleIsVisible(triangle: rl.Vector3, pos: rl.Vector3, left: rl.Vector3, right: rl.Vector3) bool {
    const leftScaled = scaleVec3(left, viewDistance);
    const rightScaled = scaleVec3(right, viewDistance);
    return TestIfPointInTriangle2D(triangle, pos, addVec3(pos, leftScaled), addVec3(pos, rightScaled));
}
