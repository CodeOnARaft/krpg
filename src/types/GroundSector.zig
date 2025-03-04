const types = @import("./_types.zig");
const raylib = @import("raylib");

pub const GroundSectorMaxZTriangles = 25;
pub const GroundSectorMaxXTriangles = 50;
pub const GroundSectorTriangleSize = GroundSectorMaxXTriangles * GroundSectorMaxZTriangles;
pub const GroundSectorScale: f32 = 10.0;

pub const GroundSector = struct {
    triangles: [GroundSectorTriangleSize]types.Triangle,
    gridX: i32 = 0,
    gridZ: i32 = 0,
    startX: i32 = 0,
    startZ: i32 = 0,

    pub fn setStart(self: *GroundSector) void {
        self.startX = self.gridX * GroundSectorMaxXTriangles * GroundSectorScale;
        self.startZ = self.gridZ * GroundSectorMaxZTriangles * GroundSectorScale;
    }

    pub fn new() GroundSector {
        var triangles: [GroundSectorTriangleSize]types.Triangle = undefined;
        for (0..triangles.len) |i| {
            triangles[i] = types.Triangle{
                .a = raylib.Vector3.zero(),
                .b = raylib.Vector3.zero(),
                .c = raylib.Vector3.zero(),
                .center = raylib.Vector3.zero(),
                .normal = raylib.Vector3.zero(),
                .color = raylib.Color.white,
            };
        }
        return GroundSector{ .triangles = triangles, .startX = 0.0, .startZ = 0.0 };
    }

    pub fn draw(self: *GroundSector) void {
        for (self.triangles) |triangle| {
            raylib.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
        }
    }
};
