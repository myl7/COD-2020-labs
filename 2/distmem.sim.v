module DistMemSim();
  reg clk = 0, we;
  reg [3:0] a;
  reg [7:0] d;
  wire [7:0] spo;

  always #5 clk <= ~clk;

  DistMem distmem(.clk(clk), .we(we), .a(a), .d(d), .spo(spo));

  initial begin
    we = 1;
    a = 0;
    d = 0;
    #20;
    we = 1;
    a = 1;
    d = 1;
    #20;
    we = 1;
    a = 2;
    d = 2;
    #20;
    we = 0;
    a = 0;
    #20;
    we = 0;
    a = 1;
    #20;
    we = 0;
    a = 2;
    #20;
  end
endmodule
