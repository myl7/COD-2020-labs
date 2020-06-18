module ALU#(
  parameter WIDTH = 32
)(
  input [WIDTH - 1:0] a, b,
  input [2:0] m,
  output reg [WIDTH - 1:0] y,
  output reg cf, of, zf
);
  always @(*) begin
    case (m)
      3'b000: y = a + b;
      3'b001: y = a - b;
      3'b010: y = a & b;
      3'b011: y = a | b;
      3'b100: y = a ^ b;
      default: y = 0;
    endcase
  end

  always @(*) begin
    case ({m[0], a[WIDTH - 1], b[WIDTH - 1], y[WIDTH - 1]})
      4'b0111, 4'b0010, 4'b0100, 4'b1111, 4'b1001, 4'b1010: cf = 1;
      default: cf = 0;
    endcase
  end

  always @(*) begin
    case ({m[0], a[WIDTH - 1], b[WIDTH - 1], y[WIDTH - 1]})
      4'b0001, 4'b0110, 4'b1011, 4'b1100: of = 1;
      default: of = 0;
    endcase
  end

  always @(*) begin
    zf = ~(| y[0]);
  end
endmodule
