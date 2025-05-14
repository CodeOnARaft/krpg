const raylib = @import("raylib");
const std = @import("std");

fn getDaySuffix(day: u8) []const u8 {
    if (day == 11 or day == 12 or day == 13) return "th";
    switch (day % 10) {
        1 => return "st",
        2 => return "nd",
        3 => return "rd",
        else => return "th",
    }
}

fn getMonthName(month: u8) []const u8 {
    const months = [_][]const u8{
        "January", "February", "March",     "April",   "May",      "June",
        "July",    "August",   "September", "October", "November", "December",
    };
    return months[month - 1];
}

fn getDayOfWeek(year: u32, month: u8, day: u8) []const u8 {
    const days = [_][]const u8{
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
    };

    const y = if (month < 3) year - 1 else year;
    const m = if (month < 3) month + 12 else month;
    const k = y % 100;
    const j = y / 100;

    const dayIndex: u8 = @intCast((day + (13 * (m + 1)) / 5 + k + (k / 4) + (j / 4) - (2 * j)) % 7);
    return days[dayIndex];
}

pub const GameTimeManager = struct {
    year: u32,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    timePassed: f32,

    pub fn init() GameTimeManager {
        return GameTimeManager{
            .year = 1000,
            .month = 1,
            .day = 1,
            .hour = 0,
            .minute = 0,
            .timePassed = 0.0,
        };
    }

    pub fn update(self: *GameTimeManager) !void {
        self.timePassed += raylib.getFrameTime();

        if (self.timePassed >= 3.0) { // 20 game minutes per real life minute
            self.minute += 1;
            if (self.minute >= 60) {
                self.minute -= 60;
                self.hour += 1;
                if (self.hour >= 24) {
                    self.hour -= 24;
                    self.day += 1;
                    if (self.day > 30) {
                        self.day -= 30;
                        self.month += 1;
                        if (self.month > 12) {
                            self.month -= 12;
                            self.year += 1;
                        }
                    }
                }
            }

            self.timePassed = 0.0;
        }
    }

    pub fn setTime(self: *GameTimeManager, year: u32, month: u8, day: u8, hour: u8, minute: u8) void {
        self.year = year;
        self.month = month;
        self.day = day;
        self.hour = hour;
        self.minute = minute;
        self.timePassed = 0.0;
    }

    pub fn getCurrentTimeString(self: *GameTimeManager) ![]u8 {
        //const dayOfWeek = getDayOfWeek(self.year, self.month, self.day);
        const monthName = getMonthName(self.month);
        const daySuffix = getDaySuffix(self.day);
        const day = @as(i32, self.day);

        // const year: i32 = @truncate(@as(i64, self.year));

        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "{d:02}:{d:02} on {d}{s} of {s} {d}",
            .{ self.hour, self.minute, day, daySuffix, monthName, self.year },
        );
    }
};
