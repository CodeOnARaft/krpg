const rl = @import("raylib");
const std = @import("std");
const util = @import("utility");
const map = @import("map");

fn Vector3sAreEqual(a: rl.Vector3, b: rl.Vector3) bool {
    return a.x == b.x and a.y == b.y and a.z == b.z;
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "krpg");
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
        camera.update(.first_person);
        if (!Vector3sAreEqual(camera.position, oldCameraPosition)) {
            map.UpdateCameraPosition(camera);
            oldCameraPosition = camera.position;
        }

        if (rl.isKeyReleased(rl.KeyboardKey.f5)) {
            showDebug = !showDebug;
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.sky_blue);

        {
            camera.begin();
            defer camera.end();

            // Draw ground
            map.DrawGround();
        }

        if (showDebug) {
            rl.drawRectangle(10, 10, 220, 70, rl.Color.sky_blue.fade(0.5));
            rl.drawRectangleLines(10, 10, 220, 70, rl.Color.blue);

            rl.drawFPS(20, 20);
        }
        //----------------------------------------------------------------------------------
    }
}
