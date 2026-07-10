const FramebufferConfig = @import("common").FramebufferConfig;

pub const PixelColor = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub const PixelWriter = union(enum) {
    rgb_8_bit: RgbResv8BitPerColorPixelWriter,
    bgr_8_bit: BgrResv8BitPerColorPixelWriter,

    pub fn write(self: PixelWriter, x: u32, y: u32, c: PixelColor) void {
        return switch (self) {
            inline else => |s| s.write(x, y, c),
        };
    }
};

pub const RgbResv8BitPerColorPixelWriter = struct {
    config: *const FramebufferConfig,

    pub fn write(self: RgbResv8BitPerColorPixelWriter, x: u32, y: u32, c: PixelColor) void {
        var p = pixelAt(self.config, x, y);
        p[0] = c.r;
        p[1] = c.g;
        p[2] = c.b;
    }
};

pub const BgrResv8BitPerColorPixelWriter = struct {
    config: *const FramebufferConfig,

    pub fn write(self: BgrResv8BitPerColorPixelWriter, x: u32, y: u32, c: PixelColor) void {
        var p = pixelAt(self.config, x, y);
        p[0] = c.b;
        p[1] = c.g;
        p[2] = c.r;
    }
};

fn pixelAt(config: *const FramebufferConfig, x: u32, y: u32) []u8 {
    const pixel_position = config.pixels_per_scan_line * y + x;
    return config.frame_buffer[4 * pixel_position ..];
}
