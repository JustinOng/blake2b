module mix_test();

//Before: a=0x6a09e667f2bdc91cL b=0x510e527fade682d1L c=0x6a09e667f3bcc908L d=0x510e527fade682d4L x=0x6f6c6c6568L y=0x0
//After: a=0xf0cf1ab11b5c47c5L b=0x4b716f2129f6614L c=0x37ed6a230704257aL d=0x2ced50392930f14aL

reg clk=0;
reg [64*16-1:0] v;
reg [3:0]
  a = 4'd0,
  b = 4'd4,
  c = 4'd8,
  d = 4'd12;
reg [63:0]
  x = 64'h6f6c6c6568,
  y = 64'h0;

wire [64*16-1:0] v_out;

mix _mix(
  .clk(clk),
  .v(v),
  .a(a),
  .b(b),
  .c(c),
  .d(d),
  .x(x),
  .y(y),
  .v_out(v_out)
);

always
  begin
    #1 clk = ~clk;
  end

initial
  begin
    v[0*64+:64] = 64'h6a09e667f2bdc91c;
    v[4*64+:64] = 64'h510e527fade682d1;
    v[8*64+:64] = 64'h6a09e667f3bcc908;
    v[12*64+:64] = 64'h510e527fade682d4;

    $display("starting!");
    $dumpfile("output.vcd");
    $dumpvars;
    #10 $display("%x %x %x %x\n", v_out[0*64+:64], v_out[4*64+:64], v_out[8*64+:64], v_out[12*64+:64]);
    #10 $finish;
  end

endmodule
