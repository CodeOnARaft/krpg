// namespace types
pub usingnamespace @import("GroundSector.zig");
pub usingnamespace @import("Scene.zig");
pub usingnamespace @import("Console.zig");
pub usingnamespace @import("enums.zig");

// namespace types.GameObjects
const GameObjectsImport = @import("GameObjects/_types_gameobjects.zig");
pub const GameObjects = GameObjectsImport;

// namespace types.Constants
const ConstantsImport = @import("Constants/_types_constants.zig");
pub const Constants = ConstantsImport;

// namespace types.Basic
const BasicImport = @import("Basic/_types_basic.zig");
pub const Basic = BasicImport;

// namespace types.ui
const uiImport = @import("ui/_types_ui.zig");
pub const ui = uiImport;

// namespace types.interfaces
const interfacesImport = @import("interfaces/_types_interfaces.zig");
pub const interfaces = interfacesImport;
