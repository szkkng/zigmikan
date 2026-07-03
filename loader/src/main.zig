const std = @import("std");
const uefi = std.os.uefi;
const File = uefi.protocol.File;
const toUtf16 = std.unicode.utf8ToUtf16LeStringLiteral;
const MemoryMapSlice = uefi.tables.MemoryMapSlice;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;

pub fn main() uefi.Error!void {
    print("Hello, Mikan World!\n", .{});

    const bs = uefi.system_table.boot_services.?;
    var memmap_buf: [4096 * 4]u8 align(@alignOf(MemoryDescriptor)) = undefined;
    var memmap = try bs.getMemoryMap(&memmap_buf);

    const root_dir = try openRootDir();
    const memmap_file = try root_dir.open(toUtf16("\\memmap"), .read_write_create, .{});
    try saveMemoryMap(&memmap, memmap_file);

    print("All done\n", .{});

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
    _ = try file.write("Index, Type, Type(name), PhysicalStart, NumberOfPages, Attribute\n");

    print(
        "map->buffer = {x:0>8}, map->map_size = {x:0>8}\n",
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

fn print(comptime format: []const u8, args: anytype) void {
    var buffer: [256]u8 = undefined;
    const formatted = std.fmt.bufPrint(buffer[0..], format, args) catch unreachable;
    var utf16_buf: [256:0]u16 = undefined;
    const len = std.unicode.utf8ToUtf16Le(utf16_buf[0..], formatted) catch unreachable;
    utf16_buf[len] = 0;
    _ = uefi.system_table.con_out.?.outputString(utf16_buf[0..len :0]) catch unreachable;
}
