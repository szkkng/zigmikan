const std = @import("std");
const uefi = std.os.uefi;
const File = uefi.protocol.File;
const toUtf16 = std.unicode.utf8ToUtf16LeStringLiteral;
const MemoryMapSlice = uefi.tables.MemoryMapSlice;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const PhysicalAddress = uefi.tables.PhysicalAddress;
const GraphicsOutput = uefi.protocol.GraphicsOutput;

pub fn main() uefi.Error!void {
    print("Hello, Mikan World!\r\n", .{});

    const bs = uefi.system_table.boot_services.?;
    var memmap_buf: [4096 * 4]u8 align(@alignOf(MemoryDescriptor)) = undefined;
    var memmap = try bs.getMemoryMap(&memmap_buf);

    const root_dir = try openRootDir();
    const memmap_file = try root_dir.open(toUtf16("\\memmap"), .read_write_create, .{});
    try saveMemoryMap(&memmap, memmap_file);

    const gop = try openGop();
    print("Resolution: {d}x{d}, Pixel Format: {s}, {d} pixels/line\r\n", .{
        gop.mode.info.horizontal_resolution,
        gop.mode.info.vertical_resolution,
        @tagName(gop.mode.info.pixel_format),
        gop.mode.info.pixels_per_scan_line,
    });
    print("Frame Buffer: 0x{x} - 0x{x}, Size: {d} bytes\r\n", .{
        gop.mode.frame_buffer_base,
        gop.mode.frame_buffer_base + gop.mode.frame_buffer_size,
        gop.mode.frame_buffer_size,
    });

    const frame_buffer = @as([*]u8, @ptrFromInt(gop.mode.frame_buffer_base))[0..gop.mode.frame_buffer_size];
    for (frame_buffer) |*f| {
        f.* = 255;
    }

    const kernel_file = try root_dir.open(toUtf16("\\kernel.elf"), .read, .{});
    const kernel_file_size = blk: {
        const file_info_size = try kernel_file.getInfoSize(.file);
        const file_info_buffer = try bs.allocatePool(.loader_data, file_info_size);
        defer bs.freePool(file_info_buffer.ptr) catch {};

        const file_info = try kernel_file.getInfo(.file, file_info_buffer[0..]);
        break :blk file_info.file_size;
    };
    const kernel_base_addr: PhysicalAddress = 0x100000;
    const pages = try bs.allocatePages(.{ .address = @ptrFromInt(kernel_base_addr) }, .loader_data, (kernel_file_size + 0xfff) / 0x1000);
    _ = try kernel_file.read(@ptrCast(pages));
    print("Kernel: 0x{x} ({d} bytes)\r\n", .{ kernel_base_addr, kernel_file_size });

    bs.exitBootServices(uefi.handle, memmap.info.key) catch {
        memmap = bs.getMemoryMap(&memmap_buf) catch |err| {
            print("failed to get memory map: {s}\r\n", .{@errorName(err)});
            while (true) {
                asm volatile ("hlt");
            }
        };
        bs.exitBootServices(uefi.handle, memmap.info.key) catch |err| {
            print("Could not exit boot service: {s}\r\n", .{@errorName(err)});
            while (true) {
                asm volatile ("hlt");
            }
        };
    };

    const EntryPointType = *const fn (
        frame_buffer_base: u64,
        frame_buffer_size: u64,
    ) callconv(.{ .x86_64_sysv = .{} }) noreturn;
    const entry_point: EntryPointType = @ptrFromInt(@as(*const u64, @ptrFromInt(kernel_base_addr + 24)).*);
    entry_point(gop.mode.frame_buffer_base, gop.mode.frame_buffer_size);

    print("All done\r\n", .{});

    while (true) {
        asm volatile ("hlt");
    }
}

fn openRootDir() uefi.Error!*File {
    const bs = uefi.system_table.boot_services.?;

    const loaded_image = (try bs.openProtocol(uefi.protocol.LoadedImage, uefi.handle, .{
        .by_handle_protocol = .{
            .agent = uefi.handle,
        },
    })).?;

    const device_handle = loaded_image.device_handle.?;
    const fs = (try bs.openProtocol(uefi.protocol.SimpleFileSystem, device_handle, .{
        .by_handle_protocol = .{
            .agent = uefi.handle,
        },
    })).?;

    return try fs.openVolume();
}

fn saveMemoryMap(map: *MemoryMapSlice, file: *File) uefi.Error!void {
    _ = try file.write("Index, Type, Type(name), PhysicalStart, NumberOfPages, Attribute\r\n");

    print(
        "map->buffer = {x:0>8}, map->map_size = {x:0>8}\r\n",
        .{ @intFromPtr(map.ptr), map.info.len * map.info.descriptor_size },
    );

    var memmap_iter = map.iterator();
    var index: usize = 0;
    while (memmap_iter.next()) |desc| : (index += 1) {
        var buf: [256]u8 = undefined;
        const formatted = std.fmt.bufPrint(
            buf[0..],
            "{d}, {x}, {s}, {x:0>8}, {x}, {x}\n",
            .{ index, desc.type, @tagName(desc.type), desc.physical_start, desc.number_of_pages, @as(u64, @bitCast(desc.attribute)) & 0xfffff },
        ) catch unreachable;
        _ = try file.write(formatted);
    }

    try file.close();
}

fn openGop() uefi.Error!*GraphicsOutput {
    const bs = uefi.system_table.boot_services.?;
    const gop_handle = (try bs.locateHandleBuffer(.{ .by_protocol = &uefi.protocol.GraphicsOutput.guid })).?;
    const gop = (try bs.openProtocol(uefi.protocol.GraphicsOutput, gop_handle[0], .{
        .by_handle_protocol = .{
            .agent = uefi.handle,
        },
    })).?;
    return gop;
}

fn print(comptime format: []const u8, args: anytype) void {
    var buffer: [256]u8 = undefined;
    const formatted = std.fmt.bufPrint(buffer[0..], format, args) catch unreachable;
    var utf16_buf: [256:0]u16 = undefined;
    const len = std.unicode.utf8ToUtf16Le(utf16_buf[0..], formatted) catch unreachable;
    utf16_buf[len] = 0;
    _ = uefi.system_table.con_out.?.outputString(utf16_buf[0..len :0]) catch unreachable;
}
