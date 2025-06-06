const std = @import("std");
pub const ActiveViewInterface = struct {
    ptr: *anyopaque,
    updateFn: *const fn (ptr: *anyopaque, frame_allocator: std.mem.Allocator) anyerror!void,
    drawFn: *const fn (ptr: *anyopaque, frame_allocator: std.mem.Allocator) anyerror!void,

    pub fn init(ptr: anytype) ActiveViewInterface {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn update(pointer: *anyopaque, frame_allocator: std.mem.Allocator) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.update(self, frame_allocator);
            }

            pub fn draw(pointer: *anyopaque, frame_allocator: std.mem.Allocator) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.draw(self, frame_allocator);
            }
        };

        return .{
            .ptr = ptr,
            .updateFn = gen.update,
            .drawFn = gen.draw,
        };
    }

    pub fn update(self: ActiveViewInterface, frame_allocator: std.mem.Allocator) anyerror!void {
        return self.updateFn(self.ptr, frame_allocator);
    }

    pub fn draw(self: ActiveViewInterface, frame_allocator: std.mem.Allocator) anyerror!void {
        return self.drawFn(self.ptr, frame_allocator);
    }
};
