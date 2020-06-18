module Ctl(
  input clk, rst,
  input [5:0] op,
  output reg f_jmp = 0, f_branch = 0, f_rd = 0, f_rw = 0, f_m2r = 0, f_mw = 0, f_alus = 0, f_aluo = 0,
  output reg [2:0] cs = S_IF, ns
);
  localparam S_IF = 0;
  localparam S_ID = 1;
  localparam S_EX = 2;
  localparam S_MEM = 3;
  localparam S_WB = 4;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      cs <= S_IF;
    end else begin
      cs <= ns;
    end
  end

  always @(*) begin
    case (cs)
      S_IF: ns = S_ID;
      S_ID: ns = S_EX;
      S_EX: ns = S_MEM;
      S_MEM: ns = S_WB;
      S_WB: ns = S_IF;
      default: ns = S_IF;
    endcase
  end

  reg jmp = 0, branch = 0, rd = 0, rw = 0, m2r = 0, mw = 0, alus = 0, aluo = 0;

  always @(posedge clk) begin
    if (cs == S_IF) begin
      jmp <= op == 6'b000010;
      branch <= op == 6'b000100;
      rw <= (op == 6'b000000) || (op == 6'b001000) || (op == 6'b100011);
      m2r <= op == 6'b100011;
      mw <= op == 6'b101011;
      alus <= (op == 6'b001000) || (op == 6'b100011) || (op == 6'b101011);
      aluo <= op == 6'b000100;
      rd <= op == 6'b000000;

      f_rd <= op == 6'b000000;
    end
  end

  always @(posedge clk) begin
    if (cs == S_ID) begin
      f_alus <= alus;
      f_aluo <= aluo;
    end
  end

  always @(posedge clk) begin
    if (cs == S_EX) begin
      f_jmp <= jmp;
      f_branch <= branch;
      f_mw <= mw;
    end
  end

  always @(posedge clk) begin
    if (cs == S_MEM) begin
      f_m2r <= m2r;
      f_rw <= rw;

      f_mw <= 0;
    end
  end

  always @(posedge clk) begin
    if (cs == S_WB) begin
      f_rw <= 0;
    end
  end
endmodule
