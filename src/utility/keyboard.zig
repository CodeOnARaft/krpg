const raylib = @import("raylib");
const std = @import("std");

const CharValue = struct {
    value: u8 = 0,
    isPressed: bool = false,
};

var lastKeyCode: raylib.KeyboardKey = raylib.KeyboardKey.null;
pub fn findKeyReleased() CharValue {
    if (lastKeyCode == raylib.KeyboardKey.null) {
        lastKeyCode = raylib.getKeyPressed();
    }

    if (raylib.isKeyReleased(lastKeyCode)) {
        std.debug.print("Key released: {}\n", .{lastKeyCode});
        const val: i32 = @intFromEnum(lastKeyCode);
        lastKeyCode = raylib.KeyboardKey.null;
        return CharValue{ .value = @intCast(val), .isPressed = true };
    }

    return CharValue{ .value = 0, .isPressed = false };
}
