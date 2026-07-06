const std = @import("std");

pub fn build(b: *std.Build) void {
    const loader = b.dependency("loader", .{}).artifact("BOOTX64");
    const install_loader = b.addInstallArtifact(loader, .{
        .dest_dir = .{ .override = .{ .custom = "EFI/BOOT" } },
    });
    const kernel = b.dependency("kernel", .{}).artifact("kernel");
    const install_kernel = b.addInstallArtifact(kernel, .{
        .dest_dir = .{ .override = .{ .custom = "" } },
    });
    install_loader.step.dependOn(&install_kernel.step);
    const ovmf_code = b.graph.environ_map.get("OVMF_CODE") orelse @panic("OVMF_CODE not found");
    const ovmf_vars = b.graph.environ_map.get("OVMF_VARS") orelse @panic("OVMF_VARS not found");

    const run_step = b.step("run", "Run QEMU");
    const qemu_cmd = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-m",
        "1G",
        "-drive",
        b.fmt("format=raw,file=fat:rw:{s}", .{b.install_path}),
        "-drive",
        b.fmt("if=pflash,format=raw,readonly=on,file={s}", .{ovmf_code}),
        "-drive",
        b.fmt("if=pflash,format=raw,readonly=on,file={s}", .{ovmf_vars}),
        "-device",
        "nec-usb-xhci,id=xhci",
        "-device",
        "usb-mouse",
        "-device",
        "usb-kbd",
        "-monitor",
        "stdio",
    });
    qemu_cmd.step.dependOn(&install_loader.step);
    run_step.dependOn(&qemu_cmd.step);
}
