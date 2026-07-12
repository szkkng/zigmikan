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

pub fn Vector2D(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

pub fn fillRectangle(writer: *const PixelWriter, pos: Vector2D(u32), size: Vector2D(u32), c: PixelColor) void {
    for (0..size.y) |y| {
        const dy: u32 = @intCast(y);
        for (0..size.x) |x| {
            const dx: u32 = @intCast(x);
            writer.write(pos.x + dx, pos.y + dy, c);
        }
    }
}

pub fn drawRectangle(writer: *const PixelWriter, pos: Vector2D(u32), size: Vector2D(u32), c: PixelColor) void {
    for (0..size.x) |x| {
        const dx: u32 = @intCast(x);
        writer.write(pos.x + dx, pos.y, c);
        writer.write(pos.x + dx, pos.y + size.y - 1, c);
    }
    for (1..size.y - 1) |y| {
        const dy: u32 = @intCast(y);
        writer.write(pos.x, pos.y + dy, c);
        writer.write(pos.x + size.x - 1, pos.y + dy, c);
    }
}

fn pixelAt(config: *const FramebufferConfig, x: u32, y: u32) []u8 {
    const pixel_position = config.pixels_per_scan_line * y + x;
    return config.frame_buffer[4 * pixel_position ..];
}
