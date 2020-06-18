module RegFileDebug#(
  parameter WIDTH = 32
)(
  input clk, rst, we,
  input [4:0] ra0, ra1, ra2, wa,
  input [WIDTH - 1:0] wd,
  output reg [WIDTH - 1:0] rd0, rd1, rd2
);
  reg [WIDTH - 1:0] regvec[31:0];

  always @(*) begin
    rd0 = regvec[ra0];
    rd1 = regvec[ra1];
    rd2 = regvec[ra2];
  end

  integer i;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      for (i = 0; i < 32; i = i + 1) begin
        regvec[i] <= 0;
      end
    end else begin
      if (we) begin
        if (wa != 0) begin
          regvec[wa] <= wd;
        end
      end
    end
  end
endmodule

module SingleCycCPUDebug(
  input clk,
  input rst,
  input [5:0] debug_reg_a,
  input [7:0] debug_mem_a,
  output [31:0] debug_reg_d,
  output [31:0] debug_mem_d,
  output o_reg_dst, o_branch, o_mem_to_reg, o_reg_write, o_mem_write, o_alu_op,
    o_alu_src, o_jmp, o_zf,
  output [31:0] pc_in, pc_out, instr, rf_rd1, rf_rd2, alu_y, m_rd
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
    .clk(clk), .a(y[7:0] >> 2), .d(rd1), .we(mem_write), .spo(spo),
    .dpra(debug_mem_a), .dpo(debug_mem_d));

  wire reg_write, reg_dst, mem_to_reg;
  wire [5:0] wa;
  assign wa = reg_dst ? ins[15:11] : ins[20:16];
  wire [31:0] wd;
  assign wd = mem_to_reg ? spo : y;
  RegFileDebug#(.WIDTH(32)) reg_file(
    .clk(clk), .rst(rst), .ra0(ins[25:21]), .ra1(ins[20:16]), .rd0(rd0),
    .rd1(rd1), .we(reg_write), .wa(wa), .wd(wd), .ra2(debug_reg_a),
    .rd2(debug_reg_d));

  CPUCtl cpu_ctl(.clk(clk), .rst(rst), .op(ins[31:26]), .reg_dst(reg_dst),
    .jmp(jmp), .branch(branch), .mem_write(mem_write), .mem_to_reg(mem_to_reg),
    .alu_src(alu_src), .alu_op(alu_op), .reg_write(reg_write),
    .next_pc(go_next_pc));

  assign o_reg_dst = reg_dst;
  assign o_branch = branch;
  assign o_mem_to_reg = mem_to_reg;
  assign o_reg_write = reg_write;
  assign o_mem_write = mem_write;
  assign o_alu_op = alu_op;
  assign o_alu_src = alu_src;
  assign o_jmp = jmp;
  assign o_zf = zf;

  assign pc_in = next_pc;
  assign pc_out = pc;
  assign instr = ins;
  assign rf_rd1 = rd0;
  assign rf_rd2 = rd1;
  assign alu_y = y;
  assign m_rd = spo;
endmodule

module Seg(
  input clk,
  input [7:0] seg0,
  input [7:0] seg1,
  input [7:0] seg2,
  input [7:0] seg3,
  input [7:0] seg4,
  input [7:0] seg5,
  input [7:0] seg6,
  input [7:0] seg7,
  output reg [7:0] seg,
  output reg [3:0] an = 0
);
  reg [11:0] i = 0;

  always @(posedge clk) begin
    i <= i + 1;

    if (i == 12'hfff) begin
      an = an + 1;
    end
  end

  always @(*) begin
    case (an)
      0: seg = seg0;
      1: seg = seg1;
      2: seg = seg2;
      3: seg = seg3;
      4: seg = seg4;
      5: seg = seg5;
      6: seg = seg6;
      default: seg = seg7;
    endcase
  end
endmodule

module Button(
  input in, clk,
  output reg out
);
  reg in_s = 0;
  reg [3:0] i = 1;

  always @(posedge clk) begin
    if (in ^ in_s) begin
      i <= i + 1;

      if (i == 0) begin
        in_s <= in;
      end
    end else begin
      i <= 1;
    end
  end

  reg pre = 0;

  always @(posedge clk) begin
    if (in ^ pre) begin
      pre <= in;

      if (in) begin
        out <= 1;
      end
    end
  end

  always @(posedge clk) begin
    if (out) begin
      out <= 0;
    end
  end
endmodule

module DBU(
  input clk, rst, succ, step, m_rf, inc, dec,
  input [3:0] sel,
  output [15:0] led,
  // output [7:0] seg,
  output [7:0] seg0,
  output [7:0] seg1,
  output [7:0] seg2,
  output [7:0] seg3,
  output [7:0] seg4,
  output [7:0] seg5,
  output [7:0] seg6,
  output [7:0] seg7,
  output [3:0] an
);
  wire [7:0] seg_list [7:0];

  reg [15:0] m_rf_addr = 0;
  wire [31:0] m_data, rf_data;

  reg [31:0] seg_data;

  assign seg0 = seg_list[0];
  assign seg1 = seg_list[1];
  assign seg2 = seg_list[2];
  assign seg3 = seg_list[3];
  assign seg4 = seg_list[4];
  assign seg5 = seg_list[5];
  assign seg6 = seg_list[6];
  assign seg7 = seg_list[7];

  assign seg_list[0] = sel == 0 ? (m_rf ? m_data[3:0] : rf_data[3:0]) : seg_data[3:0];
  assign seg_list[1] = sel == 0 ? (m_rf ? m_data[7:4] : rf_data[7:4]) : seg_data[7:4];
  assign seg_list[2] = sel == 0 ? (m_rf ? m_data[11:8] : rf_data[11:8]) : seg_data[11:8];
  assign seg_list[3] = sel == 0 ? (m_rf ? m_data[15:12] : rf_data[15:12]) : seg_data[15:12];
  assign seg_list[4] = sel == 0 ? (m_rf ? m_data[19:16] : rf_data[19:16]) : seg_data[19:16];
  assign seg_list[5] = sel == 0 ? (m_rf ? m_data[23:20] : rf_data[23:20]) : seg_data[23:20];
  assign seg_list[6] = sel == 0 ? (m_rf ? m_data[27:24] : rf_data[27:24]) : seg_data[27:24];
  assign seg_list[7] = sel == 0 ? (m_rf ? m_data[31:28] : rf_data[31:28]) : seg_data[31:28];

  wire [31:0] pc_in, pc_out, instr, rf_rd1, rf_rd2, alu_y, m_rd;

  always @(*) begin
    case (sel)
      1: seg_data = pc_in;
      2: seg_data = pc_out;
      3: seg_data = instr;
      4: seg_data = rf_rd1;
      5: seg_data = rf_rd2;
      6: seg_data = alu_y;
      default: seg_data = m_rd;
    endcase
  end

  wire reg_dst, branch, mem_to_reg, reg_write, next_pc, mem_write, alu_op,
    alu_src, jmp, zf;

  assign led = sel == 0 ? m_rf_addr : {
    jmp, branch, reg_dst, reg_write, 1'b1, mem_to_reg, mem_write, 2'b00,
    alu_op, alu_src, zf};

  reg up = 0;
  wire cpu_clk;
  assign cpu_clk = succ ? clk : up;
  SingleCycCPUDebug single_cyc_cpu_debug(
    .clk(cpu_clk), .rst(rst), .debug_reg_a(m_rf_addr[5:0]), .debug_mem_a(m_rf_addr[7:0]),
    .debug_reg_d(rf_data), .debug_mem_d(m_data), .o_reg_dst(reg_dst),
    .o_branch(branch), .o_mem_to_reg(mem_to_reg), .o_reg_write(reg_write),
    .o_mem_write(mem_write), .o_alu_op(alu_op), .o_alu_src(alu_src), .o_jmp(jmp), .o_zf(zf),
    .pc_in(pc_in), .pc_out(pc_out), .instr(instr), .rf_rd1(rf_rd1),
    .rf_rd2(rf_rd2), .alu_y(alu_y), .m_rd(m_rd));

  wire inc_o, dec_o;
  Button button_inc(.clk(clk), .in(inc), .out(inc_o));
  Button button_dec(.clk(clk), .in(dec), .out(dec_o));

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      m_rf_addr <= 0;
    end
    else begin
      if (inc_o) begin
        m_rf_addr = m_rf_addr + 1;
      end else if (dec_o) begin
        m_rf_addr = m_rf_addr - 1;
      end
    end
  end

  wire step_o;
  Button button_step(.clk(clk), .in(step), .out(step_o));
  always @(posedge clk) begin
    if (step_o) begin
      if (~up) begin
        up <= 1;
      end
    end

    if (up) begin
      up <= 0;
    end
  end
endmodule
