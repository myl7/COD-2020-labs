module PipelineCPUSim();
  reg clk = 0, rst = 1;

  always #5 clk <= ~clk;

  PipelineCPU pipeline_cpu(.clk(clk), .rst(rst));

  initial begin
    #20;
    rst = 0;
  end
endmodule
