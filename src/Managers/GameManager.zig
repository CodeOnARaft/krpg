const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const ArrayList = std.ArrayList;
const map = @import("map");
const settings = @import("settings");
const types = @import("types");

var mary: types.NPC = types.NPC{
    .name = "Mary",
    .position = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    .active = true,
};

pub const GameManager = struct {
    showDebug: bool = false,
    camera: *raylib.Camera3D = undefined,
    oldCameraPosition: raylib.Vector3 = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
    npcs: ArrayList(types.NPC) = ArrayList(types.NPC).init(std.heap.page_allocator),
    currentScene: types.Scene = undefined,
    closeWindow: bool = false,
    console: types.Console = undefined,

    pub fn initialize(self: *GameManager) !void {
        self.console = types.Console{};
        self.console.init(self);
        self.camera = &util.camera;

        self.oldCameraPosition = self.camera.position;

        const basicScene = try util.constU8toU8("overworld");
        const loadedScene = try types.Scene.load(basicScene);
        if (loadedScene == null) {
            self.closeWindow = true;
            return;
        }

        self.currentScene = loadedScene.?;

        self.currentScene.UpdateCameraPosition(self.camera);
        mary.texture = try raylib.loadTexture("resources/npc.png");
        //const marytextureheight: f32 = @floatFromInt(mary.texture.height);
        const maryY = self.currentScene.GetYValueBasedOnLocation(10, 10);
        mary.setPosition(10, maryY, 10);
        try self.npcs.append(mary);
    }

    pub fn update(self: *GameManager) void {
        if (self.closeWindow) {
            return;
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.f5)) {
            self.showDebug = !self.showDebug;
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.grave)) {
            self.console.consoleToggle();
        }

        settings.gameSettings.update();

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
            self.currentScene.draw(self.camera);

            var i: usize = 0;
            while (i < self.npcs.items.len) : (i += 1) {
                self.npcs.items[i].draw(util.camera, self.showDebug);
            }
        }

        self.drawUI();
    }

    pub fn drawUI(self: *GameManager) void {
        if (self.closeWindow) {
            return;
        }

        if (self.showDebug) {
            raylib.drawRectangle(10, 10, 220, 70, raylib.Color.sky_blue.fade(0.5));
            raylib.drawRectangleLines(10, 10, 220, 70, raylib.Color.blue);

            raylib.drawFPS(5, 5);
        }

        self.console.drawConsole();
    }
};
