const std = @import("std");

const link_zig = @import("link.zig");
const Linker = @import("Linker.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var allocator = arena.allocator();

    var linker = Linker{
        .allocator = allocator,

        .format = .elf,
    };

    try link_zig.link(&linker);

    if (!linker.is_linked) {
        _ = linker.link();
    }
}
