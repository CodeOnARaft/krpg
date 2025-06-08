const raylib = @import("raylib");
const std = @import("std");
const ArrayList = std.ArrayList;
const util = @import("../utility/_utility.zig");

const Settings = struct {
    paused: bool = false,
    debug: bool = false,
    editing: bool = false,
    resourceDirectory: []const u8 = undefined,

    pub fn init(self: *Settings, allocator: std.mem.Allocator) !void {
        self.paused = false;
        self.debug = false;
        self.editing = false;

        try self.LoadConfig(allocator);
    }

    fn LoadConfig(self: *Settings, allocator: std.mem.Allocator) !void {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const arena_allocator = arena.allocator();

        const cwd = std.fs.cwd();
        const file = cwd.openFile("config.cfg", std.fs.File.OpenFlags{}) catch |err| {
            std.debug.print("Error opening file: {}\n", .{err});
            return;
        };
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var parts: ArrayList([]u8) = ArrayList([]u8).init(arena_allocator);
            defer parts.deinit();
            var it = std.mem.splitScalar(u8, line, ' ');

            while (it.next()) |commandPart| {
                const partU8 = try util.string.constU8toU8(arena_allocator, commandPart);
                try parts.append(partU8);
            }

            if (parts.items.len == 0) {
                std.debug.print("Empty line\n", .{});
                continue;
            }

            std.debug.print("Command: {s}: length: {}\n", .{ parts.items[0], parts.items.len });
            if (std.mem.eql(u8, parts.items[0], "resources")) {
                const name_copy = try allocator.dupe(u8, parts.items[1]);
                self.resourceDirectory = name_copy;
            }
        }
    }
};

pub var gameSettings = Settings{};
