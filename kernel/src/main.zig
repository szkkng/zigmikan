const FramebufferConfig = @import("common").FramebufferConfig;
const graphics = @import("graphics.zig");
const font = @import("font.zig");
const PixelWriter = graphics.PixelWriter;
const PixelColor = graphics.PixelColor;
const fillRectangle = graphics.fillRectangle;
const drawRectangle = graphics.drawRectangle;
const Vector2D = graphics.Vector2D;
const Console = @import("Console.zig");
const std = @import("std");
const desktop_bg_color: PixelColor = .{ .r = 45, .g = 118, .b = 237 };
const desktop_fg_color: PixelColor = .{ .r = 255, .g = 255, .b = 255 };
var console: Console = undefined;

const mouse_cursor_shape = [_][]const u8{
    "@              ",
    "@@             ",
    "@.@            ",
    "@..@           ",
    "@...@          ",
    "@....@         ",
    "@.....@        ",
    "@......@       ",
    "@.......@      ",
    "@........@     ",
    "@.........@    ",
    "@..........@   ",
    "@...........@  ",
    "@............@ ",
    "@......@@@@@@@@",
    "@......@       ",
    "@....@@.@      ",
    "@...@ @.@      ",
    "@..@   @.@     ",
    "@.@    @.@     ",
    "@@      @.@    ",
    "@       @.@    ",
    "         @.@   ",
    "         @@@   ",
};

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

    const frame_width = framebuffer_config.horizontal_resolution;
    const frame_height = framebuffer_config.vertical_resolution;

    fillRectangle(
        &pixel_writer,
        .{ .x = 0, .y = 0 },
        .{ .x = frame_width, .y = frame_height - 50 },
        desktop_bg_color,
    );
    fillRectangle(
        &pixel_writer,
        .{ .x = 0, .y = frame_height - 50 },
        .{ .x = frame_width, .y = 50 },
        .{ .r = 1, .g = 8, .b = 17 },
    );
    fillRectangle(
        &pixel_writer,
        .{ .x = 0, .y = frame_height - 50 },
        .{ .x = frame_width / 5, .y = 50 },
        .{ .r = 80, .g = 80, .b = 80 },
    );
    drawRectangle(
        &pixel_writer,
        .{ .x = 10, .y = frame_height - 40 },
        .{ .x = 30, .y = 30 },
        .{ .r = 160, .g = 160, .b = 160 },
    );

    console = Console.init(&pixel_writer, desktop_fg_color, desktop_bg_color);
    printk("Welcome to MikanOS!\n", .{});

    for (mouse_cursor_shape, 0..) |row, y| {
        for (row, 0..) |pixel, x| {
            const color: PixelColor = switch (pixel) {
                '@' => .{ .r = 0, .g = 0, .b = 0 },
                '.' => .{ .r = 255, .g = 255, .b = 255 },
                else => continue,
            };

            pixel_writer.write(
                200 + @as(u32, @intCast(x)),
                100 + @as(u32, @intCast(y)),
                color,
            );
        }
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
