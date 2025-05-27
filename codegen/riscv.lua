
// register: x0 .. x31, xlen pc: xlen-1
// ISA:   31..25  24...20 19...15 14...12 11...7  6...0
// R-type funct7  rs2     rs1     funct3  rd      opcode
// I-type imm11:0         rs1     funct3  rd      opcode
// S-type imm11:5 rs2     rs1     funct3  imm4:0  opcode
// U-type imm31:12                        rd      opcode

// source reg: s2, s1   dest reg: rd
// immedaites are sign extended, bit31 always sign

let opcode = {
    // RV32I
    ["add"] = {0b000000000000110011, t="r"},
    ["jalr"] = {0b0001100111, t="i"},
    ["addi"] = {0b0000010011, t="i"},
//[[
LUI
AUIPC
JAL
JALR
BEQ
BNE
BLT
BGE
BLTU
BGEU
LB
LH
LW
LBU
LHU
SB
SH
SW
ADDI
SLTI
SLTIU
XORI
ORI
ANDI
SLLI
SRLI
SRAI
ADD
SUB
SLL
SLT
SLTU
XOR
SRL
SRA
OR
AND
FENCE
FENCE.I
ECALL
EBREAK
CSRRW
CSRRS
CSRRC
CSRRWI
CSRRSI
CSRRCI
// RV32M
MUL
MULH
MULHSU
MULHU
DIV
DIVU
REM
REMU
// RV64I
LWU
LD
SD
SLLI
SRLI
SRAI
ADDIW
SLLIW
SRLIW
SRAIW
ADDW
SUBW
SLLW
SRLW
SRAW
// RV64M
MULW
DIVW
DIVUW
REMW
REMUW
// RV32F
FLW
FSW
FMADD.S
FMSUB.S
FNMSUB.S
FNMADD.S
FADD.S
FSUB.S
FMUL.S
FDIV.S
FSQRT.S
FSGNJ.S
FSGNJN.S
FSGNJX.S
FMIN.S
FMAX.S
FCVT.W.S
FCVT.WU.S
FMV.X.W
FEQ.S
FLT.S
FLE.S
FCLASS.S
FCVT.S.W
FCVT.S.WU
FMV.W.X
FCVT.L.S
FCVT.LU.S
FCVT.S.L
FCVT.S.LU
// RV32D
FLD
FSD
FMADD.D
FMSUB.D
FNMSUB.D
FNMADD.D
FADD.D
FSUB.D
FMUL.D
FDIV.D
FSQRT.D
FSGNJ.D
FSGNJN.D
FSGNJX.D
FMIN.D
FMAX.D
FCVT.S.D
FCVT.D.S
FEQ.D
FLT.D
FLE.D
FCLASS.D
FCVT.W.D
FCVT.WU.D
FCVT.D.W
FCVT.D.WU
// RV64D
FCVT.L.D
FCVT.LU.D
FMV.X.D
FCVT.D.L
FCVT.D.LU
FMV.D.X
//]]
}

let pseudo = {
    ["ret"] = {"jalr", "zero", "ra", 0},
    ["nop"] = {"addi", "zero", "zero", 0},
//[[
la rd, symbol auipc rd, symbol[31:12] Load address
addi rd, rd, symbol[11:0]
l{b|h|w|d} rd, symbol auipc rd, symbol[31:12] Load global
l{b|h|w|d} rd, symbol[11:0](rd)
s{b|h|w|d} rd, symbol, rt auipc rt, symbol[31:12] Store global
s{b|h|w|d} rd, symbol[11:0](rt)
fl{w|d} rd, symbol, rt auipc rt, symbol[31:12] Floating-point load global
fl{w|d} rd, symbol[11:0](rt)
fs{w|d} rd, symbol, rt auipc rt, symbol[31:12] Floating-point store global
fs{w|d} rd, symbol[11:0](rt)
nop addi x0, x0, 0 No operation
li rd, immediate Myriad sequences Load immediate
mv rd, rs addi rd, rs, 0 Copy register
not rd, rs xori rd, rs, -1 One’s complement
neg rd, rs sub rd, x0, rs Two’s complement
negw rd, rs subw rd, x0, rs Two’s complement word
sext.w rd, rs addiw rd, rs, 0 Sign extend word
seqz rd, rs sltiu rd, rs, 1 Set if = zero
snez rd, rs sltu rd, x0, rs Set if ̸= zero
sltz rd, rs slt rd, rs, x0 Set if < zero
sgtz rd, rs slt rd, x0, rs Set if > zero
fmv.s rd, rs fabs.s rd, rs fmv.d rd, rs fabs.d rd, rs fsgnj.s rd, rs, rs Copy single-precision register
fsgnjx.s rd, rs, rs Single-precision absolute value
fneg.s rd, rs fsgnjn.s rd, rs, rs Single-precision negate
fsgnj.d rd, rs, rs Copy double-precision register
fsgnjx.d rd, rs, rs Double-precision absolute value
fneg.d rd, rs fsgnjn.d rd, rs, rs Double-precision negate
beqz rs, offset bnez rs, offset blez rs, offset bgez rs, offset bltz rs, offset bgtz rs, offset beq rs, x0, offset bne rs, x0, offset bge x0, rs, offset bge rs, x0, offset blt rs, x0, offset blt x0, rs, offset Branch if = zero
Branch if ̸= zero
Branch if ≤zero
Branch if ≥zero
Branch if < zero
Branch if > zero
bgt rs, rt, offset ble rs, rt, offset bgtu rs, rt, offset bleu rs, rt, offset blt rt, rs, offset bge rt, rs, offset bltu rt, rs, offset bgeu rt, rs, offset Branch if >
Branch if ≤
Branch if >, unsigned
Branch if ≤, unsigned
j offset jal x0, offset Jump
jal offset jal x1, offset Jump and link
jr rs jalr x0, rs, 0 Jump register
jalr rs jalr x1, rs, 0 Jump and link register
ret jalr x0, x1, 0 Return from subroutine
call offset auipc x6, offset[31:12] Call far-away subroutine
jalr x1, x6, offset[11:0]
tail offset auipc x6, offset[31:12] Tail call far-away subroutine
jalr x0, x6, offset[11:0]
fence fence iorw, iorw Fence on all memory and I/O
//]]
}

let reg = {
    x0 = 0, x1 = 1, x2 = 2, x3 = 3, x4 = 4, x5 = 5, x6 = 6, x7 = 7,
    x8 = 8, x9 = 9, x10 = 10, x11 = 11, x12 = 12, x13 = 13, x14 = 14, x15 = 15,
    x16 = 16, x17 = 17, x18 = 18, x19 = 19, x20 = 20, x21 = 21, x22 = 22, x23 = 23,
    x24 = 24, x25 = 25, x26 = 26, x27 = 27, x28 = 28, x29 = 29, x30 = 30, x31 = 31,
//} let abireg = {
    zero = 0, ra = 1, sp = 2, gp = 3, tp = 4, t0 = 5, t1 = 6, t2 = 7,
    s0 = 8, s1 = 9, a0 = 10, a1 = 11, a2 = 12, a3 = 13, a4 = 14, a5 = 15,
    a6 = 16, a7 = 17, s2 = 18, s3 = 19, s4 = 20, s5 = 21, s6 = 22, s7 = 23,
    s8 = 24, s9 = 25, s10 = 26, s11 = 27, t3 = 28, t4 = 29, t5 = 30, t6 = 31,
    fp  = 8,
}


let fn conv_reg(r, op, rname)
    let _r = reg[r]
    if not _r then throw(("Invalid reg '%s' for opcode '%s' %s"):fmt(r or "nil", op or "nil", rname or "nil")) end
    return _r
end

fn emit_r(s, op, opc, rd, rs1, rs2)
   let o = opc[1]
   rd, rs1, rs2 = conv_reg(rd, op, "rd"), conv_reg(rs1, op, "rs1"), conv_reg(rs2, op, "rs2")
   let fn3 = ((o >> 7) & 0b111)
   let fn7 = ((o >> 10) & 0b1111111)
   s[#s + 1] = fn7 << 25 | rs2 << 20 | rs1 << 15 | fn3 << 12 | rd << 7 | (o & 0b1111111)
end

fn emit_i(s, op, opc, rd, rs1, imm)
   let o = opc[1]
   rd, rs1 = conv_reg(rd, op, "rd"), conv_reg(rs1, op, "rs1")
   let fn3 = ((o >> 7) & 0b111)
   s[#s + 1] = imm << 20 | rs1 << 15 | fn3 << 12 | rd << 7 | (o & 0b1111111)
end

fn emit_s(s, op, opc, imm, rs1, rs2)
// S-type imm11:5 rs2     rs1     funct3  imm4:0  opcode
   let o = opc[1]
   rs1, rs2 = conv_reg(rs1, op, "rs1"), conv_reg(rs2, op, "rs2")
   let fn3 = ((o >> 7) & 0b111)
   s[#s + 1] = imm << 20 | rs1 << 15 | fn3 << 12 | rd << 7 | (o & 0b1111111)
end

fn emit_u(s, op, opc, rd, imm)
   let o = opc[1]
   rd = conv_reg(rd, op, "rd")
   s[#s + 1] = imm << 12 | rd << 7 | (o & 0b1111111)
end


fn emit_insn(s, op, ...)
   // pseudo insn?
   let opc = pseudo[op]
   if opc then return emit_insn(s, unpack(opc)) end
   
   let opc = opcode[op]
   if not opc then throw("opcode '" .. op .. "' not supported") end
   if opc.t == "r" then
      emit_r(s, op, opc, ...)
   elseif opc.t == "i" then
      emit_i(s, op, opc, ...)
   elseif opc.t == "s" then
      emit_s(s, op, opc, ...)
   elseif opc.t == "u" then
      emit_u(s, op, opc, ...)
   else
      throw("unmatched opcode type: " .. opc.t)
   end
end

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
