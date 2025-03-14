const std = @import("std");
const raylib = @import("raylib");
const types = @import("../_types.zig");
const settings = @import("../../settings/_settings.zig");
const shared = @import("../../root.zig");
const ArrayList = std.ArrayList;
const util = shared.utility;

pub const NPC = struct {
    name: []u8 = undefined,
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    heading: raylib.Vector2 = raylib.Vector2{ .x = 0.0, .y = 0.0 },
    texture: raylib.Texture2D = undefined,
    trigger: types.Trigger = types.Trigger{ .type = types.TriggerTypes.Empty, .description = @constCast("empty") },

    active: bool = true,

    pub fn setPosition(self: *NPC, x: f32, y: f32, z: f32) void {
        self.position = raylib.Vector3{ .x = x, .y = y, .z = z };
        self.trigger.setPosition(x, y, z);
        self.trigger.description = self.name;
    }

    pub fn setTriggerType(self: *NPC, triggerType: types.TriggerTypes) void {
        self.trigger.type = triggerType;
    }

    pub fn draw(self: *NPC, camera: raylib.Camera3D) void {
        if (self.texture.id == 0 or !self.active) {
            return;
        }

        raylib.drawBillboard(camera, self.texture, self.position, 2.0, raylib.Color.white);
        if (settings.gameSettings.debug) {
            self.trigger.draw();
        }
    }

    pub fn load(scene_name: []u8, x: i32, z: i32, scene: *types.Scene) !void {
        const cwd = std.fs.cwd();
        const allocator = std.heap.page_allocator;
        const filename = std.fmt.allocPrint(allocator, "{s}/map/{s}_{}_{}.npc", .{ shared.settings.gameSettings.resourceDirectory, scene_name, x, z }) catch |err| {
            std.debug.print("Error allocating filename: {}\n", .{err});
            return err;
        };

        const file = cwd.openFile(filename, std.fs.File.OpenFlags{}) catch |err| {
            std.debug.print("Error opening file: {}\n", .{err});
            return err;
        };
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;
        //var index: usize = 0;
        var npc = types.GameObjects.NPC{};
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            std.debug.print("NPC Line: {s}\n", .{line});
            var parts: ArrayList([]u8) = ArrayList([]u8).init(std.heap.page_allocator);
            var it = std.mem.splitScalar(u8, line, ' ');

            while (it.next()) |commandPart| {
                const partU8 = try util.string.constU8toU8(commandPart);
                try parts.append(partU8);
            }

            if (parts.items.len == 0) {
                std.debug.print("Empty line\n", .{});
                continue;
            }

            std.debug.print("NPC Part 0: {s}\n", .{parts.items[0]});
            if (std.mem.eql(u8, parts.items[0], "npc")) {
                if (npc.name.len > 0) {
                    npc.setTriggerType(types.TriggerTypes.Conversation);
                    try scene.loadedNPCs.append(npc);
                }

                std.debug.print("NPC: {s}\n", .{parts.items[1]});
                npc = types.GameObjects.NPC{
                    .name = parts.items[1],
                    .active = true,
                };
            } else if (std.mem.eql(u8, parts.items[0], "texture")) {
                const textureFilename = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ shared.settings.gameSettings.resourceDirectory, parts.items[1] });
                defer allocator.free(textureFilename);

                const fff = try shared.utility.string.toSentinelConstU8(allocator, textureFilename);
                npc.texture = try raylib.loadTexture(std.mem.span(fff));
            } else if (std.mem.eql(u8, parts.items[0], "location")) {
                const npc_x = std.fmt.parseFloat(f32, parts.items[1]) catch |err| {
                    std.debug.print("Error parsing x: {}\n", .{err});
                    return err;
                };

                const npc_z = std.fmt.parseFloat(f32, parts.items[2]) catch |err| {
                    std.debug.print("Error parsing z: {s} {}\n", .{ parts.items[3], err });
                    return err;
                };

                const y = scene.getYValueBasedOnLocation(npc_x, npc_z) - 1;
                npc.setPosition(npc_x, y, npc_z);
            }
        }

        std.debug.print("NPC: {s}\n", .{npc.name});
        if (npc.name.len > 0) {
            npc.setTriggerType(types.TriggerTypes.Conversation);
            try scene.loadedNPCs.append(npc);
        }
    }
};
