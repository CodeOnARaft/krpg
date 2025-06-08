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
    boundingBox: raylib.BoundingBox = undefined,
    active: bool = true,
    size: f32 = 0.4,
    size_height: f32 = 0.8,

    pub fn setPosition(self: *NPC, x: f32, y: f32, z: f32) void {
        self.position = raylib.Vector3{ .x = x, .y = y, .z = z };
        self.boundingBox = raylib.BoundingBox{
            .min = raylib.Vector3{ .x = x - self.size, .y = y - self.size_height, .z = z - self.size },
            .max = raylib.Vector3{ .x = x + self.size, .y = y + self.size_height, .z = z + self.size },
        };
    }

    pub fn draw(self: *NPC, frame_allocator: std.mem.Allocator, camera: raylib.Camera3D) void {
        _ = frame_allocator;
        if (!self.active) {
            return;
        }

        // More thorough texture validation
        if (self.texture.id == 0 or self.texture.width == 0 or self.texture.height == 0) {
            std.debug.print("NPC {s}: Invalid texture (id: {}, width: {}, height: {})\n", .{ self.name, self.texture.id, self.texture.width, self.texture.height });
            return;
        }

        // Validate position values
        if (std.math.isNan(self.position.x) or std.math.isNan(self.position.y) or std.math.isNan(self.position.z) or
            std.math.isInf(self.position.x) or std.math.isInf(self.position.y) or std.math.isInf(self.position.z))
        {
            std.debug.print("NPC {s}: Invalid position ({}, {}, {})\n", .{ self.name, self.position.x, self.position.y, self.position.z });
            return;
        }

        // Validate camera
        if (std.math.isNan(camera.position.x) or std.math.isNan(camera.position.y) or std.math.isNan(camera.position.z)) {
            std.debug.print("NPC {s}: Invalid camera position ({}, {}, {})\n", .{ self.name, camera.position.x, camera.position.y, camera.position.z });
            return;
        }

        //std.debug.print("Drawing NPC {s}: texture_id={}, pos=({}, {}, {})\n", .{ self.name, self.texture.id, self.position.x, self.position.y, self.position.z });

        raylib.drawBillboard(camera, self.texture, self.position, 2.0, raylib.Color.white);
    }

    pub fn load(allocator: std.mem.Allocator, scene_name: []const u8, x: i32, z: i32, scene: *types.Scene) !void {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const arena_allocator = arena.allocator();

        const cwd = std.fs.cwd();
        const filename = std.fmt.allocPrint(arena_allocator, "{s}/map/{s}_{}_{}.npc", .{ shared.settings.gameSettings.resourceDirectory, scene_name, x, z }) catch |err| {
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
        var npc = types.GameObjects.NPC{};
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var lline = line;
            if (std.mem.endsWith(u8, line, "\r")) {
                lline = line[0 .. line.len - 1];
            }
            std.debug.print("NPC Line: {s}\n", .{line});
            var parts: ArrayList([]u8) = ArrayList([]u8).init(arena_allocator);
            var it = std.mem.splitScalar(u8, lline, ' ');

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
                    try scene.loadedNPCs.append(npc);
                }

                std.debug.print("NPC: {s}\n", .{parts.items[1]});
                const name_copy = try allocator.dupe(u8, parts.items[1]);
                npc = types.GameObjects.NPC{
                    .name = name_copy,
                    .active = true,
                };
            } else if (std.mem.eql(u8, parts.items[0], "texture")) {
                const textureFilename = try std.fmt.allocPrint(arena_allocator, "{s}/{s}", .{ shared.settings.gameSettings.resourceDirectory, parts.items[1] });

                const fff = try shared.utility.string.toSentinelConstU8(arena_allocator, textureFilename);
                std.debug.print("Loading texture: {s}\n", .{textureFilename});

                npc.texture = raylib.loadTexture(std.mem.span(fff)) catch |err| {
                    std.debug.print("Failed to load texture {s}: {}\n", .{ textureFilename, err });
                    // Set a default/empty texture
                    npc.texture = raylib.Texture2D{ .id = 0, .width = 0, .height = 0, .mipmaps = 0, .format = .uncompressed_grayscale };
                    continue;
                };

                std.debug.print("Loaded texture: id={}, {}x{}\n", .{ npc.texture.id, npc.texture.width, npc.texture.height });
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
            try scene.loadedNPCs.append(npc);
        }
    }

    pub fn drawTrigger(self: *NPC, frame_allocator: std.mem.Allocator) void {
        _ = frame_allocator;
        if (!self.active) {
            return;
        }

        if (self.checkCollision(util.getViewingRay())) {
            types.ui.InteractInfo.drawUI(self.name);
        }
    }

    pub fn updateTrigger(self: *NPC, frame_allocator: std.mem.Allocator) anyerror!void {
        _ = frame_allocator;
        if (!self.active) {
            return;
        }
    }

    pub fn checkCollision(self: *NPC, ray: raylib.Ray) bool {
        var hit = false;

        const col: raylib.RayCollision = raylib.getRayCollisionBox(ray, self.boundingBox);

        if (col.hit) {
            const dis = util.vector3.distanceVector3_XZ(self.position, util.camera.position);
            if (dis < types.Constants.interactDistance) {
                hit = true;
            }
        }

        return hit;
    }
};
