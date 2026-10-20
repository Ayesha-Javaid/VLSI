module sram_test (
    input  logic        clk,
    input  logic        csb0,
    input  logic        web0,
    input  logic [3:0]  wmask0,
    input  logic [7:0]  addr0,
    input  logic [31:0] din0,
    output logic [31:0] dout0,
    input  logic        csb1,
    input  logic [7:0]  addr1,
    output logic [31:0] dout1
);

  sram_1rw1r_32_256_8_sky130 sram_macro0 (
      .clk0 (clk),
      .csb0 (csb0),
      .web0 (web0),
      .wmask0(wmask0),
      .addr0(addr0),
      .din0 (din0),
      .dout0(dout0),
      .clk1 (clk),
      .csb1 (csb1),
      .addr1(addr1),
      .dout1(dout1)
  );

endmodule