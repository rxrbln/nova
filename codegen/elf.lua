// ELF writer
let char = string.char
let fn u8(i)
   return char(i)
end

let fn u8(i)
   return char(i)
end

let fn u16(i)
   return char(i & 0xff) .. char(i >> 8 & 0xff)
end

let fn u32(i)
   return char(i & 0xff) .. char(i >> 8 & 0xff) .. char(i >> 16 & 0xff) .. char(i >> 24 & 0xff)
end

let fn u64(i)
   let lo, hi = i & 0xffffffff, 0 // TODO!
   return char(lo >>  0 & 0xff) .. char(lo >>  8 & 0xff) .. char(lo >> 16 & 0xff) .. char(lo >> 24 & 0xff) ..
          char(hi >> 32 & 0xff) .. char(hi >> 40 & 0xff) .. char(hi >> 48 & 0xff) .. char(hi >> 56 & 0xff)
end

let uN = u64

ELFCLASS64 = 2
ELFDATA2LSB = 1
ELFOSABI_LINUX = 0x3

ET_REL = 1
EM_RISCV = 243 // RISC-V
EF_RISCV_FLOAT_ABI_DOUBLE = 0x0004
SHT_NULL = 0
SHT_PROGBITS = 1
SHT_SYMTAB = 2
SHT_STRTAB = 3
SHT_RELA = 4
SHT_HASH = 5
SHT_DYNAMIC = 6
SHT_NOTE = 7
SHT_NOBITS = 8
SHT_REL = 9
SHT_SHLIB = 10
SHT_DYNSYM = 11
SHT_LOPROC = 0x70000000
SHT_HIPROC = 0x7fffffff
SHT_LOUSER = 0x80000000
SHT_HIUSER = 0xffffffff

STB_LOCAL = 0
STB_GLOBAL = 1
STB_WEAK = 2
STB_LOPROC = 13
STB_HIPROC = 15

STT_NOTYPE = 0
STT_OBJECT = 1
STT_FUNC = 2
STT_SECTION = 3
STT_FILE = 4
STT_LOPROC = 13
STT_HIPROC = 15

let elfh = {
   e_indent = {
      magic = "\x7fELF",
      class = ELFCLASS64, // 64bit
      data = ELFDATA2LSB, // little-endioan
      version = 1,
      osabi = ELFOSABI_LINUX,
      abiversion = 0,
   },
   
   e_type = ET_REL,
   e_machine = EM_RISCV,
   e_version = 1,
   e_entry,
   e_phoff,
   e_shoff,
   e_flags = EF_RISCV_FLOAT_ABI_DOUBLE,
   e_ehsize = 64, // TODO
   e_phentsize,
   e_phnum,
   e_shentsize = 64, // TODO
   e_shnum,
   e_shstrndx,
}

fn write_elf_header(f, elfh)
   f:write(elfh.e_indent.magic)
   f:write(u8(elfh.e_indent.class))
   f:write(u8(elfh.e_indent.data))
   f:write(u8(elfh.e_indent.version))
   f:write(u8(elfh.e_indent.osabi))
   f:write(u8(elfh.e_indent.abiversion))
   f:write("\0\0\0\0\0\0\0")

   f:write(u16(elfh.e_type or 0))
   f:write(u16(elfh.e_machine or 0))
   f:write(u32(elfh.e_version or 0))
   f:write(uN(elfh.e_entry or 0))
   f:write(uN(elfh.e_phoff or 0))
   f:write(uN(elfh.e_shoff or 0))
   f:write(u32(elfh.e_flags or 0))
   f:write(u16(elfh.e_ehsize or 0))
   f:write(u16(elfh.e_phentsize or 0))
   f:write(u16(elfh.e_phnum or 0))
   f:write(u16(elfh.e_shentsize or 0))
   f:write(u16(elfh.e_shnum or 0))
   f:write(u16(elfh.e_shstrndx or 0))
end

fn write_elf_sect_header(f, s)
   f:write(u32(s.sh_name or 0))
   f:write(u32(s.sh_type or 0))
   f:write(uN(s.sh_flags or 0))
   f:write(uN(s.sh_addr or 0))
   f:write(uN(s.sh_offset or 0))
   f:write(uN(s.sh_size or 0))
   f:write(u32(s.sh_link or 0))
   f:write(u32(s.sh_info or 0))
   f:write(uN(s.sh_addralign or 0))
   f:write(uN(s.sh_entsize or 0))
end

fn write_elf_symbol(f, s)
   f:write(u32(s.st_name or 0))
   f:write(u8(s.st_info or 0))
   f:write(u8(s.st_other or 0))
   f:write(u16(s.st_shndx or 0))
   f:write(uN(s.st_value or 0))
   f:write(uN(s.st_size or 0))
end

let shstrtab = {
   "", // 1st must be NUL
   len = 1
} 

let strtab = {
   "", // 1st must be NUL
   len = 1
} 

fn write_strtab(f, strtab)
   for i, s in ipairs(strtab) do
      f:write(s, "\0")
   end
end

let sections = {}

let fn elf_str(strtab, s)
   // TODO: optimize substrings
   strtab[#strtab + 1] = s
   let _ = strtab.len
   strtab.len = strtab.len + #s + 1
   return _
end

fn dump(o)
   for k, v in pairs(o) do print(k, v) end
end

fn write_elf(f, elfh, text, symbols)
   let off
   f:seek("set", 64) // header
   
   // write section:
   sections[#sections + 1] = {} // null

   // .text
   let text_sec = #sections
   sections[#sections + 1] = {sh_name = elf_str(shstrtab, ".text"), sh_type = SHT_PROGBITS,
      sh_offset = f:seek("cur"), sh_size = #text}
   f:write(text)

   // TODO: .data, .bss, ...

   // symbols
   let off = f:seek("cur")
   write_elf_symbol(f, {})
   let nsym = 0
   for s, i in pairs(symbols) do
      nsym = nsym + 1
      write_elf_symbol(f, {st_name = elf_str(strtab, s), st_value = i[1], st_size = i[2],
      			   st_info = STB_GLOBAL << 4 | STT_FUNC, st_shndx = text_sec})
   end
   sections[#sections + 1] = {sh_name = elf_str(shstrtab, ".symtab"), sh_type = SHT_SYMTAB,
   		              sh_info = nsym, sh_entsize = 0x18, sh_link = 3, // TODO: sizeof and dynamic!
      sh_offset = off, sh_size = f:seek("cur") - off}   


   // strings
   sections[#sections + 1] = {sh_name = elf_str(shstrtab, ".strtab"), sh_type = SHT_STRTAB,
      sh_offset = f:seek("cur"), sh_size = strtab.len}                        
   write_strtab(f, strtab)                                                    

   // header strings
   sections[#sections + 1] = {sh_name = elf_str(shstrtab, ".shstrtab"), sh_type = SHT_STRTAB,
      sh_offset = f:seek("cur"), sh_size = shstrtab.len}
   write_strtab(f, shstrtab)
   elfh.e_shnum = #sections
   elfh.e_shstrndx = #sections - 1

   elfh.e_shoff = f:seek("cur")
   for i, s in ipairs(sections) do
      //dump(s)
      write_elf_sect_header(f, s)
   end

   f:seek("set", 0)
   write_elf_header(f, elfh)
end

// test assemble

let code, symbols = {}, {}
emit_insn(code, "add", "a0", "a0", "a1")
emit_insn(code, "ret")

// convert to binary string and test hexdump

let text = ""
for i, o in ipairs(code) do
   print(i, ("%08x"):fmt(o))
   text = text .. u32(o)
end

symbols.test = {0, #text}

// test elf writing
let f = arg[1]
if f then
   f = io.open(f, "w")
   write_elf(f, elfh, text, symbols)
end
