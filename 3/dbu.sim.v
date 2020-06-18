module DBUSim();
  reg clk = 0, rst = 1, succ = 0, step = 0, m_rf = 0, inc = 0, dec = 0;
  reg [3:0] sel = 1;
  wire [15:0] led;
  wire [3:0] an;

  wire [7:0] seg0;
  wire [7:0] seg1;
  wire [7:0] seg2;
  wire [7:0] seg3;
  wire [7:0] seg4;
  wire [7:0] seg5;
  wire [7:0] seg6;
  wire [7:0] seg7;

  always #5 clk <= ~clk;

  DBU dbu(.clk(clk), .rst(rst), .succ(succ), .step(step), .m_rf(m_rf),
    .inc(inc), .dec(dec), .sel(sel), .led(led), .seg0(seg0), .seg1(seg1),
    .seg2(seg2), .seg3(seg3), .seg4(seg4), .seg5(seg5), .seg6(seg6), .seg7(seg7), .an(an));

  integer i;

  initial begin
    #100;
    rst = 0;
    succ = 1;
    #100;
    sel = 0;
    #100;
    sel = 1;
    #100;
    sel = 2;
    #100;
    sel = 3;
    #100;
    sel = 4;
    #100;
    sel = 5;
    #100;
    sel = 6;
    #100;
    sel = 7;
    #100;
  end
endmodule
