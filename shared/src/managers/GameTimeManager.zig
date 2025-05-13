const raylib = @import("raylib");

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

    pub fn update(self: *GameTimeManager) void {
        self.timePassed += raylib.GetFrameTime();

        if (self.timePassed >= 3.0) { // 20 game minutes per real life minute
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
};
