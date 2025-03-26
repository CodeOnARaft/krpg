const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Constants = @import("Constants.zig");
const edW = @import("../editor.zig");
const shared = @import("shared");

pub const SceneWindowObjectView = enum {
    Objects,
    NPCs,
    Triggers,
};

pub const SceneWindow = struct {
    windowLocation: raylib.Rectangle = undefined,
    ddActive: i32 = 0,
    ddEditMode: bool = false,
    view: SceneWindowObjectView = SceneWindowObjectView.Objects,
    editor: *edW.EditorWindow = undefined,

    pub fn init(self: *SceneWindow, editor: *edW.EditorWindow) void {
        self.editor = editor;
        self.windowLocation = raylib.Rectangle{ .x = 0, .y = Constants.MenuHeight, .height = @as(f32, @floatFromInt(raylib.getScreenHeight())) - Constants.MenuHeightf, .width = Constants.SceneWidth };
    }

    pub fn update(self: *SceneWindow) bool {
        const mouse = raylib.getMousePosition();

        return raylib.checkCollisionPointRec(mouse, self.windowLocation);
    }

    pub fn draw(self: *SceneWindow) !void {
        var vec2 = raylib.Vector2{ .x = 0, .y = 0 };
        var rec2 = raylib.Rectangle{ .x = self.windowLocation.x + 5.0, .y = self.windowLocation.y + 5.0, .height = self.windowLocation.height - 10.0, .width = self.windowLocation.width - 10.0 };
        if (raygui.guiScrollPanel(self.windowLocation, "Scene", rec2, &vec2, &rec2) > 0) {}

        const ddBounds = raylib.Rectangle{ .x = self.windowLocation.x + 10, .y = self.windowLocation.y + 30, .height = 20, .width = self.windowLocation.width - 30.0 };
        const ddValue = raygui.guiDropdownBox(ddBounds, "Objects;NPCs;Triggers", &self.ddActive, self.ddEditMode);
        if (ddValue > 0) {
            self.ddEditMode = !self.ddEditMode;
            self.editor.objectSelected = false;
            switch (self.ddActive) {
                0 => {
                    self.view = SceneWindowObjectView.Objects;
                },
                1 => {
                    self.view = SceneWindowObjectView.NPCs;
                },
                2 => {
                    self.view = SceneWindowObjectView.Triggers;
                },

                else => {
                    self.view = SceneWindowObjectView.Objects;
                },
            }
            std.debug.print("Dropdown value: {}\n", .{ddValue});
            std.debug.print("Dropdown active: {}\n", .{self.ddActive});
            std.debug.print("Dropdown edit mode: {}\n", .{self.ddEditMode});
        }

        switch (self.view) {
            SceneWindowObjectView.Objects => try self.drawObjects(),
            SceneWindowObjectView.NPCs => self.drawNPCs(),
            SceneWindowObjectView.Triggers => self.drawTriggers(),
        }
    }

    fn drawObjects(self: *SceneWindow) !void {
        const allocator = std.heap.page_allocator;
        var y = self.windowLocation.y + 60;
        var i: usize = 0;
        for (self.editor.currentScene.loadedObjects.items) |obj| {
            const labelPosition = raylib.Rectangle{ .x = 10, .y = y, .height = 20, .width = 100 };
            const buffer = try allocator.allocSentinel(u8, obj.name.len, 0);
            std.mem.copyForwards(u8, buffer[0..obj.name.len], obj.name);
            _ = raygui.guiLabel(labelPosition, buffer);
            allocator.free(buffer);
            if (raylib.checkCollisionPointRec(raylib.getMousePosition(), labelPosition)) {
                if (raylib.isMouseButtonReleased(.left)) {
                    std.debug.print("Object selected: {s}\n", .{obj.name});
                    self.editor.objectSelected = true;
                    self.editor.selectedObject = shared.types.interfaces.EditorSelectedInterface.init(&self.editor.currentScene.loadedObjects.items[i]);
                }
            }
            y += 30;
            i += 1;
        }
    }

    fn drawNPCs(self: *SceneWindow) void {
        _ = raygui.guiLabel(raylib.Rectangle{ .x = 10, .y = 60, .height = 20, .width = 100 }, "NPCs");
        _ = self.ddActive;
    }

    fn drawTriggers(self: *SceneWindow) void {
        _ = raygui.guiLabel(raylib.Rectangle{ .x = 10, .y = 60, .height = 20, .width = 100 }, "Triggers");
        _ = self.ddActive;
    }
};
