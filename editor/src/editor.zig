const raylib = @import("raylib");
const raygui = @import("raygui");

pub const Editor = struct {
    state: EditorState = .Editing,
    camera: raylib.Camera3D = undefined,
    openFile: bool = false,
    w: f32 = 1280.0,
    h: f32 = 720.0,
    pub fn init(self: *Editor) void {
        self.camera = raylib.Camera3D{
            .position = raylib.Vector3.init(20, 25, 20),
            .target = raylib.Vector3.init(30, 30, 30),
            .up = raylib.Vector3.init(0, 1, 0),
            .fovy = 60,
            .projection = .perspective,
        };
    }

    pub fn update(self: *Editor) !void {
        if (self.state == EditorState.Editing) {
            if (raylib.isMouseButtonReleased(.left)) {
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
        self.drawMenu();

        if (self.state == EditorState.Interacting) {
            _ = raygui.guiStatusBar(raylib.Rectangle{ .x = 0.0, .y = self.h - 25.0, .height = 25.0, .width = self.w }, "Press ESC to edit.");
        }
    }

    fn drawMenu(self: *Editor) void {
        const style = raygui.guiGetStyle(raygui.GuiControl.default, raygui.GuiDefaultProperty.background_color);
        raylib.drawRectangle(0, 0, 1280, 25, raylib.fade(raylib.getColor(@intCast(style)), 1));

        const openIcon = @intFromEnum(raygui.GuiIconName.icon_file_open);
        raygui.guiDrawIcon(openIcon, 5, 5, 1, raylib.Color.gray);

        if (self.openFile) {
            if (raygui.guiWindowBox(raylib.Rectangle{ .x = 100, .y = 100, .height = 150, .width = 200 }, "Open Scene") != 0) {
                self.openFile = false;
            }
        }
    }
};

pub const EditorState = enum {
    Interacting,
    Editing,
};
