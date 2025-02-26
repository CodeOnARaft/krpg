const rl = @import("raylib");
const std = @import("std");
const v3 = @import("vector3_functions.zig");
const cf = @import("camera_functions.zig");

const Triangle = struct {
    a: rl.Vector3,
    b: rl.Vector3,
    c: rl.Vector3,
    center: rl.Vector3,
    color: rl.Color,
};

const maxZTriangles = 25;
const maxXTriangles = 50;
var groundPoints: [maxXTriangles * maxZTriangles]Triangle = undefined;
var groundNormals: [maxXTriangles * maxZTriangles]rl.Vector3 = undefined;

var groundScale: f32 = 10.0;
var maxTileX: f32 = 50;
var maxTileY: f32 = 25;

fn SetupGround() void {
    // Implement the ground drawing logic here
    // Example:
    // rl.drawPlane(rl.Vector3.init(0, 0, 0), rl.Vector2.init(32, 32), rl.Color.light_gray);

    var lastTriangle: Triangle = undefined;
    for (0..25) |y| {
        for (0..50) |x| {
            //const xasF32 = @as(f32, @floatFromInt(x));
            const yasF32 = @as(f32, @floatFromInt(y));

            // random value between 0 and 2
            const h = rl.getRandomValue(0, 35);
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
                    .center = rl.Vector3.zero(),
                    .color = rl.Color.green,
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
                        .center = rl.Vector3.zero(),
                        .color = rl.Color.green,
                    };
                } else {
                    lastTriangle = Triangle{
                        .a = lastTriangle.c,
                        .b = lastTriangle.b,
                        .c = rl.Vector3.init(lastTriangle.c.x + groundScale, hf32, (yasF32 * groundScale) + groundScale),
                        .center = rl.Vector3.zero(),
                        .color = rl.Color.green,
                    };
                }
            }

            if (maxTileX < lastTriangle.c.x) {
                maxTileX = lastTriangle.c.x;
            }
            if (maxTileY < lastTriangle.c.z) {
                maxTileY = (lastTriangle.c.z);
            }

            const edge1 = v3.GetEdgeVector(lastTriangle.a, lastTriangle.b);
            const edge2 = v3.GetEdgeVector(lastTriangle.a, lastTriangle.c);
            const normal = v3.CrossProduct(edge1, edge2);
            groundNormals[y * 50 + x] = normal;

            const intensity = v3.calculateLightIntensity(normal, lastTriangle.a, lastTriangle.b, lastTriangle.c, rl.Vector3.init(20.5, 100, 11.5));
            const color = v3.applyIntensity(lastTriangle.color, intensity);

            lastTriangle = Triangle{
                .a = lastTriangle.a,
                .b = lastTriangle.b,
                .c = lastTriangle.c,
                .center = v3.triangleCenter(lastTriangle.a, lastTriangle.b, lastTriangle.c),
                .color = color,
            };

            groundPoints[y * 50 + x] = lastTriangle;
        }
    }
}

fn DrawGround() void {
    const forward = v3.scaleVec3(v3.normalizeVec3(v3.subVec3(cf.camera.position, cf.camera.target)), -1.0);
    const left = cf.rotateXZLeft(forward);
    const right = cf.rotateXZRight(forward);

    // print camera target, left and right

    var count: i32 = 0;
    const pos = v3.subVec3(cf.camera.position, cf.camera.target);
    for (groundPoints) |triangle| {
        if (v3.TriangleIsVisible(triangle.center, pos, left, right)) {
            rl.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
            count = count + 1;
        }

        //rl.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
    }
    std.debug.print("Triangles drawn: {}\n", .{count});
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

    var camera: *rl.Camera3D = &cf.camera;

    rl.disableCursor();
    SetupGround();
    UpdateCameraPosition(camera);

    var oldCameraPosition = camera.position;
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        camera.update(.first_person);
        if (!Vector3sAreEqual(camera.position, oldCameraPosition)) {
            UpdateCameraPosition(camera);
            oldCameraPosition = camera.position;
        }
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
            DrawGround();
        }

        rl.drawRectangle(10, 10, 220, 70, rl.Color.sky_blue.fade(0.5));
        rl.drawRectangleLines(10, 10, 220, 70, rl.Color.blue);

        rl.drawText("First person camera default controls:", 20, 20, 10, rl.Color.black);
        rl.drawText("- Move with keys: W, A, S, D", 40, 40, 10, rl.Color.dark_gray);
        rl.drawText("- Mouse move to look around", 40, 60, 10, rl.Color.dark_gray);

        rl.drawFPS(5, 5);
        //----------------------------------------------------------------------------------
    }
}

fn UpdateCameraPosition(camera: *rl.Camera3D) void {
    const pos = camera.position;
    //std.debug.print("Camera position: {}\n", .{camera.position});
    for (groundPoints, 0..) |triangle, i| {
        if (pos.z >= triangle.a.z and (pos.z <= triangle.c.z or pos.z < triangle.b.z)) {
            if (v3.TestIfPointInTriangle2D(pos, triangle.a, triangle.b, triangle.c)) {
                const y = v3.FindYFromNormal(groundNormals[i], triangle.a, pos.x, pos.z) + 2;
                camera.target.y = camera.target.y + (y - camera.position.y);
                camera.position.y = y;
                break;
            }
        }
    }
}
