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
    objectManager: shared.managers.ObjectsManager = undefined,
    selectedObject: types.interfaces.EditorSelectedInterface = undefined,
    objectSelected: bool = false,

    w: f32 = 1280.0,
    h: f32 = 720.0,
    pub fn init(self: *EditorWindow) !void {
        self.menu = ui.Menu{};
        self.menu.init(self);

        try shared.settings.gameSettings.init();
        shared.settings.gameSettings.editing = true;

        self.sceneWindow = ui.SceneWindow{};
        self.sceneWindow.init(self);

        self.propertyWindow = ui.PropertiesWindow{};
        self.propertyWindow.init(self);

        self.camera = raylib.Camera3D{
            .position = raylib.Vector3.init(20, 25, 20),
            .target = raylib.Vector3.init(30, 30, 30),
            .up = raylib.Vector3.init(0, 1, 0),
            .fovy = 60,
            .projection = .perspective,
        };

        util.camera = self.camera;

        self.ofd = ui.dialog.OpenFileDialog{};
        try self.ofd.init(self);

        self.objectManager = shared.managers.ObjectsManager{};
        try self.objectManager.init();
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
                try self.currentScene.draw();
                if (self.objectSelected) {
                    try self.selectedObject.drawSelected();
                }
            }
            raylib.drawGrid(100, 10);
        }

        if (self.module) {
            _ = raygui.guiLock();
        }
        self.menu.draw();
        try self.sceneWindow.draw();
        try self.propertyWindow.draw();

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
        try self.ofd.openDialog(&openSceneFileCallback);
    }

    pub fn openSceneFileCallback(dialog: *ui.dialog.OpenFileDialog, file: []const u8) anyerror!void {
        dialog.editor.module = false;

        if (std.mem.endsWith(u8, file, ".scn")) {
            const testScene = try types.Scene.load(file, &dialog.editor.objectManager);
            if (testScene != null) {
                dialog.editor.currentScene = testScene.?;
                dialog.editor.sceneLoaded = true;

                std.debug.print("Loaded scene\n", .{});
            } else {
                std.debug.print("Failed to load scene\n", .{});
            }
        } else {
            std.debug.print("Invalid file type\n", .{});
        }

        std.debug.print("File: {s}\n", .{file});
    }
};

pub const EditorState = enum {
    Interacting,
    Editing,
};
