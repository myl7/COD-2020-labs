module PipelineCPU(
  input clk, rst
);
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
  InsDistMem ins_rom(.clk(clk), .we(0), .dpra(ins_a), .dpo(ins_spo));
  DatDistMem dat_ram(.clk(clk), .we(mem_we), .a(mem_a), .d(mem_d), .spo(mem_spo));

  wire [5:0] op;
  wire f_jmp, f_branch, f_rd, f_rw, f_m2r, f_mw, f_alus, f_aluo;
  wire f_choke;
  Ctl ctl(
    .clk(clk), .rst(rst), .ins(ins_spo),
    .f_jmp(f_jmp), .f_branch(f_branch), .f_rd(f_rd), .f_rw(f_rw),
    .f_m2r(f_m2r), .f_mw(f_mw), .f_alus(f_alus), .f_aluo(f_aluo),
    .f_choke(f_choke));

  reg [31:0] pc = 0;
  assign ins_a = pc[10:0] >> 2;
  wire [31:0] npc_ser;
  assign npc_ser = pc + 4;
  wire [31:0] npc_j;
  assign npc_j = {npc_ser[31:28], ins_spo[25:0] << 2};
  assign op = ins_spo[31:26];

  reg [31:0] ifid_ins = 0, ifid_npc_ser = 0;

  always @(posedge clk) begin
    ifid_ins <= ins_spo;
    ifid_npc_ser <= npc_ser;
  end

  assign ra0 = ifid_ins[25:21];
  assign ra1 = ifid_ins[20:16];
  wire [4:0] wa_pre;
  assign wa_pre = f_rd ? ifid_ins[15:11] : ifid_ins[20:16];
  wire [31:0] imm;
  assign imm = {{16{ifid_ins[15]}}, ifid_ins[15:0]};
  wire w_ex2wb;
  assign w_ex2wb = ((ifid_ins[31:26] == 6'b000000) && (| ifid_ins[15:11]))
    || ((ifid_ins[31:26] == 6'b001000) && (| ifid_ins[20:16]));
  wire w_mem2wb;
  assign w_mem2wb = (ifid_ins[31:26] == 6'b100011) && (| ifid_ins[20:16]);

  reg [31:0] idex_rd0 = 0, idex_rd1 = 0, idex_imm = 0, idex_npc_ser = 0;
  reg [31:0] exmem_y = 0;
  reg [4:0] idex_wa = 0, exmem_wa = 0;
  reg idex_w_ex2wb = 0, exmem_w_ex2wb = 0;
  reg idex_w_mem2wb = 0, exmem_w_mem2wb = 0;

  wire [31:0] rd0_bypass, rd1_bypass;
  assign rd0_bypass = (| ra0) ? (
    exmem_w_mem2wb && (ra0 == exmem_wa) ? mem_spo : (
      idex_w_ex2wb && (ra0 == idex_wa) ? y : (
        exmem_w_ex2wb && (ra0 == exmem_wa) ? exmem_y : rd0
      )
    )
  ) : 0;
  assign rd1_bypass = (| ra1) ? (
    exmem_w_mem2wb && (ra1 == exmem_wa) ? mem_spo : (
      idex_w_ex2wb && (ra1 == idex_wa) ? y : (
        exmem_w_ex2wb && (ra1 == exmem_wa) ? exmem_y : rd1
      )
    )
  ) : 0;

  wire [31:0] npc_beq;
  assign npc_beq = ifid_npc_ser + (imm << 2);
  wire beq_zf;
  assign beq_zf = rd0_bypass == rd1_bypass;
  wire [31:0] npc;
  assign npc = rst ? 0 : (
    f_jmp ? npc_j : (
      f_branch & beq_zf ? npc_beq : (
        f_choke ? pc : npc_ser
      )
    )
  );

  always @(posedge clk) begin
    idex_rd0 <= rd0_bypass;
    idex_rd1 <= rd1_bypass;
    idex_imm <= imm;
    idex_npc_ser <= ifid_npc_ser;
    idex_wa <= wa_pre;
    idex_w_ex2wb <= w_ex2wb;
    idex_w_mem2wb <= w_mem2wb;
  end

  assign a = idex_rd0;
  assign b = f_alus ? idex_imm : idex_rd1;
  assign m = f_aluo;

  always @(posedge clk) begin
    pc <= npc;
  end

  reg [31:0] exmem_mem_d = 0;

  always @(posedge clk) begin
    exmem_y <= y;
    exmem_mem_d <= idex_rd1;
    exmem_wa <= idex_wa;
    exmem_w_ex2wb <= idex_w_ex2wb;
    exmem_w_mem2wb <= idex_w_mem2wb;
  end

  assign mem_a = exmem_y[10:0] >> 2;
  assign mem_d = exmem_mem_d;
  assign mem_we = f_mw;

  reg [31:0] memwb_mem_spo = 0, memwb_y = 0;
  reg [4:0] memwb_wa = 0;

  always @(posedge clk) begin
    memwb_mem_spo <= mem_spo;
    memwb_y <= exmem_y;
    memwb_wa <= exmem_wa;
  end

  assign wa = memwb_wa;
  assign wd = f_m2r ? memwb_mem_spo : memwb_y;
  assign reg_we = f_rw;
endmodule
