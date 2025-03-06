const std = @import("std");
const raylib = @import("raylib");

pub const Cube = struct {
    position: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    width: f32 = 1,
    height: f32 = 1,
    depth: f32 = 1,

    pub fn draw(self: Cube, color: raylib.Color, wireFrame: bool) void {
        std.debug.print("Drawing cube\n", .{});
        std.debug.print("Position: {} {} {}\n", .{ self.position.x, self.position.y, self.position.z });
        std.debug.print("Width: {}\n", .{self.width});
        std.debug.print("Height: {}\n", .{self.height});
        std.debug.print("Depth: {}\n", .{self.depth});
        if (wireFrame) {
            raylib.drawCubeWires(self.position, self.width, self.height, self.depth, color);
            return;
        }

        raylib.drawCube(self.position, self.width, self.height, self.depth, color);
    }
};
