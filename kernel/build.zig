const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
    });
    const common_mod = b.dependency("common", .{}).module("common");

    const exe = b.addExecutable(.{
        .name = "kernel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .ReleaseSmall,
            .imports = &.{.{ .name = "common", .module = common_mod }},
            .red_zone = false,
        }),
    });
    exe.link_z_relro = false;
    exe.out_filename = "kernel.elf";
    exe.entry = .{ .symbol_name = "kernelMain" };
    exe.image_base = 0x100000;

    b.installArtifact(exe);
}
