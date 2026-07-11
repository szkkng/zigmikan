const FramebufferConfig = @import("common").FramebufferConfig;
const graphics = @import("graphics.zig");
const font = @import("font.zig");
const writeAscii = font.writeAscii;
const writeString = font.writeString;
const PixelWriter = graphics.PixelWriter;
const Console = @import("Console.zig");
const std = @import("std");

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

    var console = Console.init(&pixel_writer, .{ .r = 0, .g = 0, .b = 0 }, .{ .r = 255, .g = 255, .b = 255 });
    var buf: [128]u8 = undefined;

    for (0..27) |i| {
        const s = std.fmt.bufPrint(&buf, "line: {d}\n", .{i}) catch unreachable;
        console.putString(s);
    }

    while (true) {
        asm volatile ("hlt");
    }
}
