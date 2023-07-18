const std = @import("std");

const Linker = @This();

pub const BinaryFormat = enum { elf, binary, pe, ihex, wasm };

pub const SymbolReference = enum { rel, abs };

is_linked: bool = false,

format: BinaryFormat,

pub fn addMemory(linker: *Linker, options: struct {
    base: u64,
    length: u64,
    flags: Memory.Flags,
}) *Memory {
    _ = options;
    _ = linker;
    return undefined;
}

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

pub fn declareSymbol(linker: *Linker, name: []const u8) *Symbol {
    _ = linker;

    _ = name;
    return undefined;
}

pub fn defineGlobalSymbol(linker: *Linker, name: ?[]const u8, reference: SymbolReference, offset: i64, options: struct {}) *Symbol {
    _ = options;
    _ = offset;
    _ = reference;
    _ = name;
    _ = linker;
    return undefined;
}

pub fn defineGlobalComputedSymbol(linker: *Linker, name: ?[]const u8, computer: anytype) *Symbol {
    const Computer = @TypeOf(computer);
    _ = Computer;
    _ = name;
    _ = linker;
    return undefined;
}

pub fn link(linker: *Linker) *Artifact {
    linker.is_linked = true;
    return undefined;
}

pub fn setEntryPoint(linker: *Linker, symbol: *Symbol) void {
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

pub const Symbol = struct {
    linker: *Linker,
    name: ?[]const u8,
    section: ?*Section,
    offset: u64,
};

pub const Section = struct {
    linker: *Linker,

    physical_address: u64,
    virtual_addresS: u64,
    size: u64,

    pub fn setPhysicalAddress(section: *Section, load_addr: u64) void {
        section.physical_address = load_addr;
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

    pub fn emitReference(section: *Section, symbol: *Symbol) void {
        _ = symbol;
        _ = section;
    }

    pub fn defineSymbol(section: *Section, name: ?[]const u8, reference: SymbolReference, offset: i64, options: struct {}) *Symbol {
        _ = options;
        _ = offset;
        _ = reference;
        _ = name;
        _ = section;
        return undefined;
    }

    pub fn defineComputedSymbol(section: *Section, name: ?[]const u8, computer: anytype) *Symbol {
        const Computer = @TypeOf(computer);
        _ = Computer;
        _ = name;
        _ = section;
        return undefined;
    }
};

pub const ProgramHeader = struct {
    linker: *Linker,
};

pub const Memory = struct {
    pub const Flags = struct {
        read: ?bool = null,
        write: ?bool = null,
        execute: ?bool = null,
    };

    linker: *Linker,
    flags: Flags,
    base: u64,
    length: u64,
};

pub const Artifact = struct {
    linker: *Linker,

    pub fn getVirtualSymbolOffset(artifact: *Artifact, symbol: *Symbol) u64 {
        _ = artifact;
        _ = symbol;
        return undefined;
    }

    pub fn getPhysicalSymbolOffset(artifact: *Artifact, symbol: *Symbol) u64 {
        _ = artifact;
        _ = symbol;
        return undefined;
    }

    pub fn readIntLittle(artifact: *Artifact, offset: u64, comptime I: type) I {
        _ = artifact;
        _ = offset;
        return undefined;
    }

    pub fn writeIntLittle(artifact: *Artifact, offset: u64, comptime I: type, value: I) void {
        _ = artifact;
        _ = offset;
        _ = value;
    }
};
