const graphics = @import("graphics.zig");
const PixelColor = graphics.PixelColor;
const PixelWriter = graphics.PixelWriter;
const hankaku = compile(@embedFile("hankaku.txt"));
const std = @import("std");

pub fn writeAscii(writer: *const PixelWriter, x: u32, y: u32, c: u8, color: PixelColor) void {
    const font = getFont(c);
    if (font.len == 0) return;

    for (0..16) |dy| {
        for (0..8) |dx| {
            if (((font[dy] << @intCast(dx)) & 0x80) != 0) {
                writer.write(x + @as(u32, @intCast(dx)), y + @as(u32, @intCast(dy)), color);
            }
        }
    }
}

fn getFont(c: u8) []const u8 {
    const index: usize = 16 * @as(usize, c);

    if (index + 16 > hankaku.len) {
        return &.{};
    }

    return hankaku[index..][0..16];
}

fn compile(comptime src: []const u8) [4096]u8 {
    @setEvalBranchQuota(150_000);

    var font_bin: [4096]u8 = undefined;
    var index: usize = 0;

    var lines_iter = std.mem.tokenizeScalar(u8, src, '\n');
    lines: while (lines_iter.next()) |line| {
        if (line.len != 8) continue;

        var byte: u8 = 0;
        for (line) |c| {
            byte <<= 1;

            switch (c) {
                '.' => {},
                '@', '*' => byte |= 1,
                else => continue :lines,
            }
        }

        font_bin[index] = byte;
        index += 1;
    }

    if (index != font_bin.len) {
        @compileError("invalid font file");
    }

    return font_bin;
}
