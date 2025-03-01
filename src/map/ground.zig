const util = @import("utility");
const rl = @import("raylib");
const std = @import("std");

const maxZTriangles = 25;
const maxXTriangles = 50;
var groundScale: f32 = 10.0;

const ground_sector = struct {
    triangles: [maxXTriangles * maxZTriangles]util.Triangle,
    startX: i32 = 0,
    startZ: i32 = 0,

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

pub fn GetYValueBasedOnLocation(x: f32, z: f32) f32 {
    const xasF32 = @as(f32, x);
    const zasF32 = @as(f32, z);
    const v3 = rl.Vector3.init(xasF32, 0, zasF32);

    var y: f32 = 0.0;
    for (current_ground_sector.triangles) |triangle| {
        if (zasF32 >= triangle.a.z and (zasF32 <= triangle.c.z or zasF32 < triangle.b.z)) {
            if (util.TestIfPointInTriangle2D(v3, triangle.a, triangle.b, triangle.c)) {
                y = util.FindYFromNormal(triangle.normal, triangle.a, v3.x, v3.z) + 2;

                break;
            }
        }
    }
    return y;
}

pub fn UpdateCameraPosition(camera: *rl.Camera3D) void {
    const y = GetYValueBasedOnLocation(camera.position.x, camera.position.z);
    camera.target.y = camera.target.y + (y - camera.position.y);
    camera.position.y = y;
}

pub fn SaveGroundSectorToFile(sector: ground_sector) anyerror!bool {
    const cwd = std.fs.cwd();

    // get generic allowcator
    const allocator = std.heap.page_allocator;
    const filename = std.fmt.allocPrint(allocator, "map/ground_sector_{}_{}.gs", .{ sector.startX, sector.startZ }) catch |err| {
        std.debug.print("Error allocating filename: {}\n", .{err});
        return false;
    };

    cwd.makeDir("map") catch |err| {
        std.debug.print("Error creating file: {}\n", .{err});
    };

    const file = cwd.createFile(filename, std.fs.File.CreateFlags{
        .read = false,
        .truncate = true,
    }) catch |err| {
        std.debug.print("Error creating file: {}\n", .{err});
        return false;
    };
    defer file.close();

    const writer = file.writer();
    for (sector.triangles) |triangle| {
        // a, b, c, center, normal, color
        writer.print("{}, {}, {} , {}, {}, {} , {}, {}, {} , {}, {}, {} , {}, {}, {} ,{}, {}, {}, {}\n", .{ triangle.a.x, triangle.a.y, triangle.a.z, triangle.b.x, triangle.b.y, triangle.b.z, triangle.c.x, triangle.c.y, triangle.c.z, triangle.center.x, triangle.center.y, triangle.center.z, triangle.normal.x, triangle.normal.y, triangle.normal.z, triangle.color.r, triangle.color.g, triangle.color.b, triangle.color.a }) catch |err| {
            std.debug.print("Error writing to file: {}\n", .{err});
            return false;
        };
    }

    return true;
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

    const dd = SaveGroundSectorToFile(current_ground_sector) catch |err| {
        std.debug.print("Error saving ground sector to file: {}\n", .{err});
        return;
    };

    std.debug.print("Ground sector saved to file: {}\n", .{dd});
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
