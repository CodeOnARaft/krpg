const raylib = @import("raylib");
const std = @import("std");
const types = @import("types");

var lastKeyCode: raylib.KeyboardKey = raylib.KeyboardKey.null;
var lastRead: f32 = 0.0;
pub fn findKeyReleased() types.CharValue {
    lastRead += raylib.getFrameTime();
    if (lastKeyCode == raylib.KeyboardKey.null or lastRead > 1.0) {
        lastKeyCode = raylib.getKeyPressed();
        lastRead = 0.0;
    }

    if (raylib.isKeyReleased(lastKeyCode)) {
        std.debug.print("Key released: {}\n", .{lastKeyCode});

        if (lastKeyCode == raylib.KeyboardKey.backspace) {
            lastKeyCode = raylib.KeyboardKey.null;
            return types.CharValue{ .value = 0, .isPressed = true, .isBackspace = true };
        }

        if (lastKeyCode == raylib.KeyboardKey.enter) {
            lastKeyCode = raylib.KeyboardKey.null;
            return types.CharValue{ .value = 0, .isPressed = true, .isEnter = true };
        }

        const val: i32 = @intFromEnum(lastKeyCode);
        lastKeyCode = raylib.KeyboardKey.null;

        if (val == 32 or (val >= 32 and val <= 126)) {
            return types.CharValue{ .value = @intCast(val), .isPressed = true };
        }
    } else {
        std.debug.print("Key wait: {}\n", .{lastKeyCode});
    }

    return types.CharValue{ .value = 0, .isPressed = false };
}
