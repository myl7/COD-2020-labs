module ALUSim();
  reg [2:0] a, b;
  reg [2:0] m;
  wire [2:0] y;
  wire zf, cf, of;

  ALU#(.WIDTH(3)) alu(.a(a), .b(b), .m(m), .y(y), .zf(zf), .cf(cf), .of(of));

  initial begin
    m = 3'b000;
    a = 3'b001;
    b = 3'b001;
    #50;
    m = 3'b000;
    a = 3'b001;
    b = 3'b111;
    #50;
    m = 3'b000;
    a = 3'b001;
    b = 3'b011;
    #50;
    m = 3'b001;
    a = 3'b011;
    b = 3'b001;
    #50;
    m = 3'b001;
    a = 3'b001;
    b = 3'b111;
    #50;
    m = 3'b001;
    a = 3'b100;
    b = 3'b011;
    #50;
    m = 3'b010;
    a = 3'b101;
    b = 3'b011;
    #50;
    m = 3'b011;
    a = 3'b001;
    b = 3'b000;
    #50;
    m = 3'b100;
    a = 3'b010;
    b = 3'b011;
    #50;
    m = 3'b101;
    a = 3'b111;
    b = 3'b111;
    #50;
  end
endmodule
