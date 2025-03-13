const raylib = @import("raylib");
const raygui = @import("raygui");

pub const Menu = struct {
    menuLocation: raylib.Rectangle = undefined,

    pub fn init(self: *Menu) void {
        self.menuLocation = raylib.Rectangle{ .x = 0, .y = 0, .height = 25, .width = 1280 };
    }

    pub fn update(self: *Menu) bool {
        const mouse = raylib.getMousePosition();

        return raylib.checkCollisionPointRec(mouse, self.menuLocation);
    }

    pub fn draw(self: *Menu) void {
        const style = raygui.guiGetStyle(raygui.GuiControl.default, raygui.GuiDefaultProperty.background_color);
        const color = raylib.fade(raylib.getColor(@intCast(style)), 1);
        raylib.drawRectangle(@intFromFloat(self.menuLocation.x), @intFromFloat(self.menuLocation.y), @intFromFloat(self.menuLocation.width), @intFromFloat(self.menuLocation.height), color);

        const openIcon = @intFromEnum(raygui.GuiIconName.icon_file_open);
        raygui.guiDrawIcon(openIcon, 5, 5, 1, raylib.Color.gray);
    }
};
