const std = @import("std");

const link_zig = @import("link.zig");
const Linker = @import("Linker.zig");

pub fn main() !void {
    var linker = Linker{
        .format = .elf,
    };

    try link_zig.link(&linker);

    if (!linker.is_linked) {
        linker.link();
    }
}
