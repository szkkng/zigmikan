const FramebufferConfig = @import("common").FramebufferConfig;
const graphics = @import("graphics.zig");
const font = @import("font.zig");
const writeAscii = font.writeAscii;
const writeString = font.writeString;
const PixelWriter = graphics.PixelWriter;

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

    for ('!'..('~' + 1), 0..) |c, i| {
        writeAscii(&pixel_writer, 8 * @as(u32, @intCast(i)), 50, @intCast(c), .{ .r = 0, .g = 0, .b = 0 });
    }

    writeString(&pixel_writer, 0, 66, "Hello, world!", .{ .r = 0, .g = 0, .b = 255 });

    while (true) {
        asm volatile ("hlt");
    }
}
