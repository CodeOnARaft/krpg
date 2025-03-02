const raylib = @import("raylib");

pub const NPC = struct {
    name: []const u8,
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    heading: raylib.Vector2 = raylib.Vector2{ .x = 0.0, .y = 0.0 },
    texture: raylib.Texture2D = undefined,
    bounding_box: raylib.Rectangle = raylib.Rectangle{ .x = 0.0, .y = 0.0, .width = 0.0, .height = 0.0 },
    active: bool = true,
};
