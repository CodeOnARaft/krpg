const std = @import("std");
const ArrayList = std.ArrayList;
const raylib = @import("raylib");
const shared = @import("../../root.zig");
const raygui = @import("raygui");

pub const Object = struct {
    name: []const u8 = undefined,
    model: raylib.Model = undefined,
    walkthrough: bool = false,
};

pub const ObjectInstance = struct {
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    rotation: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },

    name: []const u8 = undefined,
    type: []const u8 = undefined,
    description: []const u8 = undefined,
    objectManager: *shared.managers.ObjectsManager = undefined,

    pub fn load(allocator: std.mem.Allocator, scene_name: []const u8, x: i32, z: i32, scene: *shared.types.Scene) !void {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const arena_allocator = arena.allocator();

        const cwd = std.fs.cwd();
        const filename = std.fmt.allocPrint(arena_allocator, "{s}/map/{s}_{}_{}.gbl", .{ shared.settings.gameSettings.resourceDirectory, scene_name, x, z }) catch |err| {
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
            var lline = line;
            if (std.mem.endsWith(u8, line, "\r")) {
                lline = line[0 .. line.len - 1];
            }
            var parts: ArrayList([]const u8) = ArrayList([]const u8).init(arena_allocator);
            var it = std.mem.splitScalar(u8, lline, ' ');

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
                    std.debug.print("obj name: {s}\n", .{obj.name});
                    try scene.loadedObjects.append(obj);
                }

                std.debug.print("obj: {s}\n", .{parts.items[1]});

                const c_name = try allocator.dupe(u8, parts.items[1]);
                obj = shared.types.GameObjects.ObjectInstance{
                    .name = c_name,
                    .objectManager = scene.objectManager,
                };
            } else if (std.mem.eql(u8, parts.items[0], "type")) {
                std.debug.print("obj: {s}\n", .{parts.items[1]});

                const c_type = try allocator.dupe(u8, parts.items[1]);
                obj.type = c_type;
                std.debug.print("obj type: {s}\n", .{obj.type});
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

        std.debug.print("Loaded objects: {d}\n", .{scene.loadedObjects.items.len});
    }

    pub fn drawProperties(self: *ObjectInstance, position: raylib.Rectangle) anyerror!void {
        const allocator = std.heap.page_allocator;
        const buffer = try allocator.allocSentinel(u8, self.name.len, 0);
        std.mem.copyForwards(u8, buffer[0..self.name.len], self.name);
        _ = raygui.guiLabel(raylib.Rectangle{ .x = position.x + 5, .y = position.y, .width = 100, .height = 20 }, buffer);
        allocator.free(buffer);

        _ = raygui.guiLabel(raylib.Rectangle{ .x = position.x + 5, .y = position.y + 50, .width = 100, .height = 20 }, "X:");
        _ = raygui.guiLabel(raylib.Rectangle{ .x = position.x + 5, .y = position.y + 75, .width = 100, .height = 20 }, "Y:");
        _ = raygui.guiLabel(raylib.Rectangle{ .x = position.x + 5, .y = position.y + 100, .width = 100, .height = 20 }, "Z:");
    }

    pub fn drawSelected(self: *ObjectInstance, mode: shared.managers.ObjectManagerModes) anyerror!void {
        self.objectManager.drawSelected(self.type, self.position) catch |err| {
            std.debug.print("Error drawing selected object: {}\n", .{err});
            return err;
        };

        const smallScale = 0.25;
        const bigScale = 2.5;
        const bigScaleOffset = 0.5 * bigScale;

        switch (mode) {
            shared.managers.ObjectManagerModes.Grab => {},
            shared.managers.ObjectManagerModes.Move => {
                raylib.drawCube(raylib.Vector3{
                    .x = self.position.x + bigScaleOffset,
                    .y = self.position.y,
                    .z = self.position.z,
                }, bigScale, smallScale, smallScale, raylib.Color.red);
                raylib.drawCube(raylib.Vector3{
                    .x = self.position.x,
                    .y = self.position.y + bigScaleOffset,
                    .z = self.position.z,
                }, smallScale, bigScale, smallScale, raylib.Color.blue);
                raylib.drawCube(raylib.Vector3{
                    .x = self.position.x,
                    .y = self.position.y,
                    .z = self.position.z + bigScaleOffset,
                }, smallScale, smallScale, bigScale, raylib.Color.yellow);
            },
            shared.managers.ObjectManagerModes.Rotation => {},
        }
    }

    pub fn drawTrigger(self: *ObjectInstance, frame_allocator: std.mem.Allocator) anyerror!void {
        _ = self;
        _ = frame_allocator;
    }

    pub fn updateTrigger(self: *ObjectInstance, frame_allocator: std.mem.Allocator) anyerror!void {
        _ = self;
        _ = frame_allocator;
    }
};
