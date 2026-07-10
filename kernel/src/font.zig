const graphics = @import("graphics.zig");
const PixelColor = graphics.PixelColor;
const PixelWriter = graphics.PixelWriter;

const font_a: [16]u8 = .{
    0b00000000, //
    0b00011000, //    **
    0b00011000, //    **
    0b00011000, //    **
    0b00011000, //    **
    0b00100100, //   *  *
    0b00100100, //   *  *
    0b00100100, //   *  *
    0b00100100, //   *  *
    0b01111110, //  ******
    0b01000010, //  *    *
    0b01000010, //  *    *
    0b01000010, //  *    *
    0b11100111, // ***  ***
    0b00000000, //
    0b00000000, //
};

pub fn writeAscii(writer: *const PixelWriter, x: u32, y: u32, c: u8, color: PixelColor) void {
    if (c != 'A') return;

    for (0..16) |dy| {
        for (0..8) |dx| {
            if (((font_a[dy] << @intCast(dx)) & 0x80) != 0) {
                writer.write(x + @as(u32, @intCast(dx)), y + @as(u32, @intCast(dy)), color);
            }
        }
    }
}
