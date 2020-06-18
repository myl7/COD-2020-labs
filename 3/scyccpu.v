module SingleCycCPU(
  input clk,
  input rst,
  input [7:0] debug_a,
  output [31:0] debug_d
);
  reg [31:0] pc = 0;
  wire [31:0] next_pc;
  wire go_next_pc;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pc <= 0;
    end else if (go_next_pc) begin
      pc <= next_pc;
    end
  end

  wire [31:0] ins;
  InsDistMem ins_rom(.a(pc[9:0] >> 2), .spo(ins), .clk(clk), .we(0));

  wire [31:0] rd0, rd1;

  wire alu_src;
  wire alu_op;
  wire [32:0] ext_imm;
  assign ext_imm = {(ins[15] ? 16'hffff : 16'h0000), ins[15:0]};
  wire [31:0] b;
  assign b = alu_src ? (ins[15] ? ext_imm : ins[15:0]) : rd1;
  wire [2:0] m;
  wire [31:0] y;
  wire cf, of, zf;
  ALUFunc2M alu_func2m(.func(ins[5:0]), .m(m), .alu_op(alu_op));
  ALU#(.WIDTH(32)) alu(
    .a(rd0), .b(b), .m(m), .y(y), .cf(cf), .of(of), .zf(zf));

  wire [31:0] pc_plus4;
  assign pc_plus4 = pc + 4;
  wire [27:0] pc_low;
  assign pc_low = ins[25:0] << 2;
  wire jmp, branch;
  assign next_pc = jmp ? {pc_plus4[31:28], pc_low}
    : (branch & zf ? pc + 4 + (ext_imm << 2) : pc + 4);

  wire mem_write;
  wire [31:0] spo;
  MemDistMem mem_ram(
    .clk(clk), .a(y[7:0] >> 2), .d(rd1), .we(mem_write), .spo(spo), .dpra(debug_a), .dpo(debug_d));

  wire reg_write, reg_dst, mem_to_reg;
  wire [5:0] wa;
  assign wa = reg_dst ? ins[15:11] : ins[20:16];
  wire [31:0] wd;
  assign wd = mem_to_reg ? spo : y;
  RegFile#(.WIDTH(32)) reg_file(
    .clk(clk), .rst(rst), .ra0(ins[25:21]), .ra1(ins[20:16]), .rd0(rd0),
    .rd1(rd1), .we(reg_write), .wa(wa), .wd(wd));

  CPUCtl cpu_ctl(.clk(clk), .rst(rst), .op(ins[31:26]), .reg_dst(reg_dst),
    .jmp(jmp), .branch(branch), .mem_write(mem_write), .mem_to_reg(mem_to_reg),
    .alu_src(alu_src), .alu_op(alu_op), .reg_write(reg_write),
    .next_pc(go_next_pc));
endmodule
