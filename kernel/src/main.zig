const FramebufferConfig = @import("common").FramebufferConfig;

export fn kernelMain(
    framebuffer_config: *const FramebufferConfig,
) callconv(.{ .x86_64_sysv = .{} }) noreturn {
    for (0..framebuffer_config.horizontal_resolution) |x| {
        for (0..framebuffer_config.vertical_resolution) |y| {
            _ = writePixel(
                framebuffer_config,
                @intCast(x),
                @intCast(y),
                .{ .r = 255, .g = 255, .b = 255 },
            );
        }
    }

    for (0..200) |x| {
        for (0..100) |y| {
            _ = writePixel(
                framebuffer_config,
                @intCast(100 + x),
                @intCast(200 + y),
                .{ .r = 0, .g = 255, .b = 0 },
            );
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

fn writePixel(config: *const FramebufferConfig, x: u32, y: u32, c: PixelColor) i8 {
    const pixel_position = config.pixels_per_scan_line * y + x;
    if (config.pixel_format == .rgb_resv_8_bit_per_color) {
        var p = config.frame_buffer[4 * pixel_position ..][0..3];
        p[0] = c.r;
        p[1] = c.g;
        p[2] = c.b;
    } else if (config.pixel_format == .bgr_resv_8_bit_per_color) {
        var p = config.frame_buffer[4 * pixel_position ..][0..3];
        p[0] = c.b;
        p[1] = c.g;
        p[2] = c.r;
    } else {
        return -1;
    }

    return 0;
}
