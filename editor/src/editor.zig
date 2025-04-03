const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const ui = @import("ui/_ui.zig");
const shared = @import("shared");
const types = shared.types;
const util = shared.utility;

pub const EditorWindow = struct {
    state: EditorState = .Grab,
    camera: raylib.Camera3D = undefined,
    cameraSlideSpeed: f32 = 15.0,
    // openFile: bool = false,
    menu: ui.Menu = undefined,
    sceneWindow: ui.SceneWindow = undefined,
    propertyWindow: ui.PropertiesWindow = undefined,
    currentScene: types.Scene = undefined,
    sceneLoaded: bool = false,
    ofd: ui.dialog.OpenFileDialog = undefined,
    mb: ui.dialog.MessageBox = undefined,
    module: bool = false,
    objectManager: shared.managers.ObjectsManager = undefined,
    selectedObject: types.interfaces.EditorSelectedInterface = undefined,
    objectSelected: bool = false,

    mouseDragLook: bool = false,
    mouseDragStart: raylib.Vector2 = undefined,

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

        self.mb = ui.dialog.MessageBox{};
        try self.mb.init(self);

        self.objectManager = shared.managers.ObjectsManager{};
        try self.objectManager.init();
    }

    pub fn mbCallback(dd: *ui.dialog.MessageBox, result: i32) anyerror!void {
        dd.editor.module = false;
        if (result == 0) {
            std.debug.print("OK pressed\n", .{});
        } else if (result == 1) {
            std.debug.print("Cancel pressed\n", .{});
        } else if (result == 2) {
            std.debug.print("Yes pressed\n", .{});
        } else if (result == 3) {
            std.debug.print("No pressed\n", .{});
        }
    }

    pub fn update(self: *EditorWindow) !void {
        var handled = try self.ofd.update();
        handled = try self.mb.update() or handled;
        if (handled) {
            return;
        }

        handled = try self.menu.update();
        handled = self.sceneWindow.update() or handled;
        handled = self.propertyWindow.update() or handled;

        if (self.mouseDragLook and raylib.isMouseButtonReleased(.right)) {
            self.mouseDragLook = false;
        } else if (self.mouseDragLook) {
            self.camera.update(.free);
        }

        if (!handled and mouseInEditorWindow()) {
            if (raylib.isMouseButtonPressed(.right)) {
                self.mouseDragLook = true;
            } else {
                switch (self.state) {
                    EditorState.Grab => {
                        if (raylib.isMouseButtonPressed(.left)) {
                            self.mouseDragStart = raylib.getMousePosition();
                        } else if (raylib.isMouseButtonDown(.left)) {
                            const mouse = raylib.getMousePosition();
                            // const delta = shared.utility.vector2.subtract(mouse, self.mouseDragStart);

                            self.mouseDragStart = mouse;
                        }
                    },
                    EditorState.Move => {
                        if (raylib.isKeyDown(.up)) {
                            const direction = raylib.Vector3{
                                .x = self.camera.position.x - self.camera.target.x,
                                .y = self.camera.position.y - self.camera.target.y,
                                .z = self.camera.position.z - self.camera.target.z,
                            };
                            const normal = shared.utility.vector3.scale(shared.utility.vector3.normalize(direction), -raylib.getFrameTime() * self.cameraSlideSpeed);
                            self.camera.position = shared.utility.vector3.add(self.camera.position, normal);
                            self.camera.target = shared.utility.vector3.add(self.camera.target, normal);
                        } else if (raylib.isKeyDown(.down)) {
                            const direction = raylib.Vector3{
                                .x = self.camera.position.x - self.camera.target.x,
                                .y = self.camera.position.y - self.camera.target.y,
                                .z = self.camera.position.z - self.camera.target.z,
                            };
                            const normal = shared.utility.vector3.scale(shared.utility.vector3.normalize(direction), raylib.getFrameTime() * self.cameraSlideSpeed);
                            self.camera.position = shared.utility.vector3.add(self.camera.position, normal);
                            self.camera.target = shared.utility.vector3.add(self.camera.target, normal);
                        } else if (raylib.isKeyDown(.left)) {
                            const forward = shared.utility.vector3.normalize(raylib.Vector3{
                                .x = self.camera.target.x - self.camera.position.x,
                                .y = self.camera.target.y - self.camera.position.y,
                                .z = self.camera.target.z - self.camera.position.z,
                            });
                            const right = shared.utility.vector3.normalize(shared.utility.vector3.cross(forward, self.camera.up));
                            const movement = shared.utility.vector3.scale(right, -raylib.getFrameTime() * self.cameraSlideSpeed);
                            self.camera.position = shared.utility.vector3.add(self.camera.position, movement);
                            self.camera.target = shared.utility.vector3.add(self.camera.target, movement);
                        } else if (raylib.isKeyDown(.right)) {
                            const forward = shared.utility.vector3.normalize(raylib.Vector3{
                                .x = self.camera.target.x - self.camera.position.x,
                                .y = self.camera.target.y - self.camera.position.y,
                                .z = self.camera.target.z - self.camera.position.z,
                            });
                            const right = shared.utility.vector3.normalize(shared.utility.vector3.cross(forward, self.camera.up));
                            const movement = shared.utility.vector3.scale(right, raylib.getFrameTime() * self.cameraSlideSpeed);
                            self.camera.position = shared.utility.vector3.add(self.camera.position, movement);
                            self.camera.target = shared.utility.vector3.add(self.camera.target, movement);
                        }
                    },
                }
            }
        }
    }

    pub fn setState(self: *EditorWindow, state: EditorState) void {
        self.state = state;
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

        if (self.module) {
            _ = raygui.guiUnlock();
        }
        if (self.module and self.ofd.open) {
            try self.ofd.draw();
        }

        if (self.module and self.mb.open) {
            try self.mb.draw();
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
                //std.debug.print("Failed to load scene\n", .{});
                dialog.editor.showMessageBox("Error", "Failed to load scene", ui.dialog.MessageBoxType.Error) catch unreachable;
            }
        } else {
            //std.debug.print("Invalid file type\n", .{});
            dialog.editor.showMessageBox("Error", "Invalid file type", ui.dialog.MessageBoxType.Error) catch unreachable;
        }

        std.debug.print("File: {s}\n", .{file});
    }

    pub fn showMessageBox(self: *EditorWindow, title: [:0]const u8, message: [:0]const u8, mbtype: ui.dialog.MessageBoxType) anyerror!void {
        self.module = true;
        try self.mb.openDialog(title, message, mbtype, &mbCallback);
    }
};

pub const EditorState = enum {
    Grab,
    Move,
};
