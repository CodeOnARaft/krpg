const util = @import("utility");
const raylib = @import("raylib");
const std = @import("std");
const types = @import("types");

var current_ground_sector: types.GroundSector = undefined;

pub fn GetYValueBasedOnLocation(x: f32, z: f32) f32 {
    const xasF32 = @as(f32, x);
    const zasF32 = @as(f32, z);
    const v3 = raylib.Vector3.init(xasF32, 0, zasF32);

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

pub fn UpdateCameraPosition(camera: *raylib.Camera3D) void {
    const y = GetYValueBasedOnLocation(camera.position.x, camera.position.z);
    camera.target.y = camera.target.y + (y - camera.position.y);
    camera.position.y = y;
}

pub fn SaveGroundSectorToFile(sector: types.GroundSector) anyerror!bool {
    const cwd = std.fs.cwd();

    // get generic allowcator
    const allocator = std.heap.page_allocator;
    const filename = std.fmt.allocPrint(allocator, "map/types.GroundSector_{}_{}.gs", .{ sector.startX, sector.startZ }) catch |err| {
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

pub fn LoadGroundSectorFromFile(x: i32, z: i32) ?types.GroundSector {
    const cwd = std.fs.cwd();
    const allocator = std.heap.page_allocator;
    const filename = std.fmt.allocPrint(allocator, "map/types.GroundSector_{}_{}.gs", .{ x, z }) catch |err| {
        std.debug.print("Error allocating filename: {}\n", .{err});
        return null;
    };

    const file = cwd.openFile(filename, .{ .read = true }) catch |err| {
        std.debug.print("Error opening file: {}\n", .{err});
        return null;
    };
    defer file.close();

    const reader = file.reader();
    var triangles: [types.GroundSectorTriangleSize]types.Triangle = undefined;
    for (triangles, 0..) |triangle, index| {
        const line = try reader.readLine();
        if (line == null) {
            break;
        }

        const parts = line.split(",");
        if (parts.len != 18) {
            std.debug.print("Error reading line from file: {}\n", .{line});
            return null;
        }

        const a = raylib.Vector3.init(std.fmt.parseFloat(parts[0]), std.fmt.parseFloat(parts[1]), std.fmt.parseFloat(parts[2]));
        const b = raylib.Vector3.init(std.fmt.parseFloat(parts[3]), std.fmt.parseFloat(parts[4]), std.fmt.parseFloat(parts[5]));
        const c = raylib.Vector3.init(std.fmt.parseFloat(parts[6]), std.fmt.parseFloat(parts[7]), std.fmt.parseFloat(parts[8]));
        const center = raylib.Vector3.init(std.fmt.parseFloat(parts[9]), std.fmt.parseFloat(parts[10]), std.fmt.parseFloat(parts[11]));
        const normal = raylib.Vector3.init(std.fmt.parseFloat(parts[12]), std.fmt.parseFloat(parts[13]), std.fmt.parseFloat(parts[14]));
        const color = raylib.Color.init(std.fmt.parseInt(parts[15]), std.fmt.parseInt(parts[16]), std.fmt.parseInt(parts[17]), 255);

        triangle = types.Triangle{
            .a = a,
            .b = b,
            .c = c,
            .center = center,
            .normal = normal,
            .color = color,
        };

        triangles[index] = triangle;
    }

    return types.GroundSector{ .triangles = triangles, .startX = x, .startZ = z };
}

pub fn GenerateSector(x: i32, z: i32) types.GroundSector {
    const sector = LoadGroundSectorFromFile(x, z);
    if (sector != null) {
        sector.setStart();
        return sector;
    }
}

pub fn SetupGround() void {
    // Implement the ground drawing logic here
    current_ground_sector = types.GroundSector.new();

    var lastTriangle: types.Triangle = undefined;
    for (0..types.GroundSectorMaxZTriangles) |y| {
        for (0..types.GroundSectorMaxZTriangles) |x| {
            //const xasF32 = @as(f32, @floatFromInt(x));
            const yasF32 = @as(f32, @floatFromInt(y));

            // random value between 0 and 2
            const h = raylib.getRandomValue(0, 35);
            // h as f32
            const hf32 = @as(f32, @floatFromInt(h)) / 10.0;
            var oldhf32 = hf32;
            if (x == 0) {
                if (y != 0) {
                    oldhf32 = current_ground_sector.triangles[(y - 1) * 50].b.y;
                }
                lastTriangle = types.Triangle{
                    .a = raylib.Vector3.init(0, oldhf32, (yasF32 * types.GroundSectorScale)),
                    .b = raylib.Vector3.init(0, hf32, (yasF32 * types.GroundSectorScale) + types.GroundSectorScale),
                    .c = raylib.Vector3.init(types.GroundSectorScale, hf32, (yasF32 * types.GroundSectorScale) + types.GroundSectorScale),
                    .center = raylib.Vector3.zero(),
                    .normal = raylib.Vector3.zero(),
                    .color = raylib.Color.green,
                };
            } else {
                if (x % 2 == 1) {
                    if (y != 0) {
                        oldhf32 = current_ground_sector.triangles[(y - 1) * 50 + x].b.y;
                    }
                    lastTriangle = types.Triangle{
                        .a = lastTriangle.a,
                        .b = lastTriangle.c,
                        .c = raylib.Vector3.init(lastTriangle.c.x, oldhf32, (yasF32 * types.GroundSectorScale)),
                        .center = raylib.Vector3.zero(),
                        .normal = raylib.Vector3.zero(),
                        .color = raylib.Color.green,
                    };
                } else {
                    lastTriangle = types.Triangle{
                        .a = lastTriangle.c,
                        .b = lastTriangle.b,
                        .c = raylib.Vector3.init(lastTriangle.c.x + types.GroundSectorScale, hf32, (yasF32 * types.GroundSectorScale) + types.GroundSectorScale),
                        .center = raylib.Vector3.zero(),
                        .normal = raylib.Vector3.zero(),
                        .color = raylib.Color.green,
                    };
                }
            }

            const edge1 = util.GetEdgeVector(lastTriangle.a, lastTriangle.b);
            const edge2 = util.GetEdgeVector(lastTriangle.a, lastTriangle.c);
            const normal = util.CrossProduct(edge1, edge2);
            //groundNormals[y * 50 + x] = normal;

            const intensity = util.calculateLightIntensity(normal, lastTriangle.a, lastTriangle.b, lastTriangle.c, raylib.Vector3.init(20.5, 100, 11.5));
            const color = util.applyIntensity(lastTriangle.color, intensity);

            lastTriangle = types.Triangle{
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
    current_ground_sector.draw();
}
