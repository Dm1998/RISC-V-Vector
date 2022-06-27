module top_tb;

parameter int WIDTH=32;
parameter int ADDR_WIDTH=15;

logic clk;
logic rst;
logic we;
logic [ADDR_WIDTH-1:0] addr_wr;
logic [WIDTH-1:0] data_in;

top top_module(.clk(clk),
               .rst(rst),
               .we(we),
               .addr_wr(addr_wr),
               .data_in(data_in));

initial begin
	clk=1;
	forever #5 clk=~clk;
end

initial begin
    $readmemh("../rtl/vector/testshex.txt",top_module.scalar_proc.instructionmemory.mem);
    $readmemh("../rtl/vector/testshex.txt",top_module.scalar_proc.Datamemory.mem);
end

initial begin
    rst=1;
    we=0;
    addr_wr=0;
    data_in=0;
    @(posedge clk);
    rst=1;
    @(posedge clk);
    rst=0;
    for(int i=0;i<4000000;i++) begin
        @(posedge clk);    
    end
    $stop;
end

endmodule