const std = @import("std");

pub fn removeCharConstU8(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    if (text.len == 0) {
        return text;
    }
    const new_text = try std.fmt.allocPrint(allocator, "{s}", .{text[0 .. text.len - 1]});
    allocator.free(text); // Free the old memory
    return new_text;
}

pub fn toSentinelConstU8(allocator: std.mem.Allocator, text: []const u8) anyerror![*:0]const u8 {
    if (text.len == 0) {
        return "";
    }
    var buffer = try allocator.alloc(u8, text.len + 1); // Allocate new memory

    std.mem.copyForwards(u8, buffer[0..text.len], text); // Copy safely
    buffer[text.len] = 0; // Add null terminator
    return @as([*:0]const u8, @ptrCast(buffer.ptr)); // Cast to sentinel pointer
}

pub fn appendCharConstU8(allocator: std.mem.Allocator, text: []const u8, new_char: u8) ![]const u8 {
    std.debug.print("Appending char: {}\n", .{new_char});
    const new_text = try std.fmt.allocPrint(allocator, "{s}{c}", .{ text, new_char });
    allocator.free(text); // Free the old memory
    return new_text;
}

pub fn constU8toU8(inString: []const u8) ![]u8 {
    const outString = try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{inString});
    return outString;
}

pub fn trimSpaceEOL(inString: []const u8) []u8 {
    const d: []u8 = undefined;
    const v = constU8toU8(std.mem.trim(u8, inString, " \n")) catch |err| {
        std.debug.print("Error trimming string: {}\n", .{err});
        return d;
    };

    return v;
}
