module Ctl(
  input clk, rst,
  input [31:0] ins,
  output f_jmp, f_branch, f_rd, f_rw, f_m2r, f_mw, f_alus, f_aluo, f_choke
);
  wire [5:0] op;
  assign op = ins[31:26];
  wire [4:0] ra0;
  assign ra0 = ins[25:21];
  wire [4:0] ra1;
  assign ra1 = ins[20:16];

  reg [31:0] pre_ins = 0;
  wire [5:0] pre_op;
  assign pre_op = pre_ins[31:26];
  wire [4:0] pre_wa;
  assign pre_wa = pre_ins[20:16];

  assign f_choke = (pre_op == 6'b000100) || (
    (pre_op == 6'b100011) && (| pre_wa) && (
      (
        (op != 6'b000010) && (ra0 == pre_wa)
      ) || (
        ((op == 6'b000000) || (op == 6'b000100)) && (ra1 == pre_wa)
      )
    )
  );
  assign f_jmp = f_choke ? 0 : op == 6'b000010;

  always @(posedge clk) begin
    pre_ins <= f_choke ? 0 : ins;
  end

  reg ifid_branch = 0, ifid_rd = 0, ifid_rw = 0, ifid_m2r = 0, ifid_mw = 0, ifid_alus = 0, ifid_aluo = 0;

  always @(posedge clk) begin
    if (f_choke) begin
      ifid_branch <= 0;
      ifid_rw <= 0;
      ifid_m2r <= 0;
      ifid_mw <= 0;
      ifid_alus <= 0;
      ifid_aluo <= 0;
      ifid_rd <= 0;
    end else begin
      ifid_rw <= (op == 6'b000000) || (op == 6'b001000) || (op == 6'b100011);
      ifid_m2r <= op == 6'b100011;
      ifid_mw <= op == 6'b101011;
      ifid_alus <= (op == 6'b001000) || (op == 6'b100011) || (op == 6'b101011);
      ifid_aluo <= op == 6'b000100;

      ifid_branch <= op == 6'b000100;
      ifid_rd <= op == 6'b000000;
    end
  end

  assign f_rd = ifid_rd;
  assign f_branch = ifid_branch;

  reg idex_rw = 0, idex_m2r = 0, idex_mw = 0, idex_alus = 0, idex_aluo = 0;

  always @(posedge clk) begin
    idex_rw <= ifid_rw;
    idex_m2r <= ifid_m2r;
    idex_mw <= ifid_mw;

    idex_alus <= ifid_alus;
    idex_aluo <= ifid_aluo;
  end

  assign f_alus = idex_alus;
  assign f_aluo = idex_aluo;

  reg exmem_rw = 0, exmem_m2r = 0, exmem_mw = 0;

  always @(posedge clk) begin
    exmem_rw <= idex_rw;
    exmem_m2r <= idex_m2r;

    exmem_mw <= idex_mw;
  end

  assign f_mw = exmem_mw;

  reg memwb_rw = 0, memwb_m2r = 0;

  always @(posedge clk) begin
    memwb_m2r <= exmem_m2r;
    memwb_rw <= exmem_rw;
  end

  assign f_m2r = memwb_m2r;
  assign f_rw = memwb_rw;
endmodule
