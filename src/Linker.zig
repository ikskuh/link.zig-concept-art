const std = @import("std");

const Linker = @This();

pub const Symbol = enum(u64) {
    null,
    _,
};

pub const Section = struct {
    linker: *Linker,

    load_address: u64,
    size: u64,

    pub fn setLoadAddress(section: *Section, load_addr: u64) void {
        section.load_address = load_addr;
    }

    pub fn includeSymbols(section: *Section, glob: []const u8, options: struct { keep: bool = false }) void {
        _ = options;
        _ = glob;
        _ = section;
    }

    pub fn emitLiteral(section: *Section, comptime T: type, value: T) void {
        _ = value;
        _ = section;
    }

    pub fn emitReference(section: *Section, symbol: Symbol) void {
        _ = symbol;
        _ = section;
    }
};

pub const ProgramHeader = struct {
    linker: *Linker,
};

pub const BinaryFormat = enum { elf, binary, pe, ihex, wasm };

is_linked: bool = false,

format: BinaryFormat,

pub fn addProgramHeader(linker: *Linker, name: []const u8, options: struct { load: bool }) *ProgramHeader {
    _ = options;
    _ = name;
    _ = linker;
    return undefined;
}

pub fn createSection(linker: *Linker, name: []const u8, options: struct { header: ?*ProgramHeader }) *Section {
    _ = linker;
    _ = name;
    _ = options;
    return undefined;
}

pub fn declareSymbol(linker: *Linker, name: []const u8) Symbol {
    _ = linker;

    _ = name;
    return undefined;
}

pub const SymbolReference = enum { rel, abs };
pub fn defineSymbol(linker: *Linker, name: ?[]const u8, reference: SymbolReference, offset: i64, options: struct {}) Symbol {
    _ = options;
    _ = offset;
    _ = reference;
    _ = name;
    _ = linker;
    return undefined;
}

pub fn defineComputedSymbol(linker: *Linker, name: ?[]const u8, computer: anytype) Symbol {
    const Computer = @TypeOf(computer);
    _ = Computer;
    _ = name;
    _ = linker;
    return undefined;
}

pub fn getSymbolOffset(linker: *Linker, symbol: Symbol) u64 {
    _ = symbol;
    _ = linker;
    return undefined;
}

pub fn link(linker: *Linker) void {
    _ = linker;
}

pub fn setEntryPoint(linker: *Linker, symbol: Symbol) void {
    _ = symbol;
    _ = linker;
}

pub fn setVirtualAddress(linker: *Linker, offset: u64) void {
    _ = offset;
    _ = linker;
}

pub fn incrementVirtualAddress(linker: *Linker, increment: u64) void {
    _ = increment;
    _ = linker;
}

pub fn alignVirtualAddress(linker: *Linker, alignment: u64) void {
    _ = alignment;
    _ = linker;
}
