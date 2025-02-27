const util = @import("utility");
const rl = @import("raylib");

const maxZTriangles = 25;
const maxXTriangles = 50;
var groundScale: f32 = 10.0;

const ground_sector = struct {
    triangles: [maxXTriangles * maxZTriangles]util.Triangle,
    startX: f32 = 0.0,
    startZ: f32 = 0.0,

    pub fn new() ground_sector {
        var triangles: [maxXTriangles * maxZTriangles]util.Triangle = undefined;
        for (0..triangles.len) |i| {
            triangles[i] = util.Triangle{
                .a = rl.Vector3.zero(),
                .b = rl.Vector3.zero(),
                .c = rl.Vector3.zero(),
                .center = rl.Vector3.zero(),
                .normal = rl.Vector3.zero(),
                .color = rl.Color.white,
            };
        }
        return ground_sector{ .triangles = triangles, .startX = 0.0, .startZ = 0.0 };
    }
};

var current_ground_sector: ground_sector = undefined;

pub fn UpdateCameraPosition(camera: *rl.Camera3D) void {
    const pos = camera.position;
    for (current_ground_sector.triangles) |triangle| {
        if (pos.z >= triangle.a.z and (pos.z <= triangle.c.z or pos.z < triangle.b.z)) {
            if (util.TestIfPointInTriangle2D(pos, triangle.a, triangle.b, triangle.c)) {
                const y = util.FindYFromNormal(triangle.normal, triangle.a, pos.x, pos.z) + 2;
                camera.target.y = camera.target.y + (y - camera.position.y);
                camera.position.y = y;
                break;
            }
        }
    }
}

pub fn SaveGroundSectorToFile(sector:ground_sector){
    // file name should include the sector's start x and z
    const filename = format( "map/ground_sector_{}_{}.gs", .{sector.startX, sector.startZ});
    
    const file = std.fs.cwd().openFile("ground_sector.bin", .{ .write = true, .create = true, .truncate = true, .exclusive = false });
    const writer = file.writer();
    writer.write(sector);
    writer.flush();
    writer.close();
    file.close();
}

pub fn SetupGround() void {
    // Implement the ground drawing logic here
    current_ground_sector = ground_sector.new();

    var lastTriangle: util.Triangle = undefined;
    for (0..25) |y| {
        for (0..50) |x| {
            //const xasF32 = @as(f32, @floatFromInt(x));
            const yasF32 = @as(f32, @floatFromInt(y));

            // random value between 0 and 2
            const h = rl.getRandomValue(0, 35);
            // h as f32
            const hf32 = @as(f32, @floatFromInt(h)) / 10.0;
            var oldhf32 = hf32;
            if (x == 0) {
                if (y != 0) {
                    oldhf32 = current_ground_sector.triangles[(y - 1) * 50].b.y;
                }
                lastTriangle = util.Triangle{
                    .a = rl.Vector3.init(0, oldhf32, (yasF32 * groundScale)),
                    .b = rl.Vector3.init(0, hf32, (yasF32 * groundScale) + groundScale),
                    .c = rl.Vector3.init(groundScale, hf32, (yasF32 * groundScale) + groundScale),
                    .center = rl.Vector3.zero(),
                    .normal = rl.Vector3.zero(),
                    .color = rl.Color.green,
                };
            } else {
                if (x % 2 == 1) {
                    if (y != 0) {
                        oldhf32 = current_ground_sector.triangles[(y - 1) * 50 + x].b.y;
                    }
                    lastTriangle = util.Triangle{
                        .a = lastTriangle.a,
                        .b = lastTriangle.c,
                        .c = rl.Vector3.init(lastTriangle.c.x, oldhf32, (yasF32 * groundScale)),
                        .center = rl.Vector3.zero(),
                        .normal = rl.Vector3.zero(),
                        .color = rl.Color.green,
                    };
                } else {
                    lastTriangle = util.Triangle{
                        .a = lastTriangle.c,
                        .b = lastTriangle.b,
                        .c = rl.Vector3.init(lastTriangle.c.x + groundScale, hf32, (yasF32 * groundScale) + groundScale),
                        .center = rl.Vector3.zero(),
                        .normal = rl.Vector3.zero(),
                        .color = rl.Color.green,
                    };
                }
            }

            const edge1 = util.GetEdgeVector(lastTriangle.a, lastTriangle.b);
            const edge2 = util.GetEdgeVector(lastTriangle.a, lastTriangle.c);
            const normal = util.CrossProduct(edge1, edge2);
            //groundNormals[y * 50 + x] = normal;

            const intensity = util.calculateLightIntensity(normal, lastTriangle.a, lastTriangle.b, lastTriangle.c, rl.Vector3.init(20.5, 100, 11.5));
            const color = util.applyIntensity(lastTriangle.color, intensity);

            lastTriangle = util.Triangle{
                .a = lastTriangle.a,
                .b = lastTriangle.b,
                .c = lastTriangle.c,
                .center = util.triangleCenter(lastTriangle.a, lastTriangle.b, lastTriangle.c),
                .normal = normal,
                .color = color,
            };

            current_ground_sector.triangles[y * 50 + x] = lastTriangle;
        }
    }
}

pub fn DrawGround() void {
    // const forward = util.scaleVec3(util.normalizeVec3(util.subVec3(util.camera.position, util.camera.target)), -1.0);
    // const left = util.rotateXZLeft(forward);
    // const right = util.rotateXZRight(forward);

    // // print camera target, left and right

    var count: i32 = 0;
    // const pos = util.subVec3(util.camera.position, util.camera.target);
    for (current_ground_sector.triangles) |triangle| {
        // if (util.TriangleIsVisible(triangle, pos, left, right)) {
        //     rl.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
        count = count + 1;
        // }

        rl.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
    }
}
