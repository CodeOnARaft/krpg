const rl = @import("raylib");
const std = @import("std");
const util = @import("utility");
const map = @import("map");
const settings = @import("settings");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    rl.initWindow(settings.screenWidth, settings.screenHeight, "krpg");
    defer rl.closeWindow(); // Close window and OpenGL context
    // rl.toggleFullscreen();

    var camera: *rl.Camera3D = &util.camera;

    rl.disableCursor();
    map.SetupGround();
    map.UpdateCameraPosition(camera);

    var oldCameraPosition = camera.position;
    var showDebug = false;
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (!settings.gameSettings.paused) {
            camera.update(.first_person);

            if (!util.Vector3sAreEqual(camera.position, oldCameraPosition)) {
                map.UpdateCameraPosition(camera);
                oldCameraPosition = camera.position;
            }
        }

        if (rl.isKeyReleased(rl.KeyboardKey.f5)) {
            showDebug = !showDebug;
        }

        settings.gameSettings.update();
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        {
            camera.begin();
            defer camera.end();

            // Draw ground
            //map.DrawGround();
        }
        settings.drawConsole();
        if (showDebug) {
            rl.drawRectangle(10, 10, 220, 70, rl.Color.sky_blue.fade(0.5));
            rl.drawRectangleLines(10, 10, 220, 70, rl.Color.blue);

            // rl.drawText("First person camera default controls:", 20, 20, 10, rl.Color.black);
            // rl.drawText("- Move with keys: W, A, S, D", 40, 40, 10, rl.Color.dark_gray);
            // rl.drawText("- Mouse move to look around", 40, 60, 10, rl.Color.dark_gray);

            rl.drawFPS(5, 5);
        }
        //----------------------------------------------------------------------------------
    }
}
