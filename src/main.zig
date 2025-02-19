// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const std = @import("std");

const MAX_COLUMNS = 200;

const Triangle = struct {
    a: rl.Vector3,
    b: rl.Vector3,
    c: rl.Vector3,
    color: rl.Color,
};

var groundPoints: [25 * 50]Triangle = undefined;
var groundScale: f32 = 5.0;

fn SetupGround() void {
    // Implement the ground drawing logic here
    // Example:
    // rl.drawPlane(rl.Vector3.init(0, 0, 0), rl.Vector2.init(32, 32), rl.Color.light_gray);

    var lastTriangle: Triangle = undefined;
    var tris: i32 = 0;
    for (0..25) |y| {
        for (0..50) |x| {
            const xasF32 = @as(f32, @floatFromInt(x));
            const yasF32 = @as(f32, @floatFromInt(y));

            const r1: u8 = @as(u8, @intCast(rl.getRandomValue(20, 255)));
            const r2: u8 = @as(u8, @intCast(rl.getRandomValue(20, 255)));
            const r3: u8 = @as(u8, @intCast(rl.getRandomValue(20, 255)));

            const rndColor = rl.Color.init(r1, r2, r3, 255);

            if (x == 0) {
                lastTriangle = Triangle{
                    .a = rl.Vector3.init((xasF32 * groundScale), 0.0, (yasF32 * groundScale)),
                    .b = rl.Vector3.init((xasF32 * groundScale), 0.0, (yasF32 * groundScale) + groundScale),
                    .c = rl.Vector3.init((xasF32 * groundScale) + groundScale, 0.0, (yasF32 * groundScale) + groundScale),
                    .color = rndColor,
                };
            } else {
                if (x % 2 == 1) {
                    lastTriangle = Triangle{
                        .a = lastTriangle.a,
                        .b = lastTriangle.c,
                        .c = rl.Vector3.init((xasF32 * groundScale), 0.0, (yasF32 * groundScale) + groundScale),
                        .color = rndColor,
                    };
                } else {
                    lastTriangle = Triangle{
                        .a = lastTriangle.c,
                        .b = lastTriangle.b,
                        .c = rl.Vector3.init((xasF32 * groundScale) + groundScale, 0.0, (yasF32 * groundScale) + groundScale),
                        .color = rndColor,
                    };
                }
            }
            groundPoints[y * 50 + x] = lastTriangle;
            tris += 1;
        }
    }

    std.debug.print("Triangles: {}", .{tris});
}

fn DrawGround() void {
    var tris: i32 = 0;
    for (groundPoints) |triangle| {
        rl.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
        tris += 1;
    }

    //std.debug.print("Triangles: {}", .{tris});
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "krpg");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    // rl.toggleFullscreen();

    var camera = rl.Camera3D{
        .position = rl.Vector3.init(4, 2, 4),
        .target = rl.Vector3.init(0, 1.8, 0),
        .up = rl.Vector3.init(0, 1, 0),
        .fovy = 60,
        .projection = .perspective,
    };

    var heights: [MAX_COLUMNS]f32 = undefined;
    var positions: [MAX_COLUMNS]rl.Vector3 = undefined;
    var colors: [MAX_COLUMNS]rl.Color = undefined;

    for (0..heights.len) |i| {
        heights[i] = @as(f32, @floatFromInt(rl.getRandomValue(1, 12)));
        positions[i] = rl.Vector3.init(
            @as(f32, @floatFromInt(rl.getRandomValue(-50, 50))),
            heights[i] / 2.0,
            @as(f32, @floatFromInt(rl.getRandomValue(-50, 50))),
        );
        colors[i] = rl.Color.init(
            @as(u8, @intCast(rl.getRandomValue(20, 255))),
            @as(u8, @intCast(rl.getRandomValue(10, 55))),
            30,
            255,
        );
    }

    rl.disableCursor(); // Limit cursor to relative movement inside the window
    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    SetupGround();
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        camera.update(.first_person);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        {
            camera.begin();
            defer camera.end();

            // Draw ground
            DrawGround();
            //rl.drawCube(rl.Vector3.init(-16.0, 2.5, 0.0), 1.0, 5.0, 32.0, rl.Color.blue); // Draw a blue wall
            //rl.drawCube(rl.Vector3.init(16.0, 2.5, 0.0), 1.0, 5.0, 32.0, rl.Color.lime); // Draw a green wall
            //rl.drawCube(rl.Vector3.init(0.0, 2.5, 16.0), 32.0, 5.0, 1.0, rl.Color.gold); // Draw a yellow wall

            // Draw some cubes around
            for (heights, 0..) |height, i| {
                rl.drawCube(positions[i], 2.0, height, 2.0, colors[i]);
                rl.drawCubeWires(positions[i], 2.0, height, 2.0, rl.Color.maroon);
            }
        }

        rl.drawRectangle(10, 10, 220, 70, rl.Color.sky_blue.fade(0.5));
        rl.drawRectangleLines(10, 10, 220, 70, rl.Color.blue);

        rl.drawText("First person camera default controls:", 20, 20, 10, rl.Color.black);
        rl.drawText("- Move with keys: W, A, S, D", 40, 40, 10, rl.Color.dark_gray);
        rl.drawText("- Mouse move to look around", 40, 60, 10, rl.Color.dark_gray);
        //----------------------------------------------------------------------------------
    }
}
