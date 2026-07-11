const FramebufferConfig = @import("common").FramebufferConfig;
const graphics = @import("graphics.zig");
const font = @import("font.zig");
const PixelWriter = graphics.PixelWriter;
const Console = @import("Console.zig");
const std = @import("std");
var console: Console = undefined;

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

    console = Console.init(&pixel_writer, .{ .r = 0, .g = 0, .b = 0 }, .{ .r = 255, .g = 255, .b = 255 });

    for (0..27) |i| {
        printk("printk: {d}\n", .{i});
    }

    while (true) {
        asm volatile ("hlt");
    }
}

fn printk(comptime format: []const u8, args: anytype) void {
    var buffer: [1024]u8 = undefined;
    const formatted = std.fmt.bufPrint(&buffer, format, args) catch {
        console.putString("printk: buffer too small\n");
        return;
    };
    console.putString(formatted);
}
