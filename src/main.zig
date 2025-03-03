const raylib = @import("raylib");
const std = @import("std");
const util = @import("utility");
const map = @import("map");
const settings = @import("settings");
const types = @import("types");

var mary: types.NPC = types.NPC{
    .name = "Mary",
    .position = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    raylib.initWindow(settings.screenWidth, settings.screenHeight, "krpg");
    defer raylib.closeWindow(); // Close window and OpenGL context
    //raylib.toggleFullscreen();

    var camera: *raylib.Camera3D = &util.camera;

    raylib.disableCursor();
    map.SetupGround();
    map.UpdateCameraPosition(camera);

    var oldCameraPosition = camera.position;
    var showDebug = false;

    mary.texture = try raylib.loadTexture("resources/npc.png");
    //const marytextureheight: f32 = @floatFromInt(mary.texture.height);
    const maryY = map.GetYValueBasedOnLocation(10, 10);
    mary.position = raylib.Vector3{ .x = 10, .y = maryY, .z = 10.0 };
    const npcs = [1]types.NPC{mary};

    while (!raylib.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (!settings.gameSettings.paused) {
            camera.update(.first_person);
            camera.up = raylib.Vector3.init(0, 1, 0);

            if (!util.Vector3sAreEqual(camera.position, oldCameraPosition)) {
                map.UpdateCameraPosition(camera);
                oldCameraPosition = camera.position;
            }
        }

        if (raylib.isKeyReleased(raylib.KeyboardKey.f5)) {
            showDebug = !showDebug;
        }

        settings.gameSettings.update();
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        raylib.beginDrawing();
        defer raylib.endDrawing();

        raylib.clearBackground(raylib.Color.black);

        {
            camera.begin();
            defer camera.end();

            // Draw ground
            map.DrawGround();
            for (npcs) |npc| {
                if (npc.active) {
                    raylib.drawBillboard(camera.*, npc.texture, npc.position, 1.5, raylib.Color.white);
                }
            }
        }
        // const npc_speed = 3.0 * raylib.getFrameTime();
        // mary.position = raylib.Vector3{
        //     .x = mary.position.x + npc_speed,
        //     .y = map.GetYValueBasedOnLocation(mary.position.x + npc_speed, mary.position.z),
        //     .z = mary.position.z,
        // };
        // npcs = [1]NPC{mary};

        settings.drawConsole();
        if (showDebug) {
            raylib.drawRectangle(10, 10, 220, 70, raylib.Color.sky_blue.fade(0.5));
            raylib.drawRectangleLines(10, 10, 220, 70, raylib.Color.blue);

            // raylib.drawText("First person camera default controls:", 20, 20, 10, raylib.Color.black);
            // raylib.drawText("- Move with keys: W, A, S, D", 40, 40, 10, raylib.Color.dark_gray);
            // raylib.drawText("- Mouse move to look around", 40, 60, 10, raylib.Color.dark_gray);

            raylib.drawFPS(5, 5);
        }
        //----------------------------------------------------------------------------------
    }
}
