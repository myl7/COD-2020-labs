module MultiCycCPU(
  input clk, rst
);
  localparam S_IF = 0;
  localparam S_ID = 1;
  localparam S_EX = 2;
  localparam S_MEM = 3;
  localparam S_WB = 4;

  wire [8:0] ins_a;
  wire [31:0] ins_spo;

  wire reg_we;
  wire [4:0] ra0, ra1, wa;
  wire [31:0] rd0, rd1, wd;
  RegFile#(.WIDTH(32)) reg_file(
    .clk(clk), .rst(rst), .we(reg_we), .ra0(ra0), .ra1(ra1), .wa(wa), .wd(wd),.rd0(rd0), .rd1(rd1));

  wire [31:0] a, b, y;
  wire [2:0] m;
  wire zf;
  ALU#(.WIDTH(32)) alu(.a(a), .b(b), .m(m), .y(y), .zf(zf));

  wire mem_we;
  wire [8:0] mem_a;
  wire [31:0] mem_d, mem_spo;
  DistMem ram(.clk(clk), .we(mem_we), .a(mem_a), .d(mem_d), .spo(mem_spo), .dpra(ins_a), .dpo(ins_spo));

  wire [5:0] op;
  wire f_jmp, f_branch, f_rd, f_rw, f_m2r, f_mw, f_alus, f_aluo;
  wire [2:0] cs, ns;
  Ctl ctl(
    .clk(clk), .rst(rst), .cs(cs), .ns(ns), .op(op),
    .f_jmp(f_jmp), .f_branch(f_branch), .f_rd(f_rd), .f_rw(f_rw),
    .f_m2r(f_m2r), .f_mw(f_mw), .f_alus(f_alus), .f_aluo(f_aluo));

  reg [31:0] pc = 0;
  assign ins_a = pc[10:0] >> 2;
  wire [31:0] npc_ser;
  assign npc_ser = pc + 4;
  wire [27:0] j_a;
  assign j_a = ins_spo[25:0] << 2;
  assign op = ins_spo[31:26];

  reg [31:0] ifid_ins = 0, ifid_npc_ser = 0;
  reg [27:0] ifid_j_a = 0;
  reg [4:0] ifid_wa = 0;

  always @(posedge clk) begin
    if (cs == S_IF) begin
      ifid_ins <= ins_spo;
      ifid_npc_ser <= npc_ser;
      ifid_j_a <= j_a;
    end
  end

  assign ra0 = ifid_ins[25:21];
  assign ra1 = ifid_ins[20:16];
  wire [4:0] wa_pre;
  assign wa_pre = f_rd ? ins_spo[15:11] : ins_spo[20:16];
  wire [31:0] imm;
  assign imm = {{16{ifid_ins[15]}}, ifid_ins[15:0]};
  wire [31:0] npc_j;
  assign npc_j = {ifid_npc_ser[31:28], ifid_j_a};

  reg [31:0] idex_rd0 = 0, idex_rd1 = 0, idex_imm = 0, idex_npc_ser = 0, idex_npc_j = 0;
  reg [4:0] idex_wa = 0;

  always @(posedge clk) begin
    if (cs == S_ID) begin
      idex_rd0 <= rd0;
      idex_rd1 <= rd1;
      idex_imm <= imm;
      idex_npc_ser <= ifid_npc_ser;
      idex_npc_j <= npc_j;
      idex_wa <= wa_pre;
    end
  end

  assign a = idex_rd0;
  assign b = f_alus ? idex_imm : idex_rd1;
  assign m = f_aluo;
  wire [31:0] npc_beq;
  assign npc_beq = idex_npc_ser + (idex_imm << 2);

  reg [31:0] exmem_y = 0, exmem_zf = 0, exmem_mem_d = 0, exmem_npc_beq = 0, exmem_npc_ser = 0, exmem_npc_j = 0;
  reg [4:0] exmem_wa = 0;

  always @(posedge clk) begin
    if (cs == S_EX) begin
      exmem_y <= y;
      exmem_zf <= zf;
      exmem_mem_d <= idex_rd1;
      exmem_npc_beq <= npc_beq;
      exmem_npc_ser <= idex_npc_ser;
      exmem_npc_j <= idex_npc_j;
      exmem_wa <= idex_wa;
    end
  end

  assign mem_a = exmem_y[10:0] >> 2;
  assign mem_d = exmem_mem_d;
  assign mem_we = f_mw;
  wire [31:0] npc;
  assign npc = f_jmp ? exmem_npc_j : (f_branch & exmem_zf ? exmem_npc_beq : exmem_npc_ser);

  always @(posedge clk) begin
    if (ns == S_IF) begin
      pc <= npc;
    end
  end

  reg [31:0] memwb_mem_spo = 0, memwb_y = 0;
  reg [4:0] memwb_wa = 0;

  always @(posedge clk) begin
    if (cs == S_MEM) begin
      memwb_mem_spo <= mem_spo;
      memwb_y <= exmem_y;
      memwb_wa <= exmem_wa;
    end
  end

  assign wa = memwb_wa;
  assign wd = f_m2r ? memwb_mem_spo : memwb_y;
  assign reg_we = f_rw;
endmodule
