const raylib = @import("raylib");
const std = @import("std");
const ArrayList = std.ArrayList;
const shared = @import("../root.zig");
const types = shared.types;
const managers = shared.managers;
const basic = types.Basic;
const util = shared.utility;

pub fn SaveGroundSectorToFile(scene_name: []u8, sector: types.GroundSector) anyerror!bool {
    const cwd = std.fs.cwd();

    // get generic allowcator
    const allocator = std.heap.page_allocator;
    const filename = std.fmt.allocPrint(allocator, "map/{s}_{}_{}.gs", .{ scene_name.sector.startX, sector.startZ }) catch |err| {
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

pub fn LoadGroundSectorFromFile(scene_name: []u8, x: i32, z: i32) !?types.GroundSector {
    const cwd = std.fs.cwd();
    const allocator = std.heap.page_allocator;
    const filename = std.fmt.allocPrint(allocator, "resources/map/{s}_{}_{}.gs", .{ scene_name, x, z }) catch |err| {
        std.debug.print("Error allocating filename: {}\n", .{err});
        return null;
    };

    const file = cwd.openFile(filename, std.fs.File.OpenFlags{}) catch |err| {
        std.debug.print("Error opening file: {}\n", .{err});
        return null;
    };
    defer file.close();

    var triangles: [types.GroundSectorTriangleSize]basic.Triangle = undefined;

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var index: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parts: ArrayList([]u8) = ArrayList([]u8).init(std.heap.page_allocator);
        var it = std.mem.splitScalar(u8, line, ',');

        while (it.next()) |commandPart| {
            const partU8 = try util.string.constU8toU8(commandPart);
            try parts.append(partU8);
        }

        const p0: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[0]));
        const p1: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[1]));
        const p2: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[2]));
        const p3: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[3]));
        const p4: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[4]));
        const p5: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[5]));
        const p6: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[6]));
        const p7: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[7]));
        const p8: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[8]));
        const p9: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[9]));
        const p10: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[10]));
        const p11: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[11]));
        const p12: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[12]));
        const p13: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[13]));
        const p14: f32 = try std.fmt.parseFloat(f32, util.string.trimSpaceEOL(parts.items[14]));
        const p15: u8 = try std.fmt.parseInt(u8, util.string.trimSpaceEOL(parts.items[15]), 10);
        const p16: u8 = try std.fmt.parseInt(u8, util.string.trimSpaceEOL(parts.items[16]), 10);
        const p17: u8 = try std.fmt.parseInt(u8, util.string.trimSpaceEOL(parts.items[17]), 10);

        const a = raylib.Vector3.init(p0, p1, p2);
        const b = raylib.Vector3.init(p3, p4, p5);
        const c = raylib.Vector3.init(p6, p7, p8);
        const center = raylib.Vector3.init(p9, p10, p11);
        const normal = raylib.Vector3.init(p12, p13, p14);
        const color = raylib.Color.init(p15, p16, p17, 255);

        // const a = raylib.Vector3.init(std.fmt.parseFloat(f32, parts.items[0]), std.fmt.parseFloat(f32, parts.items[1]), std.fmt.parseFloat(f32, parts.items[2]));
        // const b = raylib.Vector3.init(std.fmt.parseFloat(f32, parts.items[3]), std.fmt.parseFloat(f32, parts.items[4]), std.fmt.parseFloat(f32, parts.items[5]));
        // const c = raylib.Vector3.init(std.fmt.parseFloat(f32, parts.items[6]), std.fmt.parseFloat(f32, parts.items[7]), std.fmt.parseFloat(f32, parts.items[8]));
        // const center = raylib.Vector3.init(std.fmt.parseFloat(f32, parts.items[9]), std.fmt.parseFloat(f32, parts.items[10]), std.fmt.parseFloat(f32, parts.items[11]));
        // const normal = raylib.Vector3.init(std.fmt.parseFloat(f32, parts.items[12]), std.fmt.parseFloat(f32, parts.items[13]), std.fmt.parseFloat(f32, parts.items[14]));
        // const color = raylib.Color.init(std.fmt.parseInt(parts.items[15]), std.fmt.parseInt(parts.items[16]), std.fmt.parseInt(parts.items[17]), 255);

        const triangle = basic.Triangle{
            .a = a,
            .b = b,
            .c = c,
            .center = center,
            .normal = normal,
            .color = color,
        };

        triangles[index] = triangle;
        index += 1;
    }

    var new_sec = types.GroundSector{ .triangles = triangles, .gridX = @intCast(x), .gridZ = @intCast(z) };
    new_sec.setStart();
    return new_sec;
}
