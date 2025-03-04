const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const map = @import("map");
const settings = @import("settings");
const types = @import("types");

pub const GameManager = struct {
    showDebug: bool = false,
    camera: *raylib.Camera3D = undefined,
    oldCameraPosition: raylib.Vector3 = raylib.Vector3{ .x = 0, .y = 0, .z = 0 },

    pub fn initialize(self: *GameManager) void {
        self.camera = &util.camera;
        map.SetupGround();
        map.UpdateCameraPosition(self.camera);
        self.oldCameraPosition = self.camera.position;
    }

    pub fn update(self: *GameManager) void {
        if (raylib.isKeyReleased(raylib.KeyboardKey.f5)) {
            self.showDebug = !self.showDebug;
        }

        settings.gameSettings.update();

        if (!settings.gameSettings.paused) {
            self.camera.update(.first_person);
            self.camera.up = raylib.Vector3.init(0, 1, 0);

            if (!util.Vector3sAreEqual(self.camera.position, self.oldCameraPosition)) {
                map.UpdateCameraPosition(self.camera);
                self.oldCameraPosition = self.camera.position;
            }
        }
    }

    pub fn draw(self: *GameManager) void {
        self.camera.begin();
        defer self.camera.end();

        // Draw ground
        map.DrawGround();
    }

    pub fn drawUI(self: *GameManager) void {
        settings.drawConsole();
        if (self.showDebug) {
            raylib.drawRectangle(10, 10, 220, 70, raylib.Color.sky_blue.fade(0.5));
            raylib.drawRectangleLines(10, 10, 220, 70, raylib.Color.blue);

            raylib.drawFPS(5, 5);
        }
    }
};
