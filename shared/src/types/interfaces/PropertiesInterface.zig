pub const PropertiesInterface = struct {
    ptr: *anyopaque,
    updatePropertiesFn: *const fn (ptr: *anyopaque) anyerror!void,
    drawPropertiesFn: *const fn (ptr: *anyopaque) anyerror!void,

    pub fn init(ptr: anytype) PropertiesInterface {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn updateProperties(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.updateProperties(self);
            }

            pub fn drawProperties(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.drawProperties(self);
            }
        };

        return .{
            .ptr = ptr,
            .updatePropertiesFn = gen.update,
            .drawPropertiesFn = gen.draw,
        };
    }

    pub fn update(self: PropertiesInterface) anyerror!void {
        return self.updatePropertiesFn(self.ptr);
    }

    pub fn draw(self: PropertiesInterface) anyerror!void {
        return self.drawPropertiesFn(self.ptr);
    }
};
