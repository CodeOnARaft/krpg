const raylib = @import("raylib");
const std = @import("std");
const ArrayList = std.ArrayList;
const shared = @import("../root.zig");
const types = shared.types;
const map = shared.map;
const util = shared.utility;

pub const GameManager = struct {
    camera: *raylib.Camera3D = undefined,
    oldCameraPosition: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    currentScene: types.Scene = undefined,
    closeWindow: bool = false,
    console: types.Console = undefined,
    player: types.GameObjects.Player = undefined,
    model: raylib.Model = undefined,

    pub fn initialize(self: *GameManager) !void {
        self.console = types.Console{};
        self.console.init(self);
        self.camera = &util.camera;

        self.oldCameraPosition = self.camera.position;

        try shared.settings.gameSettings.init();

        const basicScene = try util.string.constU8toU8("overworld");
        const loadedScene = try types.Scene.load(basicScene);
        if (loadedScene == null) {
            self.closeWindow = true;
            return;
        }

        self.currentScene = loadedScene.?;

        self.currentScene.UpdateCameraPosition(self.camera);

        self.player = types.GameObjects.Player{};
        self.player.init(self);

        // Test model from https://www.fab.com/listings/c31a5416-5ed9-48a3-8070-280884403fc8
        self.model = try raylib.loadModel("resources/barrel.glb"); // Load model
        const texture = try raylib.loadTexture("resources/T_Barrel_BaseColor.png"); // Load model texture
        self.model.materials[0].maps[0].texture = texture; // Set map diffuse texture

    }

    pub fn update(self: *GameManager) void {
        if (self.closeWindow) {
            return;
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.f5)) {
            shared.settings.gameSettings.debug = !shared.settings.gameSettings.debug;
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.grave)) {
            self.console.consoleToggle();
        }

        self.player.update();

        if (!shared.settings.gameSettings.paused) {
            self.camera.update(.first_person);
            self.camera.up = raylib.Vector3.init(0, 1, 0);

            if (!util.vector3.areEqual(self.camera.position, self.oldCameraPosition)) {
                self.currentScene.UpdateCameraPosition(self.camera);
                self.oldCameraPosition = self.camera.position;
            }
        }

        self.currentScene.update();
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

            raylib.drawModel(self.model, raylib.Vector3{ .x = 12, .y = self.currentScene.GetYValueBasedOnLocation(12, 12) + 1.5, .z = 12 }, 0.5, raylib.Color.white); // Draw 3d model with texture
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
