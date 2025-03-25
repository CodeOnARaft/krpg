const std = @import("std");
const ArrayList = std.ArrayList;
const raylib = @import("raylib");
const shared = @import("../../root.zig");

pub const Object = struct {
    name: []const u8 = undefined,
    model: raylib.Model = undefined,
    walkthrough: bool = false,
    trigger: shared.types.Trigger = undefined,
    hasTrigger: bool = false,
};

pub const ObjectInstance = struct {
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    rotation: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },

    name: []const u8 = undefined,

    pub fn load(scene_name: []const u8, x: i32, z: i32, scene: *shared.types.Scene) !void {
        const cwd = std.fs.cwd();
        const allocator = std.heap.page_allocator;
        const filename = std.fmt.allocPrint(allocator, "{s}/map/{s}_{}_{}.gbl", .{ shared.settings.gameSettings.resourceDirectory, scene_name, x, z }) catch |err| {
            std.debug.print("Error allocating filename: {}\n", .{err});
            return err;
        };

        const file = cwd.openFile(filename, std.fs.File.OpenFlags{}) catch |err| {
            std.debug.print("Error opening file: {s} {}\n", .{ filename, err });
            return err;
        };
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;
        //var index: usize = 0;
        var obj = shared.types.GameObjects.ObjectInstance{};
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            std.debug.print("obj Line: {s}\n", .{line});
            var parts: ArrayList([]const u8) = ArrayList([]const u8).init(std.heap.page_allocator);
            var it = std.mem.splitScalar(u8, line, ' ');

            while (it.next()) |commandPart| {
                //const partU8 = try shared.util.string.constU8toU8(commandPart);
                try parts.append(commandPart);
            }

            if (parts.items.len == 0) {
                std.debug.print("Empty line\n", .{});
                continue;
            }

            if (std.mem.eql(u8, parts.items[0], "name")) {
                if (obj.name.len > 0) {
                    try scene.loadedObjects.append(obj);
                }

                std.debug.print("obj: {s}\n", .{parts.items[1]});
                const nameBuffer = allocator.alloc(u8, parts.items[1].len) catch |err| {
                    std.debug.print("Error allocating name buffer: {}\n", .{err});
                    return err;
                };
                std.mem.copyForwards(u8, nameBuffer, parts.items[1]);
                obj = shared.types.GameObjects.ObjectInstance{
                    .name = nameBuffer,
                };
            } else if (std.mem.eql(u8, parts.items[0], "position")) {
                const obj_x = std.fmt.parseFloat(f32, parts.items[1]) catch |err| {
                    std.debug.print("Error parsing x: {}\n", .{err});
                    return err;
                };

                const obj_y = std.fmt.parseFloat(f32, parts.items[2]) catch |err| {
                    std.debug.print("Error parsing xy: {}\n", .{err});
                    return err;
                };

                const obj_z = std.fmt.parseFloat(f32, parts.items[3]) catch |err| {
                    std.debug.print("Error parsing z: {s} {}\n", .{ parts.items[3], err });
                    return err;
                };

                obj.position = raylib.Vector3{ .x = obj_x, .y = obj_y, .z = obj_z };
            }
        }

        std.debug.print("obj end: {s}\n", .{obj.name});
        if (obj.name.len > 0) {
            try scene.loadedObjects.append(obj);
        }
    }
};

// self.model = try raylib.loadModel("resources/barrel.glb"); // Load model
// const texture = try raylib.loadTexture("resources/T_Barrel_BaseColor.png"); // Load model texture
// self.model.materials[0].maps[0].texture = texture; // Set map diffuse texture
