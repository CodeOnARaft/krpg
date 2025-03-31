const std = @import("std");
const raylib = @import("raylib");

pub const EditorSelectedInterface = struct {
    ptr: *anyopaque,

    drawPropertiesFn: *const fn (ptr: *anyopaque, position: raylib.Rectangle) anyerror!void,
    drawSelectedFn: *const fn (ptr: *anyopaque) anyerror!void,

    pub fn init(ptr: anytype) EditorSelectedInterface {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn drawProperties(pointer: *anyopaque, position: raylib.Rectangle) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.drawProperties(self, position);
            }

            pub fn drawSelected(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.drawSelected(self);
            }
        };

        return .{
            .ptr = ptr,
            .drawPropertiesFn = gen.drawProperties,
            .drawSelectedFn = gen.drawSelected,
        };
    }

    pub fn drawProperties(self: EditorSelectedInterface, position: raylib.Rectangle) anyerror!void {
        return self.drawPropertiesFn(self.ptr, position);
    }

    pub fn drawSelected(self: EditorSelectedInterface) anyerror!void {
        return self.drawSelectedFn(self.ptr);
    }
};
