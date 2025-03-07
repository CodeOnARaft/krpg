// namespace types
pub usingnamespace @import("CharValue.zig");
pub usingnamespace @import("Triangle.zig");
pub usingnamespace @import("GroundSector.zig");
pub usingnamespace @import("Scene.zig");
pub usingnamespace @import("Console.zig");
pub usingnamespace @import("Cube.zig");
pub usingnamespace @import("Trigger.zig");

// namespace types.GameObjects
const GameObjectsImport = @import("GameObjects/_types_gameobjects.zig");
pub const GameObjects = GameObjectsImport;

// namespace types.Constants
const ConstantsImport = @import("Constants/_types_constants.zig");
pub const Constants = ConstantsImport;
