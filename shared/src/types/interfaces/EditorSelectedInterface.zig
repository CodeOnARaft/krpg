pub const EditorSelectedInterface = struct {
    ptr: *anyopaque,

    drawPropertiesFn: *const fn (ptr: *anyopaque) anyerror!void,

    pub fn init(ptr: anytype) EditorSelectedInterface {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn drawProperties(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.drawProperties(self);
            }
        };

        return .{
            .ptr = ptr,
            .drawPropertiesFn = gen.drawProperties,
        };
    }

    pub fn drawProperties(self: EditorSelectedInterface) anyerror!void {
        return self.drawPropertiesFn(self.ptr);
    }
};
