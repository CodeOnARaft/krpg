const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const ui = @import("ui/_ui.zig");
const shared = @import("shared");
const types = shared.types;
const util = shared.utility;

pub const EditorWindow = struct {
    state: EditorState = .Editing,
    camera: raylib.Camera3D = undefined,
    // openFile: bool = false,
    menu: ui.Menu = undefined,
    sceneWindow: ui.SceneWindow = undefined,
    propertyWindow: ui.PropertiesWindow = undefined,
    currentScene: types.Scene = undefined,
    sceneLoaded: bool = false,
    ofd: ui.dialog.OpenFileDialog = undefined,
    module: bool = false,

    w: f32 = 1280.0,
    h: f32 = 720.0,
    pub fn init(self: *EditorWindow) !void {
        self.menu = ui.Menu{};
        self.menu.init(self);

        try shared.settings.gameSettings.init();
        shared.settings.gameSettings.editing = true;

        self.sceneWindow = ui.SceneWindow{};
        self.sceneWindow.init();

        self.propertyWindow = ui.PropertiesWindow{};
        self.propertyWindow.init();

        self.camera = raylib.Camera3D{
            .position = raylib.Vector3.init(20, 25, 20),
            .target = raylib.Vector3.init(30, 30, 30),
            .up = raylib.Vector3.init(0, 1, 0),
            .fovy = 60,
            .projection = .perspective,
        };

        util.camera = self.camera;

        // const basicScene = try util.string.constU8toU8("overworld");
        // const testScene = try types.Scene.load(basicScene);

        // if (testScene != null) {
        //     self.currentScene = testScene.?;
        //     self.sceneLoaded = true;
        //     self.currentScene.camera = &self.camera;
        // }

        self.ofd = ui.dialog.OpenFileDialog{};
        try self.ofd.init(self);
    }

    pub fn update(self: *EditorWindow) !void {
        var handled = try self.ofd.update();
        if (handled) {
            return;
        }

        handled = self.menu.update();
        handled = self.sceneWindow.update() or handled;
        handled = self.propertyWindow.update() or handled;

        if (self.state == EditorState.Editing) {
            if (!handled and mouseInEditorWindow() and raylib.isMouseButtonReleased(.left)) {
                self.state = EditorState.Interacting;
                raylib.hideCursor();
            }
        } else if (self.state == EditorState.Interacting) {
            self.camera.update(.free);
            if (raylib.isKeyPressed(.escape)) {
                self.state = EditorState.Editing;
                raylib.showCursor();
            }
        }
    }

    fn mouseInEditorWindow() bool {
        const mouse = raylib.getMousePosition();
        return raylib.checkCollisionPointRec(mouse, raylib.Rectangle{ .x = ui.Constants.SceneWidth, .y = ui.Constants.MenuHeightf, .height = @as(f32, @floatFromInt(raylib.getScreenHeight())) - ui.Constants.MenuHeightf, .width = @as(f32, @floatFromInt(raylib.getScreenWidth())) - (ui.Constants.SceneWidth * 2) });
    }

    pub fn draw(self: *EditorWindow) !void {
        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        {
            self.camera.begin();
            defer self.camera.end();
            if (self.sceneLoaded) {
                self.currentScene.draw();
            }
            raylib.drawGrid(100, 10);
        }

        if (self.module) {
            _ = raygui.guiLock();
        }
        self.menu.draw();
        self.sceneWindow.draw();
        self.propertyWindow.draw();

        if (self.state == EditorState.Interacting) {
            _ = raygui.guiStatusBar(raylib.Rectangle{ .x = 0.0, .y = self.h - 25.0, .height = 25.0, .width = self.w }, "Press ESC to edit.");
        }

        if (self.module) {
            _ = raygui.guiUnlock();
        }
        if (self.module and self.ofd.open) {
            try self.ofd.draw();
        }
    }

    pub fn openFile(self: *EditorWindow) !void {
        self.module = true;
        try self.ofd.openDialog(&openFileCallback);
    }

    pub fn openFileCallback(dialog: *ui.dialog.OpenFileDialog, file: []const u8) anyerror!void {
        dialog.editor.module = false;

        const testScene = try types.Scene.load(file);
        if (testScene != null) {
            dialog.editor.currentScene = testScene.?;
            dialog.editor.sceneLoaded = true;
        }
    }
};

pub const EditorState = enum {
    Interacting,
    Editing,
};
