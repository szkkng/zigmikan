const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
    });

    const exe = b.addExecutable(.{
        .name = "kernel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .ReleaseSmall,
            .red_zone = false,
        }),
    });
    exe.link_z_relro = false;
    exe.out_filename = "kernel.elf";
    exe.entry = .{ .symbol_name = "KernelMain" };

    // Temporary workaround until the bootloader loads PT_LOAD segments correctly.
    // Reference: https://github.com/uchan-nos/os-from-zero/issues/140#issuecomment-1445066297
    exe.setLinkerScript(b.path("kernel.ld"));
    // exe.image_base = 0x100000;

    b.installArtifact(exe);
}
