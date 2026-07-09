const FramebufferConfig = @import("common").FramebufferConfig;

export fn kernelMain(
    framebuffer_config: *const FramebufferConfig,
) callconv(.{ .x86_64_sysv = .{} }) noreturn {
    const pixel_writer: PixelWriter = switch (framebuffer_config.pixel_format) {
        .rgb_resv_8_bit_per_color => PixelWriter{ .rgb_8_bit = .{ .config = framebuffer_config } },
        .bgr_resv_8_bit_per_color => PixelWriter{ .bgr_8_bit = .{ .config = framebuffer_config } },
    };

    for (0..framebuffer_config.horizontal_resolution) |x| {
        for (0..framebuffer_config.vertical_resolution) |y| {
            pixel_writer.write(@intCast(x), @intCast(y), .{ .r = 255, .g = 255, .b = 255 });
        }
    }

    for (0..200) |x| {
        for (0..100) |y| {
            pixel_writer.write(@intCast(x), @intCast(y), .{ .r = 0, .g = 255, .b = 0 });
        }
    }

    writeAscii(&pixel_writer, 50, 50, 'A', .{ .r = 0, .g = 0, .b = 0 });
    writeAscii(&pixel_writer, 58, 50, 'A', .{ .r = 0, .g = 0, .b = 0 });

    while (true) {
        asm volatile ("hlt");
    }
}

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

fn writeAscii(writer: *const PixelWriter, x: u32, y: u32, c: u8, color: PixelColor) void {
    if (c != 'A') return;

    for (0..16) |dy| {
        for (0..8) |dx| {
            if (((font_a[dy] << @intCast(dx)) & 0x80) != 0) {
                writer.write(x + @as(u32, @intCast(dx)), y + @as(u32, @intCast(dy)), color);
            }
        }
    }
}

const PixelColor = struct {
    r: u8,
    g: u8,
    b: u8,
};

const PixelWriter = union(enum) {
    rgb_8_bit: RgbResv8BitPerColorPixelWriter,
    bgr_8_bit: BgrResv8BitPerColorPixelWriter,

    pub fn write(self: PixelWriter, x: u32, y: u32, c: PixelColor) void {
        return switch (self) {
            inline else => |s| s.write(x, y, c),
        };
    }
};

const RgbResv8BitPerColorPixelWriter = struct {
    config: *const FramebufferConfig,

    pub fn write(self: RgbResv8BitPerColorPixelWriter, x: u32, y: u32, c: PixelColor) void {
        var p = pixelAt(self.config, x, y);
        p[0] = c.r;
        p[1] = c.g;
        p[2] = c.b;
    }
};

const BgrResv8BitPerColorPixelWriter = struct {
    config: *const FramebufferConfig,

    pub fn write(self: BgrResv8BitPerColorPixelWriter, x: u32, y: u32, c: PixelColor) void {
        var p = pixelAt(self.config, x, y);
        p[0] = c.b;
        p[1] = c.g;
        p[2] = c.r;
    }
};

pub fn pixelAt(config: *const FramebufferConfig, x: u32, y: u32) []u8 {
    const pixel_position = config.pixels_per_scan_line * y + x;
    return config.frame_buffer[4 * pixel_position ..];
}
