const std = @import("std");
pub const TriggerInterface = struct {
    ptr: *anyopaque,
    updateTriggerFn: *const fn (ptr: *anyopaque, frame_allocator: std.mem.Allocator) anyerror!void,
    drawTriggerFn: *const fn (ptr: *anyopaque, frame_allocator: std.mem.Allocator) anyerror!void,

    pub fn init(ptr: anytype) TriggerInterface {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn updateTrigger(pointer: *anyopaque, frame_allocator: std.mem.Allocator) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.updateTrigger(self, frame_allocator);
            }

            pub fn drawTrigger(pointer: *anyopaque, frame_allocator: std.mem.Allocator) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.drawTrigger(self, frame_allocator);
            }
        };

        return .{
            .ptr = ptr,
            .updateTriggerFn = gen.updateTrigger,
            .drawTriggerFn = gen.drawTrigger,
        };
    }

    pub fn updateTrigger(self: TriggerInterface, frame_allocator: std.mem.Allocator) anyerror!void {
        return self.updateTriggerFn(self.ptr, frame_allocator);
    }

    pub fn drawTrigger(self: TriggerInterface, frame_allocator: std.mem.Allocator) anyerror!void {
        return self.drawTriggerFn(self.ptr, frame_allocator);
    }
};
