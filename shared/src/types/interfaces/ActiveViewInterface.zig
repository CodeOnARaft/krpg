pub const ActiveViewInterface = struct {
    ptr: *anyopaque,
    updateFn: *const fn (ptr: *anyopaque) anyerror!void,
    drawFn: *const fn (ptr: *anyopaque) anyerror!void,

    pub fn init(ptr: anytype) ActiveViewInterface {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn update(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.update(self);
            }

            pub fn draw(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.draw(self);
            }
        };

        return .{
            .ptr = ptr,
            .updateFn = gen.update,
            .drawFn = gen.draw,
        };
    }

    pub fn update(self: ActiveViewInterface) anyerror!void {
        return self.updateFn(self.ptr);
    }

    pub fn draw(self: ActiveViewInterface) anyerror!void {
        return self.drawFn(self.ptr);
    }
};
