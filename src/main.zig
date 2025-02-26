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

/// Adds two vectors.
pub fn addVec3(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
}

/// Subtracts b from a.
pub fn subVec3(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
}

/// Scales a vector by a scalar.
pub fn scaleVec3(v: rl.Vector3, s: f32) rl.Vector3 {
    return rl.Vector3{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
}

pub fn triangleCenter(a: rl.Vector3, b: rl.Vector3, c: rl.Vector3) rl.Vector3 {
    // The centroid is the average of the vertices.
    return scaleVec3(addVec3(addVec3(a, b), c), 1.0 / 3.0);
}
pub fn lengthVec3(v: rl.Vector3) f32 {
    return std.math.sqrt(dotVec3(v, v));
}

pub fn dotVec3(a: rl.Vector3, b: rl.Vector3) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

/// Computes the cross product of two vectors.
pub fn cross(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return rl.Vector3{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

pub fn normalizeVec3(v: rl.Vector3) rl.Vector3 {
    return scaleVec3(v, 1.0 / lengthVec3(v));
}

pub fn calculateLightIntensity(
    triangleNormal: rl.Vector3,
    a: rl.Vector3,
    b: rl.Vector3,
    c: rl.Vector3,
    sunPosition: rl.Vector3,
) f32 {
    // Compute the center of the triangle.
    const center = triangleCenter(a, b, c);
    // Compute a normalized light direction from the triangle center to the sun.
    const lightDir = normalizeVec3(subVec3(sunPosition, center));
    std.debug.print("Light direction: {}, {}, {}\n", .{ lightDir.x, lightDir.y, lightDir.z });

    // Compute the diffuse intensity (clamped to zero if the angle is more than 90°).

    var diffuseIntensity = dotVec3(triangleNormal, lightDir);

    if (diffuseIntensity < 0.0) {
        diffuseIntensity = 0.0;
    }

    // if (triangleNormal.z < 0.0 and triangleNormal.x < 0.0) {
    //     diffuseIntensity = -1.0 * (diffuseIntensity * 0.75);
    // } else if (triangleNormal.z > 0.0 and triangleNormal.x > 0.0) {
    //     diffuseIntensity = diffuseIntensity * 1.25;
    // }

    // return diffuseIntensity;

    var ambientIntensity: f32 = 0.18;
    ambientIntensity = ambientIntensity + (1.0 - ambientIntensity) * diffuseIntensity;
    while (ambientIntensity > 1.0) {
        ambientIntensity = ambientIntensity / 10.0;
    }

    return ambientIntensity;
}

fn applyIntensity(base: rl.Color, intensity: f32) rl.Color {
    // Clamp intensity to the range [0.0, 1.0] if needed.
    //const clampedIntensity: f32 = std.math.clamp(intensity, 0.0, 1.0);
    //std.debug.print("Intensity: {}\n", .{clampedIntensity});
    const rf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.r))) * intensity, 0, 255);
    const gf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.g))) * intensity, 0, 255);
    const bf32 = std.math.clamp(@as(f32, @floatFromInt(@as(i32, base.b))) * intensity, 0, 255);

    //std.debug.print("r: {}, g: {}, b: {}\n", .{ base.r, base.g, base.b });
    //std.debug.print("r: {}, g: {}, b: {}\n", .{ rf32, gf32, bf32 });

    // Multiply each color channel (converted to f32) by the intensity.
    // We round the result before casting back to u8.
    const color = rl.Color{
        .r = @as(u8, @intFromFloat(std.math.round(rf32))),
        .g = @as(u8, @intFromFloat(std.math.round(gf32))),
        .b = @as(u8, @intFromFloat(std.math.round(bf32))),
        .a = base.a,
    };

    // std.debug.print("r: {}, g: {}, b: {}\n", .{ color.r, color.g, color.b });
    return color;
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
                        .color = rl.Color.green,
                    };
                } else {
                    lastTriangle = Triangle{
                        .a = lastTriangle.c,
                        .b = lastTriangle.b,
                        .c = rl.Vector3.init(lastTriangle.c.x + groundScale, hf32, (yasF32 * groundScale) + groundScale),
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

            const edge1 = GetEdgeVector(lastTriangle.a, lastTriangle.b);
            const edge2 = GetEdgeVector(lastTriangle.a, lastTriangle.c);
            const normal = CrossProduct(edge1, edge2);
            groundNormals[y * 50 + x] = normal;

            const intensity = calculateLightIntensity(normal, lastTriangle.a, lastTriangle.b, lastTriangle.c, rl.Vector3.init(20.5, 100, 11.5));
            const color = applyIntensity(lastTriangle.color, intensity);

            lastTriangle = Triangle{
                .a = lastTriangle.a,
                .b = lastTriangle.b,
                .c = lastTriangle.c,
                .color = color,
            };

            groundPoints[y * 50 + x] = lastTriangle;
        }
    }
}

fn DrawGround() void {
    for (groundPoints) |triangle| {
        rl.drawTriangle3D(triangle.a, triangle.b, triangle.c, triangle.color);
        // std.debug.print("Triangle: {}, {}, {}\n", .{ triangle.color.r, triangle.color.g, triangle.color.b });
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

fn GenMeshCustom() rl.Mesh {
    const tris = maxXTriangles * maxZTriangles;
    var mesh = rl.Mesh{
        .vertexCount = 3 * tris,
        .triangleCount = tris,
        // @ptrCast -> [*c]f32, @alignCast -> @alignOf(f32)
        .vertices = @ptrCast(@alignCast(rl.memAlloc(tris * 3 * 3 * @sizeOf(f32)))), // 3 vertices, 3 coordinates each (x, y, z)
        // @ptrCast -> [*c]f32, @alignCast -> @alignOf(f32)
        .texcoords = @ptrCast(@alignCast(rl.memAlloc(tris * 3 * 2 * @sizeOf(f32)))), // 3 vertices, 2 coordinates each (x, y)
        .texcoords2 = null,
        // @ptrCast -> [*c]f32, @alignCast -> @alignOf(f32)
        .normals = @ptrCast(@alignCast(rl.memAlloc(tris * 3 * 3 * @sizeOf(f32)))), // 3 vertices, 3 coordinates each (x, y, z)
        .tangents = null,
        .colors = null,
        .indices = null,
        .animVertices = null,
        .animNormals = null,
        .boneIds = null,
        .boneWeights = null,
        .vaoId = 0,
        // UploadMesh() uses RL_CALLOC() macro to allocate MAX_MESH_VERTEX_BUFFERS unsigned ints,
        // and saves the pointer to them in .vboId
        .vboId = null,
        .boneMatrices = null,
        .boneCount = 0,
    };

    for (groundPoints, 0..) |triangle, i| {
        const ii = i * 3;
        // Vertex at (0, 0, 0)
        mesh.vertices[ii] = triangle.a.x;
        mesh.vertices[ii + 1] = triangle.a.y;
        mesh.vertices[ii + 2] = triangle.a.z;
        mesh.normals[ii] = 0;
        mesh.normals[ii + 1] = 1;
        mesh.normals[ii + 2] = 0;
        mesh.texcoords[ii] = 0;
        mesh.texcoords[ii + 1] = 0;

        // Vertex at (1, 0, 2)
        mesh.vertices[ii + 3] = triangle.b.x;
        mesh.vertices[ii + 4] = triangle.b.y;
        mesh.vertices[ii + 5] = triangle.b.z;
        mesh.normals[ii + 3] = 0;
        mesh.normals[ii + 4] = 1;
        mesh.normals[ii + 5] = 0;
        mesh.texcoords[ii + 2] = 0.5;
        mesh.texcoords[ii + 3] = 1.0;

        // Vertex at (2, 0, 0)
        mesh.vertices[ii + 6] = triangle.c.x;
        mesh.vertices[ii + 7] = triangle.c.y;
        mesh.vertices[ii + 8] = triangle.c.z;
        mesh.normals[ii + 6] = 0;
        mesh.normals[ii + 7] = 1;
        mesh.normals[ii + 8] = 0;
        mesh.texcoords[ii + 4] = 1;
        mesh.texcoords[ii + 5] = 0;
    }

    // Upload mesh data from CPU (RAM) to GPU (VRAM) memory
    rl.uploadMesh(&mesh, false);

    return mesh;
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "krpg");
    defer rl.closeWindow(); // Close window and OpenGL context

    // rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
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
    //rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    SetupGround();
    // const mesh = GenMeshCustom();
    // const @_: rl.Model = rl.loadModelFromMesh(mesh) catch |err| {
    //     std.debug.print("Error loading model: {}\n", .{err});
    //     return;
    // };
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

        rl.clearBackground(rl.Color.black);

        {
            camera.begin();
            defer camera.end();

            // Draw ground
            DrawGround();
            //rl.drawModel(model, rl.Vector3.init(0, 0, 0), 1.0, rl.Color.white);
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

        rl.drawFPS(5, 5);
        //----------------------------------------------------------------------------------
    }
}
