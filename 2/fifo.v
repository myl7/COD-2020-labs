module FIFO(
  input clk, rst, eni, eno,
  input [7:0] din,
  output reg [7:0] dout,
  output reg [4:0] n
);
  reg we = 0;
  reg [3:0] a;
  reg [7:0] d;
  wire [7:0] spo;

  reg [3:0] af = 0, al = 0;
  reg [4:0] n = 0;

  DistMem distmem(.clk(clk), .we(we), .a(a), .d(d), .spo(spo));

  parameter SW = 0;
  parameter SP = 1;
  reg cs = SW, ns;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      af <= 0;
      al <= 0;
      cs <= SW;
    end else begin
      cs <= ns;
    end
  end

  always @(*) begin
    if (cs == SW) begin
      if (eni || eno) begin
        ns = SP;
      end else begin
        ns = SW;
      end
    end else begin
      ns = SW;
    end
  end

  always @(posedge clk) begin
    if (cs == SW) begin
      if (eni) begin
        if (af + 1 != al) begin
          a <= af;
          d <= din;
          we <= 1;
          af <= af + 1;
          n <= n + 1;
        end
      end else if (eno) begin
        if (al != af) begin
          a <= al;
          we <= 0;
          al <= al + 1;
          n <= n - 1;
        end
      end
    end else if (eno) begin
      dout <= spo;
    end
  end
endmodule
