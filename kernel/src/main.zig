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

    while (true) {
        asm volatile ("hlt");
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
