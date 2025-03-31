const raylib = @import("raylib");
const std = @import("std");
const ArrayList = std.ArrayList;
const shared = @import("../root.zig");
const types = shared.types;
const managers = shared.managers;
const basic = types.Basic;
const util = shared.utility;
const map = shared.map;

const SceneTypes = enum {
    Blank,
    Game,
    Dialog,
    Menu,
};

pub const Scene = struct {
    id: []const u8 = undefined,
    sceneType: SceneTypes = SceneTypes.Blank,
    loadedSectors: ArrayList(types.GroundSector) = undefined,
    loadedNPCs: ArrayList(types.GameObjects.NPC) = undefined,
    loadedObjects: ArrayList(types.GameObjects.ObjectInstance) = undefined,
    startLocation: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    currentTrigger: *types.Trigger = types.emptyTriggerPtr,
    camera: *raylib.Camera3D = undefined,
    gameManager: *managers.GameManager = undefined,
    objectManager: *managers.ObjectsManager = undefined,

    pub fn new() !Scene {
        const blankName = try util.string.constU8toU8("_blank");
        return Scene{ .id = blankName, .loadedSectors = ArrayList(types.GroundSector).init(std.heap.page_allocator), .loadedObjects = ArrayList(types.GameObjects.ObjectInstance).init(std.heap.page_allocator), .loadedNPCs = ArrayList(types.GameObjects.NPC).init(std.heap.page_allocator) };
    }

    pub fn load(scene_name: []const u8, objectManager: *shared.managers.ObjectsManager) !?Scene {
        var scene = try new();
        scene.objectManager = objectManager;
        scene.currentTrigger = types.emptyTriggerPtr;

        const cwd = std.fs.cwd();
        const allocator = std.heap.page_allocator;
        const filename = try std.fmt.allocPrint(allocator, "{s}/map/{s}", .{ shared.settings.gameSettings.resourceDirectory, scene_name });
        std.debug.print("Loading scene: {s}\n", .{filename});
        defer allocator.free(filename);

        const file = cwd.openFile(filename, std.fs.File.OpenFlags{}) catch |err| {
            std.debug.print("Error opening file: {s},{}\n", .{ filename, err });
            return scene;
        };
        defer file.close();

        var it1 = std.mem.splitScalar(u8, scene_name, '.');
        var index: i32 = 0;
        var sc_fn: []const u8 = "";
        while (it1.next()) |commandPart| {
            if (index == 0) {
                sc_fn = commandPart;
            }
            index += 1;
        }

        scene.id = scene_name;

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var parts: ArrayList([]u8) = ArrayList([]u8).init(std.heap.page_allocator);
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

            // std.debug.print("Command: {s}: length: {}\n", .{ parts.items[0], parts.items.len });
            if (std.mem.eql(u8, parts.items[0], "start")) {
                const startx = std.fmt.parseFloat(f32, parts.items[1]) catch |err| {
                    std.debug.print("Error parsing x: {}\n", .{err});
                    return null;
                };
                const starty = std.fmt.parseFloat(f32, parts.items[2]) catch |err| {
                    std.debug.print("Error parsing y: {}\n", .{err});
                    return null;
                };
                const startz = std.fmt.parseFloat(f32, parts.items[3]) catch |err| {
                    std.debug.print("Error parsing z: {s} {}\n", .{ parts.items[3], err });
                    return null;
                };

                std.debug.print("Start location: {} {} {}\n", .{ startx, starty, startz });

                scene.startLocation = raylib.Vector3{ .x = startx, .y = starty, .z = startz };

                std.debug.print("Start location: {} {} {}\n", .{ startx, starty, startz });
            } else if (std.mem.eql(u8, parts.items[0], "startSector")) {
                std.debug.print("Start sector\n", .{});

                const x = std.fmt.parseInt(i32, parts.items[1], 10) catch |err| {
                    std.debug.print("Error parsing x: {}\n", .{err});
                    return null;
                };
                const z = std.fmt.parseInt(i32, parts.items[2], 10) catch |err| {
                    std.debug.print("Error parsing z: {s} {}\n", .{ parts.items[2], err });
                    return null;
                };

                const sector = try map.LoadGroundSectorFromFile(sc_fn, x, z);

                if (sector == null) {
                    std.debug.print("Error loading sector: {} {}\n", .{ x, z });
                    return null;
                }

                std.debug.print("Loaded sector: {} {}\n", .{ sector.?.gridX, sector.?.gridZ });
                try scene.loadedSectors.append(sector.?);

                try types.GameObjects.NPC.load(sc_fn, x, z, &scene);
                try types.GameObjects.ObjectInstance.load(sc_fn, x, z, &scene);
            }
        }

        const startLocationY = scene.getYValueBasedOnLocation(scene.startLocation.x, scene.startLocation.z);
        scene.startLocation = raylib.Vector3{ .x = scene.startLocation.x, .y = startLocationY, .z = scene.startLocation.z };

        return scene;
    }

    pub fn resetCameraPosition(self: *Scene, camera: *raylib.Camera) void {
        const y = self.getYValueBasedOnLocation(self.startLocation.x, self.startLocation.z);
        camera.position = raylib.Vector3{ .x = self.startLocation.x, .y = y, .z = self.startLocation.z };
        camera.target = raylib.Vector3{ .x = self.startLocation.x + 1, .y = y, .z = self.startLocation.z + 1 };
    }

    pub fn updateCameraPosition(self: *Scene, camera: *raylib.Camera) void {
        const y = self.getYValueBasedOnLocation(camera.position.x, camera.position.z);
        camera.target.y = camera.target.y + (y - camera.position.y);
        camera.position.y = y;
    }

    pub fn getYValueBasedOnLocation(self: *Scene, x: f32, z: f32) f32 {
        // std.debug.print("Getting y value for x: {} z: {}\n", .{ x, z });
        if (self.loadedSectors.items.len == 0 or x <= 0 or z <= 0) {
            std.debug.print("No sectors loaded ({},{})\n", .{ x, z });
            return 0.0;
        }

        const fx = @floor(x);
        const fz = @floor(z);
        // std.debug.print("input x: {} z: {}\n", .{ fx, fz });

        const mx = fx - @mod(fx, types.GroundSectorSize);
        const mz = fz - @mod(fz, types.GroundSectorSize);
        // std.debug.print("mod x: {} z: {}\n", .{ mx, mz });

        const tilex: u32 = @intFromFloat(@floor(mx / types.GroundSectorSize));
        const tilez: u32 = @intFromFloat(@floor(mz / types.GroundSectorSize));

        for (0..self.loadedSectors.items.len) |index| {
            var sector = self.loadedSectors.items[index];
            if (sector.gridX == tilex and sector.gridZ == tilez) {
                const newY = sector.GetYValueBasedOnLocation(x, z);
                //std.debug.print("Found sector for x: {} z: {} y: {}\n", .{ x, z, newY });
                return newY;
            }
        }

        if (shared.settings.gameSettings.debug) {
            std.debug.print("No sector found for x: {} z: {}\n", .{ tilex, tilez });
            std.debug.print("input x: {} z: {}\n", .{ x, z });
        }
        return 0.0;
    }

    pub fn update(self: *Scene) anyerror!void {
        if (!shared.settings.gameSettings.paused and !shared.settings.gameSettings.editing) {
            self.gameManager.camera.update(.first_person);
            self.gameManager.camera.up = raylib.Vector3.init(0, 1, 0);

            if (!util.vector3.areEqual(self.gameManager.camera.position, self.gameManager.oldCameraPosition)) {
                self.updateCameraPosition(self.gameManager.camera);
                self.gameManager.oldCameraPosition = self.gameManager.camera.position;
            }
        }

        if (!shared.settings.gameSettings.editing) {
            if (raylib.isKeyReleased(.i)) {
                try self.gameManager.changeView(.Inventory);
            }

            if (raylib.isKeyReleased(.c)) {
                try self.gameManager.changeView(.Character);
            }

            if (raylib.isKeyReleased(raylib.KeyboardKey.e)) {
                if (self.currentTrigger.type != types.TriggerTypes.Empty) {
                    std.debug.print("Interacting with trigger: {s} \n", .{self.currentTrigger.description});
                    self.currentTrigger = types.emptyTriggerPtr;
                } else {
                    std.debug.print("No trigger to interact with\n", .{});
                }
            }
        }
    }

    pub fn draw(self: *Scene) anyerror!void {
        {
            if (!shared.settings.gameSettings.editing) {
                self.gameManager.camera.begin();
            }

            for (0..self.loadedSectors.items.len) |index| {
                self.loadedSectors.items[index].draw();
            }

            for (0..self.loadedObjects.items.len) |index| {
                try self.objectManager.drawObject(self.loadedObjects.items[index].name, self.loadedObjects.items[index].position);
            }

            if (shared.settings.gameSettings.editing) {
                const y = self.getYValueBasedOnLocation(self.startLocation.x, self.startLocation.z) + 1;
                raylib.drawSphere(raylib.Vector3{ .x = self.startLocation.x, .y = y, .z = self.startLocation.z }, 1, raylib.Color.red);
            }

            if (!shared.settings.gameSettings.editing) {
                self.gameManager.camera.end();
            }
        }

        self.drawUI();
    }

    pub fn drawUI(self: *Scene) void {
        if (shared.settings.gameSettings.editing) {
            return;
        }

        var i: usize = 0;
        while (i < self.loadedNPCs.items.len) : (i += 1) {
            if (self.loadedNPCs.items[i].trigger.checkCollision(util.getViewingRay())) {
                self.currentTrigger = &self.loadedNPCs.items[i].trigger;
                types.ui.InteractInfo.drawUI(@ptrCast(self.loadedNPCs.items[i].trigger.description));
            }
        }
    }
};
