module BlkMemSim();
  reg clka = 0, ena = 1, wea;
  reg [3:0] addra;
  reg [7:0] dina;
  wire [7:0] douta;

  always #5 clka <= ~clka;

  BlkMem blkmem(.clka(clka), .ena(ena), .wea(wea), .addra(addra), .dina(dina), .douta(douta));

  initial begin
    wea = 1;
    addra = 0;
    dina = 0;
    #20;
    wea = 1;
    addra = 1;
    dina = 1;
    #20;
    wea = 1;
    addra = 2;
    dina = 2;
    #50;
    wea = 0;
    addra = 0;
    #20;
    wea = 0;
    addra = 1;
    #20;
    wea = 0;
    addra = 2;
    #20;
  end
endmodule
