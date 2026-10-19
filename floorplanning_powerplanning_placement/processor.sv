// 1. Package Definition
package typedefs;
  typedef enum logic [2:0] {
    HLT = 3'b000,
    SKZ = 3'b001,
    ADD = 3'b010,
    AND = 3'b011,
    XOR = 3'b100,
    LDA = 3'b101,
    STO = 3'b110,
    JMP = 3'b111
  } opcode_t;
 
  typedef enum logic [2:0] {
    INST_ADDR,
    INST_FETCH,
    INST_LOAD,
    IDLE,
    OP_ADDR,
    OP_FETCH,
    ALU_OP,
    STORE
  } state_t;
endpackage : typedefs
 
import typedefs::*;
 
// 2. ALU Module
module alu (
    output logic [63:0]       out,
    output logic              zero,
    input  logic              clk,
    input  logic [63:0]       accum,
    input  logic [63:0]       data,
    input  typedefs::opcode_t opcode
);
 
  always @(negedge clk) begin
    case (opcode)
      ADD : out <= accum + data;
      AND : out <= accum & data;
      XOR : out <= accum ^ data;
      LDA : out <= data;
      HLT : out <= accum;
      SKZ : out <= accum;
      JMP : out <= accum;
      STO : out <= accum;
      default: out <= accum;
    endcase
  end
 
  always_comb begin
    zero = ~(|accum);
  end
 
endmodule
 
// 3. Control Unit Module
module control (
    output logic              load_ac,
    output logic              mem_rd,
    output logic              mem_wr,
    output logic              inc_pc,
    output logic              load_pc,
    output logic              load_ir,
    output logic              halt,
    input  typedefs::opcode_t opcode,
    input  logic              zero,
    input  logic              clk,
    input  logic              rst_
);
 
  typedefs::state_t state, next_state;
  logic aluop;
 
  assign aluop = (opcode == ADD) || (opcode == AND) || (opcode == XOR) || (opcode == LDA);
 
  always_comb begin
    case (state)
      INST_ADDR : next_state = INST_FETCH;
      INST_FETCH: next_state = INST_LOAD;
      INST_LOAD : next_state = IDLE;
      IDLE      : next_state = OP_ADDR;
      OP_ADDR   : next_state = OP_FETCH;
      OP_FETCH  : next_state = ALU_OP;
      ALU_OP    : next_state = STORE;
      STORE     : next_state = INST_ADDR;
      default   : next_state = INST_ADDR;
    endcase
  end
 
  always_ff @(posedge clk or negedge rst_) begin
    if (!rst_)
      state <= INST_ADDR;
    else
      state <= next_state;
  end
 
  always_comb begin
    {mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr} = 7'b000_0000;
    case (state)
      INST_ADDR : ;
      INST_FETCH: mem_rd = 1'b1;    
      INST_LOAD : begin         
                    mem_rd  = 1'b1;   
                    load_ir = 1'b1;  
                  end
      IDLE      : begin
                    mem_rd  = 1'b1;  
                    load_ir = 1'b1; 
                  end
      OP_ADDR   : begin        
                    inc_pc = 1'b1;
                    halt   = (opcode == HLT);
                  end
      OP_FETCH  : mem_rd = aluop; 
      ALU_OP    : begin          
                    load_ac = aluop;
                    mem_rd  = aluop;
                    inc_pc  = ((opcode == SKZ) && zero);
                    load_pc = (opcode == JMP);
                  end
      STORE     : begin
                    load_ac = aluop;
                    mem_rd  = aluop;
                    inc_pc  = (opcode == JMP || ((opcode == SKZ) && zero));
                    load_pc = (opcode == JMP);
                    mem_wr  = (opcode == STO);
                  end
      default   : ;
    endcase
  end
 
endmodule
 
// 4. Counter Module
module counter (
    output logic [4:0] count,
    input  logic [4:0] data,
    input  logic       clk,
    input  logic       load,
    input  logic       enable,
    input  logic       rst_
);
 
  always_ff @(posedge clk or negedge rst_) begin
    if (!rst_)
      count <= 5'b0;
    else if (load)
      count <= data;
    else if (enable)
      count <= count + 1'b1;
  end
 
endmodule
 
// 5. Memory Module
module mem (
    input  logic        clk,
    input  logic        read,
    input  logic        write, 
    input  logic [4:0]  addr,
    input  logic [63:0] data_in,
    output logic [63:0] data_out
);
 
  logic [63:0] memory [0:31];
  
  always_ff @(posedge clk) begin
    if (write && !read)
      memory[addr] <= data_in;
  end
 
  always_ff @(posedge clk) begin
    if (read && !write)
      data_out <= memory[addr];
  end
 
endmodule
 
// 6. Register Module
module register (
    output logic [63:0] out,
    input  logic [63:0] data,
    input  logic        clk,
    input  logic        enable,
    input  logic        rst_
);
 
  always_ff @(posedge clk or negedge rst_) begin
    if (!rst_)
      out <= 64'b0;
    else if (enable)
      out <= data;
  end
 
endmodule
 
// 7. Scale Multiplexer Module
module scale_mux #(parameter WIDTH = 1) (
    output logic [WIDTH-1:0] out,
    input  logic [WIDTH-1:0] in_a,
    input  logic [WIDTH-1:0] in_b,
    input  logic             sel_a
);
 
  always_comb begin
    case (sel_a)
      1'b1:    out = in_a;
      1'b0:    out = in_b;
      default: out = {WIDTH{1'bx}};
    endcase
  end
 
endmodule
 
// 8. Top-Level CPU Module
module cpu (
    output logic halt,
    output logic load_ir,
    input  logic clk,
    input  logic cntrl_clk,
    input  logic alu_clk,
    input  logic fetch,
    input  logic rst_
);
 
  logic [63:0]      data_out, alu_out, accum, ir_out;
  logic [4:0]       pc_addr, ir_addr, addr;
  typedefs::opcode_t opcode;
  logic             load_ac, mem_rd, mem_wr, inc_pc, load_pc, zero;
logic [7:0]  sram_addr;
logic        sram_csb0, sram_web0;
logic [31:0] sram_dout0 [0:1];


 
  register ac (
      .out(accum),
      .data(alu_out),
      .clk(clk),
      .enable(load_ac),
      .rst_(rst_)
  );
 
  register ir (
      .out(ir_out),
      .data(data_out),
      .clk(clk),
      .enable(load_ir),
      .rst_(rst_)
  );
 
  assign opcode  = typedefs::opcode_t'(ir_out[7:5]);
  assign ir_addr = ir_out[4:0]; 
 
  counter pc (
      .count(pc_addr),
      .data(ir_addr),
      .clk(clk),
      .load(load_pc),
      .enable(inc_pc),
      .rst_(rst_)
  );
 
  alu alu1 (
      .out(alu_out),
      .zero(zero),
      .clk(alu_clk),
      .accum(accum),
      .data(data_out),
      .opcode(opcode)
  );
 
  scale_mux #(5) smx (
      .out(addr),
      .in_a(pc_addr),
      .in_b(ir_addr),
      .sel_a(fetch) 
  );
 

assign sram_addr = {3'b000, addr};
assign sram_csb0 = ~(mem_rd | mem_wr);
assign sram_web0 = ~mem_wr;
assign data_out  = {sram_dout0[1], sram_dout0[0]};


sky130_sram_1kbyte_1rw1r_32x256_8 sram_macro0 (

  .clk0 (~cntrl_clk),
  .csb0 (sram_csb0),
  .web0 (sram_web0),
  .wmask0(4'hF),        // write all 4 bytes every write -- no partial-word writes in this design
  .addr0(sram_addr),
  .din0 (alu_out[31:0]),
  .dout0(sram_dout0[0]),
  .clk1 (~cntrl_clk),
  .csb1 (1'b1),         // port 1 (read-only) unused, kept deselected
  .addr1(8'b0),
  .dout1()              // left unconnected -- not used

);

sky130_sram_1kbyte_1rw1r_32x256_8 sram_macro1 (

  .clk0 (~cntrl_clk),
  .csb0 (sram_csb0),
  .web0 (sram_web0),
  .wmask0(4'hF),        // write all 4 bytes every write -- no partial-word writes in this design
  .addr0(sram_addr),
  .din0 (alu_out[63:32]),
  .dout0(sram_dout0[1]),
  .clk1 (~cntrl_clk),
  .csb1 (1'b1),         // port 1 (read-only) unused, kept deselected
  .addr1(8'b0),
  .dout1()              // left unconnected -- not used

);


 
  control cntl (
      .load_ac(load_ac),
      .mem_rd(mem_rd),
      .mem_wr(mem_wr),
      .inc_pc(inc_pc),
      .load_pc(load_pc),
      .load_ir(load_ir),
      .halt(halt),
      .opcode(opcode),
      .zero(zero),
      .clk(cntrl_clk),
      .rst_(rst_)
  );
 
endmodule
