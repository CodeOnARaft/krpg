const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Constants = @import("Constants.zig");
const EditorWindow = @import("../editor.zig").EditorWindow;
const ArrayList = std.ArrayList;

pub const Menu = struct {
    menuLocation: raylib.Rectangle = undefined,
    editor: *EditorWindow = undefined,
    icons: ArrayList(MenuIcon) = undefined,

    pub fn init(self: *Menu, currentEditor: *EditorWindow) void {
        self.menuLocation = raylib.Rectangle{ .x = 0, .y = 0, .height = Constants.MenuHeight, .width = 1280 };
        self.editor = currentEditor;

        self.icons = ArrayList(MenuIcon).init(std.heap.page_allocator);

        const openIcon = MenuIcon.new(@intFromEnum(raygui.GuiIconName.icon_folder_file_open), 5, 5);
        const saveIcon = MenuIcon.new(@intFromEnum(raygui.GuiIconName.icon_file_save_classic), 25, 5);
        const handIcon = MenuIcon.new(@intFromEnum(raygui.GuiIconName.icon_cursor_hand), 60, 5);
        const moveIcon = MenuIcon.new(@intFromEnum(raygui.GuiIconName.icon_cursor_move_fill), 80, 5);

        self.icons.append(openIcon) catch unreachable;
        self.icons.append(saveIcon) catch unreachable;
        self.icons.append(handIcon) catch unreachable;
        self.icons.append(moveIcon) catch unreachable;
    }

    pub fn update(self: *Menu) !bool {
        const mouse = raylib.getMousePosition();
        if (!raylib.checkCollisionPointRec(mouse, self.menuLocation) or !raylib.isMouseButtonReleased(.left)) {
            return false;
        }

        var handled = false;

        for (0..self.icons.items.len) |i| {
            if (self.icons.items[i].checkCollision(mouse)) {
                switch (self.icons.items[i].iconId) {
                    @intFromEnum(raygui.GuiIconName.icon_folder_file_open) => {
                        try self.editor.openFile();
                        handled = true;
                        break;
                    },
                    @intFromEnum(raygui.GuiIconName.icon_file_save_classic) => {
                        // TODO Scene Save
                    },
                    @intFromEnum(raygui.GuiIconName.icon_cursor_hand) => {
                        self.selectIcon(self.icons.items[i].iconId);
                        // TODO Set mode
                    },
                    @intFromEnum(raygui.GuiIconName.icon_cursor_move_fill) => {
                        self.selectIcon(self.icons.items[i].iconId);
                        // TODO Set Mode
                    },
                    else => {},
                }
            }
        }

        return handled;
    }

    pub fn selectIcon(self: *Menu, iconId: i32) void {
        for (0..self.icons.items.len) |i| {
            if (self.icons.items[i].iconId == iconId) {
                self.icons.items[i].selected = true;
            } else {
                self.icons.items[i].selected = false;
            }
        }
    }

    pub fn draw(self: *Menu) void {
        const style = raygui.guiGetStyle(raygui.GuiControl.default, raygui.GuiDefaultProperty.background_color);
        const color = raylib.fade(raylib.getColor(@intCast(style)), 1);
        raylib.drawRectangle(@intFromFloat(self.menuLocation.x), @intFromFloat(self.menuLocation.y), @intFromFloat(self.menuLocation.width), Constants.MenuHeight, color);

        for (0..self.icons.items.len) |i| {
            self.icons.items[i].draw();
        }

        raylib.drawText("|", 50, 5, 16, raylib.Color.dark_green);
    }
};

const MenuIcon = struct {
    iconId: i32,
    posX: i32,
    posY: i32,
    size: i32 = 16,
    boundingBox: raylib.Rectangle = undefined,
    selected: bool = false,
    clickEvent: *const fn (*MenuIcon) anyerror!void = undefined,

    pub fn new(iconId: i32, posX: i32, posY: i32) MenuIcon {
        const newIcon = MenuIcon{
            .iconId = iconId,
            .posX = posX,
            .posY = posY,
            .boundingBox = raylib.Rectangle{ .x = @floatFromInt(posX), .y = @floatFromInt(posY), .width = 16, .height = 16 },
        };
        return newIcon;
    }

    pub fn draw(self: *MenuIcon) void {
        var color = raylib.Color.dark_green;
        if (self.selected) {
            color = raylib.Color.red;
        } else if (self.checkCollision(raylib.getMousePosition())) {
            color = raylib.Color.yellow;
        }
        raygui.guiDrawIcon(self.iconId, self.posX, self.posY, 1, color);
    }

    pub fn checkCollision(self: *MenuIcon, mouse: raylib.Vector2) bool {
        return raylib.checkCollisionPointRec(mouse, self.boundingBox);
    }
};
