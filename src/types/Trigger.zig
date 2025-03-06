const types = @import("types");
const std = @import("std");
const raylib = @import("raylib");

pub const TriggerTypes = enum {
    Test,
    SceneChange,
    Conversation,
};

pub const Trigger = struct {
    type: TriggerTypes = TriggerTypes.Test,
    boundingBox: types.Cube = undefined,
    description: []const u8 = "",

    pub fn draw(self: *Trigger) void {
        raylib.drawCubeWires(self.boundingBox.position, self.boundingBox.width, self.boundingBox.height, self.boundingBox.depth, raylib.Color.blue);
    }
};
