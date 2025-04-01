const raylib = @import("raylib");
const std = @import("std");
const shared = @import("shared");
const types = shared.types;

pub fn add(vector1: *raylib.Vector2, vector2: *raylib.Vector2) raylib.Vector2 {
    return raylib.Vector2{ .x = vector1.x + vector2.x, .y = vector1.y + vector2.y };
}

pub fn subtract(vector1: *raylib.Vector2, vector2: *raylib.Vector2) raylib.Vector2 {
    return raylib.Vector2{ .x = vector1.x - vector2.x, .y = vector1.y - vector2.y };
}

pub fn multiply(vector1: *raylib.Vector2, vector2: *raylib.Vector2) raylib.Vector2 {
    return raylib.Vector2{ .x = vector1.x * vector2.x, .y = vector1.y * vector2.y };
}

pub fn divide(vector1: *raylib.Vector2, vector2: *raylib.Vector2) raylib.Vector2 {
    return raylib.Vector2{ .x = vector1.x / vector2.x, .y = vector1.y / vector2.y };
}
