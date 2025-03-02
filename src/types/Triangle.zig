const raylib = @import("raylib");

pub const Triangle = struct {
    a: raylib.Vector3,
    b: raylib.Vector3,
    c: raylib.Vector3,
    center: raylib.Vector3,
    normal: raylib.Vector3,
    color: raylib.Color,
};
