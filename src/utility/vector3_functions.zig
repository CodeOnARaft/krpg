const raylib = @import("raylib");
const std = @import("std");
const types = @import("types");

pub fn GetEdgeVector(a: raylib.Vector3, b: raylib.Vector3) raylib.Vector3 {
    return raylib.Vector3.init(b.x - a.x, b.y - a.y, b.z - a.z);
}

pub fn CrossProduct(a: raylib.Vector3, b: raylib.Vector3) raylib.Vector3 {
    return raylib.Vector3.init(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
    );
}

pub fn FindYFromNormal(normal: raylib.Vector3, point: raylib.Vector3, x: f32, z: f32) f32 {
    const top = normal.x * (x - point.x) + normal.z * (z - point.z);
    const bottom = normal.y;
    return point.y - (top / bottom);
}

pub fn distanceVector3(a: raylib.Vector3, b: raylib.Vector3) f32 {
    return std.math.sqrt(std.math.pow(f32, a.x - b.x, 2) + std.math.pow(f32, a.z - b.z, 2));
}

/// Adds two vectors.
pub fn addVec3(a: raylib.Vector3, b: raylib.Vector3) raylib.Vector3 {
    return raylib.Vector3{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
}

/// Subtracts b from a.
pub fn subVec3(a: raylib.Vector3, b: raylib.Vector3) raylib.Vector3 {
    return raylib.Vector3{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
}

/// Scales a vector by a scalar.
pub fn scaleVec3(v: raylib.Vector3, s: f32) raylib.Vector3 {
    return raylib.Vector3{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
}

pub fn triangleCenter(a: raylib.Vector3, b: raylib.Vector3, c: raylib.Vector3) raylib.Vector3 {
    // The centroid is the average of the vertices.
    return scaleVec3(addVec3(addVec3(a, b), c), 1.0 / 3.0);
}
pub fn lengthVec3(v: raylib.Vector3) f32 {
    return std.math.sqrt(dotVec3(v, v));
}

pub fn dotVec3(a: raylib.Vector3, b: raylib.Vector3) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

/// Computes the cross product of two vectors.
pub fn cross(a: raylib.Vector3, b: raylib.Vector3) raylib.Vector3 {
    return raylib.Vector3{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

pub fn normalizeVec3(v: raylib.Vector3) raylib.Vector3 {
    return scaleVec3(v, 1.0 / lengthVec3(v));
}

pub fn calculateLightIntensity(
    triangleNormal: raylib.Vector3,
    a: raylib.Vector3,
    b: raylib.Vector3,
    c: raylib.Vector3,
    sunPosition: raylib.Vector3,
) f32 {
    // Compute the center of the triangle.
    const center = triangleCenter(a, b, c);
    // Compute a normalized light direction from the triangle center to the sun.
    const lightDir = normalizeVec3(subVec3(sunPosition, center));

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

pub fn applyIntensity(base: raylib.Color, intensity: f32) raylib.Color {
    // Clamp intensity to the range [0.0, 1.0] if needed.
    //const clampedIntensity: f32 = std.math.clamp(intensity, 0.0, 1.0);
    //std.debug.print("Intensity: {}\n", .{clampedIntensity});
    const rf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.r))) * intensity, 0, 255);
    const gf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.g))) * intensity, 0, 255);
    const bf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.b))) * intensity, 0, 255);

    // Multiply each color channel (converted to f32) by the intensity.
    // We round the result before casting back to u8.
    const color = raylib.Color{
        .r = @as(u8, @intFromFloat(std.math.round(rf32))),
        .g = @as(u8, @intFromFloat(std.math.round(gf32))),
        .b = @as(u8, @intFromFloat(std.math.round(bf32))),
        .a = base.a,
    };

    return color;
}
pub fn TestIfPointInTriangle2D(pp: raylib.Vector3, aa: raylib.Vector3, bb: raylib.Vector3, cc: raylib.Vector3) bool {
    const p = raylib.Vector2.init(pp.x, pp.z);
    const a = raylib.Vector2.init(aa.x, aa.z);
    const b = raylib.Vector2.init(bb.x, bb.z);
    const c = raylib.Vector2.init(cc.x, cc.z);

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

pub fn Vector3sAreEqual(a: raylib.Vector3, b: raylib.Vector3) bool {
    return a.x == b.x and a.y == b.y and a.z == b.z;
}

pub fn TriangleIsVisible(triangle: types.Triangle, pos: raylib.Vector3, left: raylib.Vector3, right: raylib.Vector3) bool {
    const leftScaled = scaleVec3(left, viewDistance);
    const rightScaled = scaleVec3(right, viewDistance);

    return triangleOverlapOrInside(pos, addVec3(pos, leftScaled), addVec3(pos, rightScaled), triangle.a, triangle.b, triangle.c);
}

const Vec2 = struct {
    x: f32,
    z: f32,
};

const edgeVec2 = struct {
    a: Vec2,
    b: Vec2,
};

/// Check if a point (p) is inside a triangle (A, B, C) using barycentric coordinates
fn pointInTriangle(p: Vec2, a: Vec2, b: Vec2, c: Vec2) bool {
    const v0 = Vec2{ .x = c.x - a.x, .z = c.z - a.z };
    const v1 = Vec2{ .x = b.x - a.x, .z = b.z - a.z };
    const v2 = Vec2{ .x = p.x - a.x, .z = p.z - a.z };

    const dot00 = v0.x * v0.x + v0.z * v0.z;
    const dot01 = v0.x * v1.x + v0.z * v1.z;
    const dot02 = v0.x * v2.x + v0.z * v2.z;
    const dot11 = v1.x * v1.x + v1.z * v1.z;
    const dot12 = v1.x * v2.x + v1.z * v2.z;

    const invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01);
    const u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    const v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    return (u >= 0) and (v >= 0) and (u + v <= 1);
}

/// Check if two line segments (A1-B1 and A2-B2) intersect
fn linesIntersect(ea: edgeVec2, eb: edgeVec2) bool {
    const a1 = ea.a;
    const b1 = ea.b;
    const a2 = eb.a;
    const b2 = eb.b;
    const d = (b2.z - a2.z) * (b1.x - a1.x) - (b2.x - a2.x) * (b1.z - a1.z);
    if (d == 0.0) return false; // Parallel lines

    const uA = ((b2.x - a2.x) * (a1.z - a2.z) - (b2.z - a2.z) * (a1.x - a2.x)) / d;
    const uB = ((b1.x - a1.x) * (a1.z - a2.z) - (b1.z - a1.z) * (a1.x - a2.x)) / d;

    return (uA >= 0 and uA <= 1 and uB >= 0 and uB <= 1);
}

/// Check if triangle 2 overlaps or is inside triangle 1
pub fn triangleOverlapOrInside(a1: raylib.Vector3, b1: raylib.Vector3, c1: raylib.Vector3, a2: raylib.Vector3, b2: raylib.Vector3, c2: raylib.Vector3) bool {
    const tri1 = [_]Vec2{
        Vec2{ .x = a1.x, .z = a1.z },
        Vec2{ .x = b1.x, .z = b1.z },
        Vec2{ .x = c1.x, .z = c1.z },
    };

    const tri2 = [_]Vec2{
        Vec2{ .x = a2.x, .z = a2.z },
        Vec2{ .x = b2.x, .z = b2.z },
        Vec2{ .x = c2.x, .z = c2.z },
    };

    // Step 1: Check if all points of triangle 2 are inside triangle 1
    if (pointInTriangle(tri2[0], tri1[0], tri1[1], tri1[2]) and
        pointInTriangle(tri2[1], tri1[0], tri1[1], tri1[2]) and
        pointInTriangle(tri2[2], tri1[0], tri1[1], tri1[2]))
    {
        return true; // Triangle 2 is fully inside triangle 1
    }

    // Step 2: Check for edge intersections
    const edges1 = [3]edgeVec2{
        edgeVec2{ .a = tri1[0], .b = tri1[1] },
        edgeVec2{ .a = tri1[1], .b = tri1[2] },
        edgeVec2{ .a = tri1[2], .b = tri1[0] },
    };

    //{ {tri1[0], tri1[1]}, {tri1[1], tri1[2]}, {tri1[2], tri1[0]} };
    const edges2 = [3]edgeVec2{
        edgeVec2{ .a = tri2[0], .b = tri2[1] },
        edgeVec2{ .a = tri2[1], .b = tri2[2] },
        edgeVec2{ .a = tri2[2], .b = tri2[0] },
    };
    //{tri2[0], tri2[1]}, {tri2[1], tri2[2]}, {tri2[2], tri2[0]} };

    for (edges1) |e1| {
        for (edges2) |e2| {
            if (linesIntersect(e1, e2)) {
                return true; // An edge of triangle 2 intersects triangle 1
            }
        }
    }

    return false; // No overlap
}
