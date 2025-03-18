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
    inventory: types.GameObjects.Inventory = undefined,

    pub fn initialize(self: *GameManager) !void {
        self.console = types.Console{};
        self.console.init(self);
        self.camera = &util.camera;

        self.oldCameraPosition = self.camera.position;

        try shared.settings.gameSettings.init();

        const loadedScene = try types.Scene.load("overworld.scn");
        if (loadedScene == null) {
            self.closeWindow = true;
            return;
        }

        self.currentScene = loadedScene.?;
        self.currentScene.camera = self.camera;
        self.currentScene.resetCameraPosition(self.camera);

        self.player = types.GameObjects.Player{};
        self.player.init(self);

        self.inventory = types.GameObjects.Inventory{};
        self.inventory.init(self, 100);
    }

    pub fn update(self: *GameManager) void {
        if (self.closeWindow) {
            return;
        }

        if (self.inventory.open) {
            self.inventory.update();
            return;
        }

        if (raylib.isKeyReleased(.f5)) {
            shared.settings.gameSettings.debug = !shared.settings.gameSettings.debug;
        }

        if (raylib.isKeyReleased(.grave)) {
            self.console.consoleToggle();
        }

        if (raylib.isKeyReleased(.i)) {
            self.inventory.open = !self.inventory.open;
            return;
        }

        self.player.update();

        if (!shared.settings.gameSettings.paused) {
            self.camera.update(.first_person);
            self.camera.up = raylib.Vector3.init(0, 1, 0);

            if (!util.vector3.areEqual(self.camera.position, self.oldCameraPosition)) {
                self.currentScene.updateCameraPosition(self.camera);
                self.oldCameraPosition = self.camera.position;
            }
        }

        self.currentScene.update();
    }

    pub fn draw(self: *GameManager) void {
        if (self.closeWindow) {
            return;
        }

        if (self.inventory.open) {
            self.inventory.draw();
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
