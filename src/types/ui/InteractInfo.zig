const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const types = @import("types");

pub const InteractInfo = struct {
    pub fn drawUI(message: []u8) void {
        const dialogWidth: f32 = 200.0;
        const x = types.Constants.screenWidth / 2 - dialogWidth / 2;
        raylib.drawRectangle(x, 10, dialogWidth, 70, raylib.Color.beige.fade(0.75));
        raylib.drawRectangleLinesEx(raylib.Rectangle{ .x = x, .y = 10, .width = dialogWidth, .height = 70 }, 3, raylib.Color.dark_brown);
        raylib.drawText(@ptrCast(message), x + 20, 20, 24, raylib.Color.black);
    }
};
