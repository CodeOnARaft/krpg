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
    model: raylib.Model = undefined,
    objectManager: shared.managers.ObjectsManager = undefined,
    gameTimeManager: shared.managers.GameTimeManager = undefined,

    pub fn initialize(self: *GameManager, allocator: std.mem.Allocator) !void {
        self.console = types.Console{};
        self.console.init(self);
        self.camera = &util.camera;

        self.oldCameraPosition = self.camera.position;

        try shared.settings.gameSettings.init(allocator);

        self.objectManager = shared.managers.ObjectsManager{};
        try self.objectManager.init(allocator);

        const loadedScene = try types.Scene.load(std.heap.page_allocator, "overworld.scn", &self.objectManager);
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

        self.gameTimeManager = shared.managers.GameTimeManager.init();
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
            types.Views.Map => {
                self.activeView = interfaces.ActiveViewInterface.init(&self.currentScene);
            },
        }
    }

    pub fn update(self: *GameManager, frame_allocator: std.mem.Allocator) anyerror!void {
        if (self.closeWindow) {
            return;
        }

        try self.gameTimeManager.update();

        if (raylib.isKeyReleased(.f5)) {
            shared.settings.gameSettings.debug = !shared.settings.gameSettings.debug;
        }

        if (raylib.isKeyReleased(.grave)) {
            self.console.consoleToggle();
        }

        if (!self.console.Visible()) {
            try self.activeView.update(frame_allocator);
        }
    }

    pub fn draw(self: *GameManager, frame_allocator: std.mem.Allocator) anyerror!void {
        if (self.closeWindow) {
            return;
        }

        try self.activeView.draw(frame_allocator);

        self.console.drawConsole();
    }
};
