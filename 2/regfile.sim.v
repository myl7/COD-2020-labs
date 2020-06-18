module RegFileSim();
  reg clk = 0, we;
  reg [4:0] ra0, ra1, wa;
  reg [31:0] wd;
  wire [31:0] rd0, rd1;

  RegFile#(.WIDTH(32)) regfile(
    .clk(clk), .we(we), .ra0(ra0), .ra1(ra1), .wa(wa), .wd(wd), .rd0(rd0), .rd1(rd1));

  always #5 clk = ~clk;

  initial begin
    we = 1;
    ra0 = 0;
    ra1 = 1;
    wa = 0;
    wd = 1;
    #20;
    we = 1;
    ra0 = 0;
    ra1 = 1;
    wa = 0;
    wd = 2;
    #20;
    we = 1;
    ra0 = 0;
    ra1 = 1;
    wa = 1;
    wd = 1;
    #20;
  end
endmodule
