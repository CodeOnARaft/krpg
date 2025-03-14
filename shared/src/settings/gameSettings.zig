const raylib = @import("raylib");
const std = @import("std");
const ArrayList = std.ArrayList;
const util = @import("../utility/_utility.zig");

const Settings = struct {
    paused: bool = false,
    debug: bool = false,
    editing: bool = false,
    resourceDirectory: []const u8 = undefined,

    pub fn init(self: *Settings) !void {
        self.paused = false;
        self.debug = false;
        self.editing = false;

        try self.LoadConfig();
    }

    fn LoadConfig(self: *Settings) !void {
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

            std.debug.print("Command: {s}: length: {}\n", .{ parts.items[0], parts.items.len });
            if (std.mem.eql(u8, parts.items[0], "resources")) {
                self.resourceDirectory = parts.items[1];
            }
        }
    }
};

pub var gameSettings = Settings{};
