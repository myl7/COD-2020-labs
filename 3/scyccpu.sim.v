module SingleCycCPUSim();
  reg clk = 0, rst = 1;

  always #5 clk <= ~clk;

  reg [7:0] debug_a;
  wire [31:0] debug_d;

  SingleCycCPU single_cyc_cpu(.clk(clk), .rst(rst), .debug_a(debug_a >> 2), .debug_d(debug_d));

  initial begin
      debug_a = 8;
      #50;
      rst = 0;
      #1000;
      $stop;
  end
endmodule
