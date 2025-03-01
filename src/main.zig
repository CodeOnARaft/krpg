const rl = @import("raylib");
const std = @import("std");
const util = @import("utility");
const map = @import("map");
const settings = @import("settings");

var mary: NPC = NPC{
    .name = "Mary",
    .position = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    rl.initWindow(settings.screenWidth, settings.screenHeight, "krpg");
    defer rl.closeWindow(); // Close window and OpenGL context
    rl.toggleFullscreen();

    var camera: *rl.Camera3D = &util.camera;

    rl.disableCursor();
    map.SetupGround();
    map.UpdateCameraPosition(camera);

    var oldCameraPosition = camera.position;
    var showDebug = false;

    mary.texture = try rl.loadTexture("npc.png");
    //const marytextureheight: f32 = @floatFromInt(mary.texture.height);
    const maryY = map.GetYValueBasedOnLocation(10, 10);
    std.debug.print("Mary Y: {}\n", .{maryY});
    mary.position = rl.Vector3{ .x = 10, .y = maryY, .z = 10.0 };
    var npcs = [1]NPC{mary};

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (!settings.gameSettings.paused) {
            camera.update(.first_person);
            camera.up = rl.Vector3.init(0, 1, 0);

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
            map.DrawGround();
            for (npcs) |npc| {
                if (npc.active) {
                    rl.drawBillboard(camera.*, npc.texture, npc.position, 4.0, rl.Color.white);
                }
            }
        }
        const npc_speed = 3.0 * rl.getFrameTime();
        mary.position = rl.Vector3{
            .x = mary.position.x + npc_speed,
            .y = map.GetYValueBasedOnLocation(mary.position.x + npc_speed, mary.position.z),
            .z = mary.position.z,
        };
        npcs = [1]NPC{mary};

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

const NPC = struct {
    name: []const u8,
    position: rl.Vector3,
    texture: rl.Texture2D = undefined,
    active: bool = true,
};
