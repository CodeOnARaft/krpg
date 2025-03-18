const std = @import("std");
const raylib = @import("raylib");

pub const Object = struct {
    name: []const u8 = undefined,
    model: raylib.Model = undefined,
};

// self.model = try raylib.loadModel("resources/barrel.glb"); // Load model
// const texture = try raylib.loadTexture("resources/T_Barrel_BaseColor.png"); // Load model texture
// self.model.materials[0].maps[0].texture = texture; // Set map diffuse texture
