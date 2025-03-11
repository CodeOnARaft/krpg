const types = @import("./_types.zig");
const basic = types.Basic;
const raylib = @import("raylib");
const util = @import("utility");

pub const GroundSectorMaxZTriangles = 25;
pub const GroundSectorMaxXTriangles = 50;
pub const GroundSectorTriangleSize = GroundSectorMaxXTriangles * GroundSectorMaxZTriangles;
pub const GroundSectorScale: f32 = 10.0;
pub const GroundSectorSize = GroundSectorTriangleSize * GroundSectorScale;

pub const GroundSector = struct {
    triangles: [GroundSectorTriangleSize]basic.Triangle,
    gridX: u32 = 0,
    gridZ: u32 = 0,
    startX: f32 = 0,
    startZ: f32 = 0,

    pub fn new(gridX: u32, gridZ: u32) GroundSector {
        var triangles: [GroundSectorTriangleSize]basic.Triangle = undefined;
        for (0..triangles.len) |i| {
            triangles[i] = basic.Triangle{
                .a = raylib.Vector3.zero(),
                .b = raylib.Vector3.zero(),
                .c = raylib.Vector3.zero(),
                .center = raylib.Vector3.zero(),
                .normal = raylib.Vector3.zero(),
                .color = raylib.Color.white,
            };
        }
        var gs = GroundSector{ .triangles = triangles, .gridX = gridX, .gridZ = gridZ };
        gs.setStart();
        return gs;
    }

    pub fn generateSector(gridX: u32, gridZ: u32, flat: bool) GroundSector {
        var current_ground_sector = GroundSector.new(gridX, gridZ);

        const xStart = current_ground_sector.startX;
        const zStart = current_ground_sector.startZ;

        var lastTriangle: basic.Triangle = undefined;
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

                lastTriangle = basic.Triangle{
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
        self.startX = @as(f32, @floatFromInt(self.gridX)) * GroundSectorMaxXTriangles * GroundSectorScale;
        self.startZ = @as(f32, @floatFromInt(self.gridZ)) * GroundSectorMaxZTriangles * GroundSectorScale;
    }

    pub fn draw(self: *GroundSector) void {
        for (self.triangles) |triangle| {
            raylib.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
        }
    }

    pub fn GetYValueBasedOnLocation(self: *GroundSector, x: f32, z: f32) f32 {
        const xasF32 = @as(f32, x);
        const zasF32 = @as(f32, z);
        const v3 = raylib.Vector3.init(xasF32, 0, zasF32);

        var y: f32 = 0.0;
        for (self.triangles) |triangle| {
            if (zasF32 >= triangle.a.z and (zasF32 <= triangle.c.z or zasF32 < triangle.b.z)) {
                if (util.vector3.TestIfPointInTriangle2D(v3, triangle.a, triangle.b, triangle.c)) {
                    y = util.vector3.FindYFromNormal(triangle.normal, triangle.a, v3.x, v3.z) + 2.0;

                    break;
                }
            }
        }
        return y;
    }
};
