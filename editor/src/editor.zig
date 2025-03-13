const raylib = @import("raylib");
const raygui = @import("raygui");
const ui = @import("ui/_ui.zig");

pub const Editor = struct {
    state: EditorState = .Editing,
    camera: raylib.Camera3D = undefined,
    openFile: bool = false,
    menu: ui.Menu = undefined,
    w: f32 = 1280.0,
    h: f32 = 720.0,
    pub fn init(self: *Editor) void {
        self.menu = ui.Menu{};
        self.menu.init();

        self.camera = raylib.Camera3D{
            .position = raylib.Vector3.init(20, 25, 20),
            .target = raylib.Vector3.init(30, 30, 30),
            .up = raylib.Vector3.init(0, 1, 0),
            .fovy = 60,
            .projection = .perspective,
        };
    }

    pub fn update(self: *Editor) !void {
        const handled = self.menu.update();
        if (self.state == EditorState.Editing) {
            if (!handled and raylib.isMouseButtonReleased(.left)) {
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

    pub fn draw(self: *Editor) void {
        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        {
            self.camera.begin();
            defer self.camera.end();

            raylib.drawGrid(100, 10);
        }
        self.menu.draw();

        if (self.state == EditorState.Interacting) {
            _ = raygui.guiStatusBar(raylib.Rectangle{ .x = 0.0, .y = self.h - 25.0, .height = 25.0, .width = self.w }, "Press ESC to edit.");
        }
    }
};

pub const EditorState = enum {
    Interacting,
    Editing,
};
