frame_buffer: []u8,
pixels_per_scan_line: u32,
horizontal_resolution: u32,
vertical_resolution: u32,
pixel_format: PixelFormat,

const PixelFormat = enum {
    rgb_resv_8_bit_per_color,
    bgr_resv_8_bit_per_color,
};
