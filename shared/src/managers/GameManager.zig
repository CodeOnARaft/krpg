const raylib = @import("raylib");
const std = @import("std");
const ArrayList = std.ArrayList;
const shared = @import("../root.zig");
const types = shared.types;
const map = shared.map;
const util = shared.utility;
const interfaces = types.interfaces;

pub const GameManager = struct {
    camera: *raylib.Camera3D = undefined,
    oldCameraPosition: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    currentScene: types.Scene = undefined,
    closeWindow: bool = false,
    console: types.Console = undefined,
    player: types.GameObjects.Player = undefined,
    inventory: types.GameObjects.Inventory = undefined,
    activeView: interfaces.ActiveViewInterface = undefined,

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
        self.currentScene.gameManager = self;
        self.activeView = interfaces.ActiveViewInterface.init(&self.currentScene);

        self.player = types.GameObjects.Player{};
        self.player.init(self);

        self.inventory = types.GameObjects.Inventory{};
        self.inventory.init(self, 100);
    }

    pub fn changeView(self: *GameManager, view: types.Views) anyerror!void {
        switch (view) {
            types.Views.Scene => {
                self.activeView = interfaces.ActiveViewInterface.init(&self.currentScene);
            },
            types.Views.Inventory => {
                self.activeView = interfaces.ActiveViewInterface.init(&self.inventory);
            },
            types.Views.Character => {
                self.activeView = interfaces.ActiveViewInterface.init(&self.player);
            },
        }
    }

    pub fn update(self: *GameManager) anyerror!void {
        if (self.closeWindow) {
            return;
        }

        if (raylib.isKeyReleased(.f5)) {
            shared.settings.gameSettings.debug = !shared.settings.gameSettings.debug;
        }

        if (raylib.isKeyReleased(.grave)) {
            self.console.consoleToggle();
        }

        try self.activeView.update();
    }

    pub fn draw(self: *GameManager) anyerror!void {
        if (self.closeWindow) {
            return;
        }

        try self.activeView.draw();

        self.console.drawConsole();
    }
};
