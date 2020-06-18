module RegFile#(
  parameter WIDTH = 32
)(
  input clk, rst, we,
  input [4:0] ra0, ra1, wa,
  input [WIDTH - 1:0] wd,
  output reg [WIDTH - 1:0] rd0, rd1
);
  reg [WIDTH - 1:0] regvec[31:0];

  always @(*) begin
    rd0 = (we & (wa == ra0) & (| ra0)) ? wd : regvec[ra0];
    rd1 = (we & (wa == ra1) & (| ra1)) ? wd : regvec[ra1];
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
