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

const maxZTriangles = 25;
const maxXTriangles = 50;
var groundPoints: [maxXTriangles * maxZTriangles]Triangle = undefined;
var groundNormals: [maxXTriangles * maxZTriangles]rl.Vector3 = undefined;

var groundScale: f32 = 10.0;
var maxTileX: f32 = 50;
var maxTileY: f32 = 25;

fn GetEdgeVector(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3.init(b.x - a.x, b.y - a.y, b.z - a.z);
}

fn CrossProduct(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3.init(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
    );
}

fn FindYFromNormal(normal: rl.Vector3, point: rl.Vector3, x: f32, z: f32) f32 {
    const top = normal.x * (x - point.x) + normal.z * (z - point.z);
    const bottom = normal.y;
    return point.y - (top / bottom);
}

fn SetupGround() void {
    // Implement the ground drawing logic here
    // Example:
    // rl.drawPlane(rl.Vector3.init(0, 0, 0), rl.Vector2.init(32, 32), rl.Color.light_gray);

    var lastTriangle: Triangle = undefined;
    for (0..25) |y| {
        for (0..50) |x| {
            //const xasF32 = @as(f32, @floatFromInt(x));
            const yasF32 = @as(f32, @floatFromInt(y));

            const r1: u8 = @as(u8, @intCast(rl.getRandomValue(20, 255)));
            const r2: u8 = @as(u8, @intCast(rl.getRandomValue(20, 255)));
            const r3: u8 = @as(u8, @intCast(rl.getRandomValue(20, 255)));

            const rndColor = rl.Color.init(r1, r2, r3, 255);
            // random value between 0 and 2
            const h = rl.getRandomValue(0, 40);
            // h as f32
            const hf32 = @as(f32, @floatFromInt(h)) / 10.0;
            var oldhf32 = hf32;
            if (x == 0) {
                if (y != 0) {
                    oldhf32 = groundPoints[(y - 1) * 50].b.y;
                }
                lastTriangle = Triangle{
                    .a = rl.Vector3.init(0, oldhf32, (yasF32 * groundScale)),
                    .b = rl.Vector3.init(0, hf32, (yasF32 * groundScale) + groundScale),
                    .c = rl.Vector3.init(groundScale, hf32, (yasF32 * groundScale) + groundScale),
                    .color = rndColor,
                };
            } else {
                if (x % 2 == 1) {
                    if (y != 0) {
                        oldhf32 = groundPoints[(y - 1) * 50 + x].b.y;
                    }
                    lastTriangle = Triangle{
                        .a = lastTriangle.a,
                        .b = lastTriangle.c,
                        .c = rl.Vector3.init(lastTriangle.c.x, oldhf32, (yasF32 * groundScale)),
                        .color = rndColor,
                    };
                } else {
                    lastTriangle = Triangle{
                        .a = lastTriangle.c,
                        .b = lastTriangle.b,
                        .c = rl.Vector3.init(lastTriangle.c.x + groundScale, hf32, (yasF32 * groundScale) + groundScale),
                        .color = rndColor,
                    };
                }
            }
            groundPoints[y * 50 + x] = lastTriangle;
            if (maxTileX < lastTriangle.c.x) {
                maxTileX = lastTriangle.c.x;
            }
            if (maxTileY < lastTriangle.c.z) {
                maxTileY = (lastTriangle.c.z);
            }

            const edge1 = GetEdgeVector(lastTriangle.a, lastTriangle.b);
            const edge2 = GetEdgeVector(lastTriangle.a, lastTriangle.c);
            const normal = CrossProduct(edge1, edge2);
            groundNormals[y * 50 + x] = normal;
        }
    }
}

fn DrawGround() void {
    var tris: i32 = 0;
    for (groundPoints) |triangle| {
        rl.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
        tris += 1;
    }

    //std.debug.print("Triangles: {}", .{tris});
}

fn TestIfPointInTriangle2D(pp: rl.Vector3, aa: rl.Vector3, bb: rl.Vector3, cc: rl.Vector3) bool {
    const p = rl.Vector2.init(pp.x, pp.z);
    const a = rl.Vector2.init(aa.x, aa.z);
    const b = rl.Vector2.init(bb.x, bb.z);
    const c = rl.Vector2.init(cc.x, cc.z);

    const s = a.y * c.x - a.x * c.y + (c.y - a.y) * p.x + (a.x - c.x) * p.y;
    const t = a.x * b.y - a.y * b.x + (a.y - b.y) * p.x + (b.x - a.x) * p.y;

    if ((s < 0) != (t < 0)) {
        return false;
    }

    const A = -b.y * c.x + a.y * (c.x - b.x) + a.x * (b.y - c.y) + b.x * c.y;

    if (A < 0) {
        return (s <= 0 and (s + t >= A));
    } else {
        return (s >= 0 and (s + t <= A));
    }
}

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

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    // rl.toggleFullscreen();

    var camera = rl.Camera3D{
        .position = rl.Vector3.init(4, 2, 4),
        .target = rl.Vector3.init(0, 2, 0),
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
    var oldCameraPosition = camera.position;
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        camera.update(.first_person);
        if (!Vector3sAreEqual(camera.position, oldCameraPosition)) {
            const pos = camera.position;
            //std.debug.print("Camera position: {}\n", .{camera.position});
            for (groundPoints, 0..) |triangle, i| {
                if (pos.z >= triangle.a.z and (pos.z <= triangle.c.z or pos.z < triangle.b.z)) {
                    if (TestIfPointInTriangle2D(pos, triangle.a, triangle.b, triangle.c)) {
                        const y = FindYFromNormal(groundNormals[i], triangle.a, pos.x, pos.z) + 2;
                        camera.target.y = camera.target.y + (y - camera.position.y);
                        camera.position.y = y;
                        break;
                    }
                }
            }
            oldCameraPosition = camera.position;
        }
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
            // for (heights, 0..) |height, i| {
            //     rl.drawCube(positions[i], 2.0, height, 2.0, colors[i]);
            //     rl.drawCubeWires(positions[i], 2.0, height, 2.0, rl.Color.maroon);
            // }
        }

        rl.drawRectangle(10, 10, 220, 70, rl.Color.sky_blue.fade(0.5));
        rl.drawRectangleLines(10, 10, 220, 70, rl.Color.blue);

        rl.drawText("First person camera default controls:", 20, 20, 10, rl.Color.black);
        rl.drawText("- Move with keys: W, A, S, D", 40, 40, 10, rl.Color.dark_gray);
        rl.drawText("- Mouse move to look around", 40, 60, 10, rl.Color.dark_gray);
        //----------------------------------------------------------------------------------
    }
}
