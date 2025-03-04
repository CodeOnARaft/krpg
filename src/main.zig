const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const map = @import("map");
const settings = @import("settings");
const types = @import("types");
const managers = @import("managers");

var mary: types.NPC = types.NPC{
    .name = "Mary",
    .position = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
};

pub fn main() anyerror!void {
    raylib.initWindow(settings.screenWidth, settings.screenHeight, "krpg");
    defer raylib.closeWindow(); // Close window and OpenGL context

    raylib.disableCursor();
    var gameManager = managers.GameManager{};
    gameManager.initialize();

    mary.texture = try raylib.loadTexture("resources/npc.png");
    //const marytextureheight: f32 = @floatFromInt(mary.texture.height);
    const maryY = map.GetYValueBasedOnLocation(10, 10);
    mary.position = raylib.Vector3{ .x = 10, .y = maryY, .z = 10.0 };
    const npcs = [1]types.NPC{mary};

    while (!raylib.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------

        gameManager.update();

        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        {
            gameManager.draw();
            for (npcs) |npc| {
                if (npc.active) {
                    raylib.drawBillboard(gameManager.camera.*, npc.texture, npc.position, 1.5, raylib.Color.white);
                }
            }
        }

        gameManager.drawUI();

        //----------------------------------------------------------------------------------
    }
}
