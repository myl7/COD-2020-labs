module FIFOSim();
  reg clk = 0, rst = 0, eni, eno;
  reg [7:0] din;
  wire [7:0] dout;
  wire [4:0] n;

  always #5 clk <= ~clk;

  FIFO fifo(.clk(clk), .rst(rst), .eni(eni), .eno(eno), .din(din), .dout(dout), .n(n));

  initial begin
    eni = 0;
    eno = 0;
    #20;
    eni = 1;
    eno = 0;
    din = 0;
    #20;
    din = 1;
    #20;
    din = 2;
    #20;
    din = 3;
    #20;
    din = 4;
    #20;
    eni = 0;
    eno = 1;
    #20;
    #20;
    #20;
    #20;
    #20;
  end
endmodule
