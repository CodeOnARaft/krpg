const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const ArrayList = std.ArrayList;
const map = @import("map");
const settings = @import("settings");
const types = @import("types");

pub const GameManager = struct {
    camera: *raylib.Camera3D = undefined,
    oldCameraPosition: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    currentScene: types.Scene = undefined,
    closeWindow: bool = false,
    console: types.Console = undefined,
    player: types.GameObjects.Player = undefined,

    pub fn initialize(self: *GameManager) !void {
        self.console = types.Console{};
        self.console.init(self);
        self.camera = &util.camera;

        self.oldCameraPosition = self.camera.position;

        const basicScene = try util.String.constU8toU8("overworld");
        const loadedScene = try types.Scene.load(basicScene);
        if (loadedScene == null) {
            self.closeWindow = true;
            return;
        }

        self.currentScene = loadedScene.?;

        self.currentScene.UpdateCameraPosition(self.camera);

        self.player = types.GameObjects.Player{};
        self.player.init(self);
    }

    pub fn update(self: *GameManager) void {
        if (self.closeWindow) {
            return;
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.f5)) {
            settings.gameSettings.debug = !settings.gameSettings.debug;
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.grave)) {
            self.console.consoleToggle();
        }

        settings.gameSettings.update();
        self.player.update();

        if (!settings.gameSettings.paused) {
            self.camera.update(.first_person);
            self.camera.up = raylib.Vector3.init(0, 1, 0);

            if (!util.Vector3sAreEqual(self.camera.position, self.oldCameraPosition)) {
                self.currentScene.UpdateCameraPosition(self.camera);
                self.oldCameraPosition = self.camera.position;
            }
        }
    }

    pub fn draw(self: *GameManager) void {
        if (self.closeWindow) {
            return;
        }

        {
            self.camera.begin();
            defer self.camera.end();

            // Draw ground
            self.currentScene.draw();
        }

        self.drawUI();
    }

    pub fn drawUI(self: *GameManager) void {
        if (self.closeWindow) {
            return;
        }

        self.currentScene.drawUI();

        self.console.drawConsole();
    }
};
