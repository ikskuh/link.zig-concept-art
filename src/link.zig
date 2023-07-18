const std = @import("std");

const Linker = @import("Linker.zig");

comptime {
    _ = link;
}

// Link the file into such an executable:
// https://docs.espressif.com/projects/esptool/en/latest/esp32/advanced-topics/firmware-image-format.html

pub fn link(linker: *Linker) !void {
    linker.format = .binary;

    const hdrseg = linker.addProgramHeader("hdrseg", .{ .load = true });
    const codeseg = linker.addProgramHeader("codeseg", .{ .load = true });
    const rodataseg = linker.addProgramHeader("rodataseg", .{ .load = true });
    const dataseg = linker.addProgramHeader("dataseg", .{ .load = true });

    const section_alignment = 8;

    // Forward declaration
    const data_begin = linker.declareSymbol("__start_data");
    const data_end = linker.declareSymbol("__stop_data");
    const text_begin = linker.declareSymbol("__start_text");
    const text_end = linker.declareSymbol("__stop_text");
    const rodata_begin = linker.declareSymbol("__start_rodata");
    const rodata_end = linker.declareSymbol("__stop_rodata");
    const entry_point = linker.declareSymbol("_start");

    const start_xip = 0x42000000;
    const start_sram = 0x40800000;

    _ = linker.defineSymbol("__start_xip", .abs, start_xip, .{}); // __start_xip  = 0x42000000;
    _ = linker.defineSymbol("__start_sram", .abs, start_sram, .{}); // __start_sram = 0x40800000;

    // Sections:

    const esp_hdr_sect = linker.createSection(".esphdr", .{ .header = hdrseg }); //             .esphdr : AT(0) { ... } :hdrseg

    const data_hdr_sect = linker.createSection(".espseg.1", .{ .header = dataseg }); //         .espseg.0 : AT(LOADADDR(.esphdr) + SIZEOF(.esphdr)) { ... } :hdrseg
    const data_sect = linker.createSection(".data", .{ .header = dataseg }); //                 .data : AT(SIZEOF(.esphdr) + SIZEOF(.espseg.0)) { ... } :dataseg

    const text_hdr_sect = linker.createSection(".espseg.0", .{ .header = codeseg }); //         .espseg.1 : AT(LOADADDR(.data) + SIZEOF(.data)) { ... } :codeseg
    const text_sect = linker.createSection(".text", .{ .header = codeseg }); //                 .text : AT(LOADADDR(.espseg.1) + SIZEOF(.espseg.1)) { ... } :codeseg

    const rodata_hdr_sect = linker.createSection(".espseg.2", .{ .header = rodataseg }); //     .espseg.2 : AT(LOADADDR(.text) + SIZEOF(.text)) { ... } :rodataseg
    const initarray_sect = linker.createSection(".init_array", .{ .header = rodataseg }); //    .init_array : AT(LOADADDR(.espseg.2) + SIZEOF(.espseg.2)) { ... } :rodataseg
    const rodata_sect = linker.createSection(".rodata", .{ .header = rodataseg }); //           .rodata : AT(LOADADDR(.init_array) + SIZEOF(.init_array)) { ... } :rodataseg

    const bss_sect = linker.createSection(".bss", .{ .header = null });
    _ = bss_sect; //                      .bss : { ... } :NONE

    // SETUP RAM SYMBOLS
    linker.setVirtualAddress(start_sram); //     . = __start_sram ;

    _ = linker.defineSymbol("__start_data", .rel, 0, .{}); //     __start_data = .;
    {
        _ = linker.defineSymbol("__global_pointer$", .rel, 0, .{}); //         __global_pointer$ = .;

        data_sect.includeSymbols(".sdata", .{}); //  *(.sdata)
        data_sect.includeSymbols(".sdata*", .{}); // *(.sdata*)
        data_sect.includeSymbols(".data", .{}); //   *(.data)
        data_sect.includeSymbols(".data*", .{}); //  *(.data*)

        linker.alignVirtualAddress(section_alignment);
    }
    _ = linker.defineSymbol("__stop_data", .rel, 0, .{});

    _ = linker.defineSymbol("__start_bss", .rel, 0, .{}); // __start_bss = .;
    {
        data_sect.includeSymbols(".sbss", .{}); //   *(.sbss)
        data_sect.includeSymbols(".sbss*", .{}); //  *(.sbss*)
        data_sect.includeSymbols(".bss", .{}); //    *(.bss)
        data_sect.includeSymbols(".bss*", .{}); //   *(.bss*)

        linker.alignVirtualAddress(section_alignment); // . = ALIGN(__section_alignment);
    }
    _ = linker.defineSymbol("__stop_bss", .rel, 0, .{}); // __stop_bss = .;

    // SETUP FLASH SYMBOLS
    linker.setVirtualAddress(start_xip); //     . = __start_xip;

    {
        esp_hdr_sect.emitLiteral(u8, 0xE9); //          BYTE(0xE9);       /* Magic byte. */
        esp_hdr_sect.emitLiteral(u8, 3); //             BYTE(3);          /* Segment count. */
        esp_hdr_sect.emitLiteral(u8, 0x02); //          BYTE(0x02);       /* SPI mode. */
        esp_hdr_sect.emitLiteral(u8, 0x10); //          BYTE(0x10);       /* SPI speed/size. */
        esp_hdr_sect.emitReference(entry_point); //     LONG(_start);     /* Entrypoint. */
        esp_hdr_sect.emitLiteral(u8, 0xee); //          BYTE(0xee);       /* WP pin state. */
        esp_hdr_sect.emitLiteral(u8, 0x00); //          BYTE(0x00);       /* Drive settings. */
        esp_hdr_sect.emitLiteral(u8, 0x00); //          BYTE(0x00);
        esp_hdr_sect.emitLiteral(u8, 0x00); //          BYTE(0x00);
        esp_hdr_sect.emitLiteral(u16, 0x000D); //       SHORT(0x000D);    /* Chip (ESP32-C6). */
        esp_hdr_sect.emitLiteral(u8, 0x00); //          BYTE(0x00);       /* (deprecated) */
        esp_hdr_sect.emitLiteral(u8, 0x0000); //        SHORT(0x0000);    /* Min chip rev. */
        esp_hdr_sect.emitLiteral(u8, 0x0000); //        SHORT(0x0000);    /* Max chip rev. */
        esp_hdr_sect.emitLiteral(u32, 0x00000000); //   LONG(0x00000000); /* (reserved) */
        esp_hdr_sect.emitLiteral(u8, 0x00); //          BYTE(0x00);       /* SHA256 appended (not appended). */

    }

    {
        const section_length = linker.defineComputedSymbol(null, SymbolDistance{
            .end = data_end,
            .begin = data_begin,
        });

        data_hdr_sect.emitReference(data_begin); //     LONG(__start_data);
        data_hdr_sect.emitReference(section_length); // LONG(__stop_data - __start_data);
    }

    linker.incrementVirtualAddress(data_sect.size); //     . = . + SIZEOF(.data);

    {
        const section_length = linker.defineComputedSymbol(null, SymbolDistance{
            .end = text_end,
            .begin = text_begin,
        });
        text_hdr_sect.emitReference(text_begin); //     LONG(__start_text);
        text_hdr_sect.emitReference(section_length); // LONG(__stop_text - __start_text);
    }

    _ = linker.defineSymbol("__start_text", .rel, 0, .{}); // __start_text = .;
    {
        linker.alignVirtualAddress(256); //                          . = ALIGN(256);

        text_sect.includeSymbols(".interrupt_vector_table", .{}); // *(.interrupt_vector_table)
        text_sect.includeSymbols(".text", .{}); //                   *(.text)
        text_sect.includeSymbols(".text*", .{}); //                  *(.text*)

        linker.alignVirtualAddress(section_alignment); //            . = ALIGN(__section_alignment);
    }
    _ = linker.defineSymbol("__stop_text", .rel, 0, .{}); // __stop_text = .;

    {
        const section_length = linker.defineComputedSymbol(null, SymbolDistance{
            .end = rodata_end,
            .begin = rodata_begin,
        });
        rodata_hdr_sect.emitReference(rodata_begin); //   LONG(__start_rodata);
        rodata_hdr_sect.emitReference(section_length); // LONG(__stop_rodata - __start_rodata);
    }

    _ = linker.defineSymbol("__start_rodata", .rel, 0, .{}); // __start_rodata = .;
    {
        _ = linker.defineSymbol("__start_init_array", .rel, 0, .{}); //      __start_init_array = .;
        initarray_sect.includeSymbols(".init_array", .{ .keep = true }); //  KEEP(*(.init_array))
        _ = linker.defineSymbol("__stop_init_array", .rel, 0, .{}); //       __stop_init_array = .;
    }
    {
        rodata_sect.includeSymbols(".rodata", .{}); //   *(.rodata)
        rodata_sect.includeSymbols(".rodata*", .{}); //  *(.rodata*)
        rodata_sect.includeSymbols(".srodata", .{}); //  *(.srodata)
        rodata_sect.includeSymbols(".srodata*", .{}); // *(.srodata*)

        linker.alignVirtualAddress(section_alignment); // . = ALIGN(__section_alignment);
    }
    _ = linker.defineSymbol("__stop_rodata", .rel, 0, .{}); // __stop_rodata = .;

    // Define physical (binary image) addresses

    // we load the sections one after another at address 0
    var addr: u64 = 0;

    esp_hdr_sect.setLoadAddress(0); //       .esphdr : AT(0) {
    addr += esp_hdr_sect.size;
    data_hdr_sect.setLoadAddress(addr); //   .espseg.0 : AT(LOADADDR(.esphdr) + SIZEOF(.esphdr)) {
    addr += data_hdr_sect.size;
    text_sect.setLoadAddress(addr); //       .data : AT(SIZEOF(.esphdr) + SIZEOF(.espseg.0)) {
    addr += text_sect.size;
    text_hdr_sect.setLoadAddress(addr); //   .espseg.1 : AT(LOADADDR(.data) + SIZEOF(.data)) {
    addr += text_hdr_sect.size;
    data_sect.setLoadAddress(addr); //       .text : AT(LOADADDR(.espseg.1) + SIZEOF(.espseg.1)) {
    addr += data_sect.size;
    rodata_hdr_sect.setLoadAddress(addr); // .espseg.2 : AT(LOADADDR(.text) + SIZEOF(.text)) {
    addr += rodata_hdr_sect.size;
    initarray_sect.setLoadAddress(addr); //  .init_array : AT(LOADADDR(.espseg.2) + SIZEOF(.espseg.2)) {
    addr += initarray_sect.size;
    rodata_sect.setLoadAddress(addr); //     .rodata : AT(LOADADDR(.init_array) + SIZEOF(.init_array)) {

    // ENTRY(_start)
    linker.setEntryPoint(entry_point);

    // This is optional and will perform the linking.
    linker.link();

    // We can now perform post processing on section contents:

    // TODO:
    // import os

    // # Use objcopy to extract the image from the ELF file.
    // os.system("riscv32-unknown-elf-objcopy -O binary build/main.elf build/main.bin")

    // # Open the generated file for appending a checksum.
    // fd = open("build/main.bin", "+ab")

    // # Determine the length of the file.
    // fd.seek(0, 2)
    // raw_size = fd.tell()

    // # Append padding bytes.
    // padd_size = ((raw_size + 15) & ~15) - raw_size
    // if padd_size == 0:
    //     fd.write(b"\0" * 15)
    // elif padd_size > 1:
    //     fd.write(b"\0" * (padd_size - 1))

    // # Initialise checksum.
    // xsum_state = 0xEF

    // fd.seek(1, 0)
    // seg_num = fd.read(1)[0]

    // def readword():
    //     raw = fd.read(4)
    //     return raw[0] + (raw[1] << 8) + (raw[2] << 16) + (raw[3] << 24)

    // # Compute checksum.
    // fd.seek(24)
    // for _ in range(seg_num):
    //     seg_laddr = readword()
    //     seg_len = readword()
    //     for _ in range(seg_len):
    //         xsum_state ^= fd.read(1)[0]

    // # Append checksum.
    // fd.seek(0, 2)
    // fd.write(bytes([xsum_state]))
}

const SymbolDistance = struct {
    end: Linker.Symbol,
    begin: Linker.Symbol,

    pub fn compute(sd: *SymbolDistance, linker: *Linker) u64 {
        return linker.getSymbolOffset(sd.end) - linker.getSymbolOffset(sd.begin);
    }
};
