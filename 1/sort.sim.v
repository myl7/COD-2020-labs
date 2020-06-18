module SortSim();
  reg clk = 1, rst = 1;
  reg [2:0] x0, x1, x2, x3;
  wire [2:0] s0, s1, s2, s3;
  wire done;

  always #10 clk = ~clk;

  Sort#(.N(3)) sort(
    .clk(clk), .rst(rst), .done(done),
    .x0(x0), .x1(x1), .x2(x2), .x3(x3),
    .s0(s0), .s1(s1), .s2(s2), .s3(s3)
  );

  initial begin
    rst = 1;
    #20
    x0 = -1; x1 = -2; x2 = 3; x3 = 2;
    rst = 0;
    #2000;
    rst = 1;
    #20
    x0 = 0; x1 = 1; x2 = 2; x3 = 3;
    rst = 0;
    #2000;
  end
endmodule
