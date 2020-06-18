module CPUCtl(
  input clk, rst,
  input [5:0] op,
  output mem_write, alu_op, alu_src, jmp,
  output reg reg_dst, branch, mem_to_reg, reg_write, next_pc
);
  reg [1:0] cs = SID;
  reg [1:0] ns;
  localparam SID = 0;
  localparam SME = 1;
  localparam SWB = 2;

  reg i_reg_write;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      cs <= SID;
    end else begin
      cs <= ns;
    end
  end

  always @(posedge clk) begin
    if (cs == SID) begin
      i_reg_write <= (op == 6'b000000) || (op == 6'b001000) || (op == 6'b100011);

      reg_dst <= op == 6'b000000;
      branch <= op == 6'b000100;
      mem_to_reg <= op == 6'b100011;
    end
  end

  assign mem_write = op == 6'b101011;

  assign alu_op = op == 6'b000100;

  assign alu_src = (op == 6'b001000) || (op == 6'b100011) || (op == 6'b101011);

  assign jmp = op == 6'b000010;

  always @(negedge clk) begin
    if (cs == SME) begin
      reg_write <= i_reg_write;
    end else if (cs == SWB) begin
      i_reg_write <= 0;
      reg_write <= 0;
    end
  end

  always @(*) begin
    case (cs)
      SID: if (op == 6'b000010) begin
        ns = SID;
      end else begin
        ns = SME;
      end
      SME: if (op == 6'b000100) begin
        ns = SID;
      end else begin
        ns = SWB;
      end
      SWB: ns = SID;
      default: ns = SID;
    endcase

    next_pc = ns == SID;
  end
endmodule
