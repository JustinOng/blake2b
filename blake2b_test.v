module blake2b_test();

reg clk=0;
reg [80*8-1:0] header = 640'h636261;

wire [32*8-1:0] hash_out;

blake2b hasher(
  .clk(clk),
  .header(header),
  .hash(hash_out)
);

always
  begin
    #1 clk = ~clk;
  end

initial
  begin
    $display("starting!");
    $dumpfile("output.vcd");
    $dumpvars;
    // expected: 324dcf027dd4a30a932c441f365a25e86b173defa4b8e58948253471b81b72cf for "abc" as input
    #200 $display("Hash out: 0x%x\nExpected: 0xbddd813c634239723171ef3fee98579b94964e3bb1cb3e427262c8c068d52319", hash_out);
    #200 $finish;
  end

endmodule
