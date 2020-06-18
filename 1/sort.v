module Sort#(
  parameter N = 4
)(
  input clk, rst,
  input [N - 1:0] x0, x1, x2, x3,
  output reg [N - 1:0] s0, s1, s2, s3,
  output reg done
);
  parameter SIN = 2'b00;
  parameter SLOOP = 2'b01;
  parameter SSWAP = 2'b10;
  parameter SOUT = 2'b11;

  reg [1:0] cs = SIN;
  reg [1:0] ns;

  reg [N - 1:0] r0, r1, r2, r3;

  reg [1:0] i = 0;
  reg swapped = 0;

  reg [N - 1:0] a, b;
  reg [N - 1:0] ta, tb;
  wire [N - 1:0] y;
  wire cf, of, zf;
  ALU#(.WIDTH(N)) alu(.a(a), .b(b), .y(y), .m(3'b001), .zf(zf), .cf(cf), .of(of));

  always @(posedge clk or posedge rst) begin
    if (rst == 1) begin
      cs <= SIN;
    end else begin
      case (cs)
        SIN: begin
          r0 <= x0;
          r1 <= x1;
          r2 <= x2;
          r3 <= x3;
          i <= 0;
          done <= 0;
        end
        SLOOP: begin
          if (ns != SSWAP) begin
            if (i == 3) begin
              i <= 0;
              swapped <= 0;
            end else begin
              i <= i + 1;
            end
          end

          ta <= a;
          tb <= b;
        end
        SSWAP: begin
          case (i)
            2'b00: begin
              r0 <= b;
              r1 <= a;
            end
            2'b01: begin
              r1 <= b;
              r2 <= a;
            end
            default: begin
              r2 <= b;
              r3 <= a;
            end
          endcase

          swapped <= 1;
        end
        SOUT: begin
          s0 <= r0;
          s1 <= r1;
          s2 <= r2;
          s3 <= r3;
          done <= 1;
        end
      endcase

      cs <= ns;
    end
  end

  always @(r0, r1, r2, r3, i) begin
    case (i)
      2'b00: begin
        a = r0;
        b = r1;
      end
      2'b01: begin
        a = r1;
        b = r2;
      end
      default: begin
        a = r2;
        b = r3;
      end
    endcase
  end

  always @(cs, i, swapped, y, of) begin
    case (cs)
      SIN: ns = SLOOP;
      SLOOP: begin
        if (i == 3 && swapped == 0) begin
          ns = SOUT;
        end else if (y[N - 1] ^ of == 1) begin
          ns = SSWAP;
        end else begin
          ns = cs;
        end
      end
      SSWAP: ns = SLOOP;
      SOUT: ns = SIN;
    endcase
  end
endmodule
