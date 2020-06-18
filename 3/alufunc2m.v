module ALUFunc2M(
  input [5:0] func,
  input alu_op,
  output reg [2:0] m
);
  always @(*) begin
    if (alu_op) begin
      m = 3'b001;
    end else begin
      m = 3'b000;
    end
  end
endmodule
