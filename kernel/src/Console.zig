const Console = @This();
const graphics = @import("graphics.zig");
const PixelWriter = graphics.PixelWriter;
const PixelColor = graphics.PixelColor;
const font = @import("font.zig");
const writeAscii = font.writeAscii;
const writeString = font.writeString;
const std = @import("std");
const rows = 25;
const columns = 80;

writer: *const PixelWriter,
fg_color: PixelColor,
bg_color: PixelColor,
buffer: [rows][columns:0]u8 = .{.{0} ** columns} ** rows,
cursor_row: u8 = 0,
cursor_column: u8 = 0,

pub fn init(writer: *const PixelWriter, fg_color: PixelColor, bg_color: PixelColor) Console {
    return .{
        .writer = writer,
        .fg_color = fg_color,
        .bg_color = bg_color,
    };
}

pub fn putString(self: *Console, string: []const u8) void {
    for (string) |s| {
        if (s == '\n') {
            self.newline();
        } else if (self.cursor_column < columns) {
            writeAscii(self.writer, 8 * self.cursor_column, 16 * self.cursor_row, s, self.fg_color);
            self.buffer[self.cursor_row][self.cursor_column] = s;
            self.cursor_column += 1;
        }
    }
}

fn newline(self: *Console) void {
    self.cursor_column = 0;

    if (self.cursor_row < rows - 1) {
        self.cursor_row += 1;
    } else {
        for (0..(16 * rows)) |_y| {
            const y: u32 = @intCast(_y);

            for (0..(8 * columns)) |_x| {
                const x: u32 = @intCast(_x);
                self.writer.write(x, y, self.bg_color);
            }
        }

        for (0..(rows - 1)) |row| {
            @memcpy(self.buffer[row][0..], self.buffer[row + 1][0..]);
            writeString(self.writer, 0, 16 * @as(u32, @intCast(row)), self.buffer[row][0..], self.fg_color);
        }

        @memset(self.buffer[rows - 1][0..], 0);
    }
}
