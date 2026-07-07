export fn KernelMain(
    frame_buffer_base: u64,
    frame_buffer_size: u64,
) callconv(.{ .x86_64_sysv = .{} }) noreturn {
    const frame_buffer = @as([*]u8, @ptrFromInt(frame_buffer_base))[0..frame_buffer_size];
    for (frame_buffer, 0..) |*f, i| {
        f.* = @intCast(i % 256);
    }
    while (true) {
        asm volatile ("hlt");
    }
}
