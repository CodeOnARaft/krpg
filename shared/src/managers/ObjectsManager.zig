const raylib = @import("raylib");
const std = @import("std");
const ArrayList = std.ArrayList;
const shared = @import("../root.zig");
const types = shared.types;
const map = shared.map;
const util = shared.utility;
const interfaces = types.interfaces;

pub const ObjectsManager = struct {
    objects: ArrayList(types.GameObjects.Object) = undefined,

    pub fn init(self: *ObjectsManager) !void {
        self.objects = ArrayList(types.GameObjects.Object).init(std.heap.page_allocator);

        try self.loadObjects();
    }

    fn loadObjects(self: *ObjectsManager) !void {
        const allocator = std.heap.page_allocator;

        // Open objects directory
        const sub = try std.fmt.allocPrintZ(allocator, "{s}/objects", .{shared.settings.gameSettings.resourceDirectory});
        defer allocator.free(sub);
        const cwd = try std.fs.cwd().openDir(sub, std.fs.Dir.OpenOptions{ .iterate = true });

        // iterate over files and load "prefab"
        var iter = cwd.iterate();

        while (try iter.next()) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".gob")) {
                const file = cwd.openFile(entry.name, std.fs.File.OpenFlags{}) catch |err| {
                    std.debug.print("=> Error opening file: {s},{}\n", .{ entry.name, err });
                    continue;
                };
                defer file.close();

                var new_object = types.GameObjects.Object{};
                var buf_reader = std.io.bufferedReader(file.reader());
                var in_stream = buf_reader.reader();
                var buf: [1024]u8 = undefined;
                while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
                    var parts: ArrayList([]u8) = ArrayList([]u8).init(allocator);
                    defer parts.deinit();

                    var it = std.mem.splitScalar(u8, line, ' ');

                    while (it.next()) |commandPart| {
                        const partU8 = try util.string.constU8toU8(commandPart);
                        try parts.append(partU8);
                    }

                    if (parts.items.len == 0) {
                        std.debug.print("Empty line\n", .{});
                        continue;
                    }

                    if (std.mem.eql(u8, parts.items[0], "name")) {
                        new_object.name = parts.items[1];
                    } else if (std.mem.eql(u8, parts.items[0], "model")) {
                        const filename = try std.fmt.allocPrintZ(allocator, "{s}/objects/{s}", .{ shared.settings.gameSettings.resourceDirectory, parts.items[1] });
                        std.debug.print("Loading model: {s}\n", .{filename});
                        defer allocator.free(filename);

                        new_object.model = try raylib.loadModel(filename);
                    } else if (std.mem.eql(u8, parts.items[0], "texture")) {
                        const filename = try std.fmt.allocPrintZ(allocator, "{s}/objects/{s}", .{ shared.settings.gameSettings.resourceDirectory, parts.items[1] });
                        std.debug.print("Loading model: {s}\n", .{filename});
                        defer allocator.free(filename);

                        const texture = try raylib.loadTexture(filename);

                        new_object.model.materials[0].maps[0].texture = texture;
                    } else if (std.mem.eql(u8, parts.items[0], "walkthrough")) {
                        if (std.mem.startsWith(u8, parts.items[1], "1")) {
                            new_object.walkthrough = true;
                        }
                    }
                }

                try self.objects.append(new_object);
            }
        }

        std.debug.print("Loaded objects: {d}\n", .{self.objects.items.len});
    }

    pub fn drawObject(self: *ObjectsManager, name: []const u8, position: raylib.Vector3) !void {
        for (self.objects.items) |object| {
            //std.debug.print("Checking object: {s} = {s}\n", .{ object.name, name });
            if (std.mem.eql(u8, object.name, name)) {
                //std.debug.print("Drawing object: {s}\n", .{object.name});
                raylib.drawModel(object.model, position, 1.0, raylib.Color.white);
            }
        }
    }

    pub fn drawSelected(self: *ObjectsManager, name: []const u8, position: raylib.Vector3) !void {
        for (self.objects.items) |object| {
            if (std.mem.eql(u8, object.name, name)) {
                raylib.drawModelWires(object.model, position, 1.05, raylib.Color.red);
            }
        }
    }
};
