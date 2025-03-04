const types = @import("./_types.zig");
const raylib = @import("raylib");
const util = @import("utility");

pub const GroundSectorMaxZTriangles = 25;
pub const GroundSectorMaxXTriangles = 50;
pub const GroundSectorTriangleSize = GroundSectorMaxXTriangles * GroundSectorMaxZTriangles;
pub const GroundSectorScale: f32 = 10.0;

pub const GroundSector = struct {
    triangles: [GroundSectorTriangleSize]types.Triangle,
    gridX: u32 = 0,
    gridZ: u32 = 0,
    startX: f32 = 0,
    startZ: f32 = 0,

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

    pub fn generateSector(gridX: u32, gridZ: u32, flat: bool) GroundSector {
        const xStart = @as(f32, @floatFromInt(gridX)) * GroundSectorMaxXTriangles * GroundSectorScale;
        const zStart = @as(f32, @floatFromInt(gridZ)) * GroundSectorMaxZTriangles * GroundSectorScale;

        var current_ground_sector = GroundSector.new();
        current_ground_sector.gridX = gridX;
        current_ground_sector.gridZ = gridZ;
        current_ground_sector.startX = xStart;
        current_ground_sector.startZ = zStart;

        var lastTriangle: types.Triangle = undefined;
        for (0..types.GroundSectorMaxZTriangles) |z| {
            for (0..types.GroundSectorMaxZTriangles) |x| {

                // Z as a float value
                const zAsF32 = @as(f32, @floatFromInt(z));

                // Pick a random height between 0 and 3.5
                var randomNewHeight: f32 = 0;
                if (!flat) {
                    randomNewHeight = @as(f32, @floatFromInt(raylib.getRandomValue(0, 35))) / 10.0;
                }

                // If the vector point is already generated in a prev triangle, use that height
                var oldRandomHeight = randomNewHeight;

                var new_a: raylib.Vector3 = undefined;
                var new_b: raylib.Vector3 = undefined;
                var new_c: raylib.Vector3 = undefined;

                if (x == 0) {
                    if (z != 0) {
                        oldRandomHeight = current_ground_sector.triangles[(z - 1) * types.GroundSectorMaxXTriangles].b.y;
                    }

                    new_a = raylib.Vector3.init(xStart, oldRandomHeight, (zAsF32 * types.GroundSectorScale) + zStart);
                    new_b = raylib.Vector3.init(xStart, randomNewHeight, (zAsF32 * types.GroundSectorScale) + types.GroundSectorScale + zStart);
                    new_c = raylib.Vector3.init(xStart + types.GroundSectorScale, randomNewHeight, (zAsF32 * types.GroundSectorScale) + types.GroundSectorScale + zStart);
                } else {
                    if (x % 2 == 1) {
                        if (z != 0) {
                            oldRandomHeight = current_ground_sector.triangles[(z - 1) * types.GroundSectorMaxXTriangles + x].b.y;
                        }

                        new_a = lastTriangle.a;
                        new_b = lastTriangle.c;
                        new_c = raylib.Vector3.init(lastTriangle.c.x, oldRandomHeight, (zAsF32 * types.GroundSectorScale) + zStart);
                    } else {
                        new_a = lastTriangle.c;
                        new_b = lastTriangle.b;
                        new_c = raylib.Vector3.init(lastTriangle.c.x + types.GroundSectorScale, randomNewHeight, (zAsF32 * types.GroundSectorScale) + types.GroundSectorScale + zStart);
                    }
                }

                const edge1 = util.GetEdgeVector(new_a, new_b);
                const edge2 = util.GetEdgeVector(new_a, new_c);
                const normal = util.CrossProduct(edge1, edge2);

                const intensity = util.calculateLightIntensity(normal, new_a, new_b, new_c, raylib.Vector3.init(20.5, 100, 11.5));
                const color = util.applyIntensity(raylib.Color.green, intensity);

                lastTriangle = types.Triangle{
                    .a = new_a,
                    .b = new_b,
                    .c = new_c,
                    .center = util.triangleCenter(new_a, new_b, new_c),
                    .normal = normal,
                    .color = color,
                };

                current_ground_sector.triangles[z * types.GroundSectorMaxXTriangles + x] = lastTriangle;
            }
        }
        return current_ground_sector;
    }

    pub fn setStart(self: *GroundSector) void {
        self.startX = self.gridX * GroundSectorMaxXTriangles * GroundSectorScale;
        self.startZ = self.gridZ * GroundSectorMaxZTriangles * GroundSectorScale;
    }
    pub fn draw(self: *GroundSector) void {
        for (self.triangles) |triangle| {
            raylib.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
        }
    }
};
