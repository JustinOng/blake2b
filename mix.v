// built based on
// https://github.com/secworks/blake2/blob/master/src/rtl/blake2_G.v
// https://github.com/Toms42/fpga-hash-breaker/blob/master/design%20files/hash-operation.v

module mix(
  input clk,
  input wire [64*16-1:0] v,
  input wire [3:0] a, b, c, d,
  input wire [63:0] x, y,
  output reg [64*16-1:0] v_out
);

reg [63:0]
  a0, a1,
  b0, b1, b2, b3,
  c0, c1,
  d0, d1, d2, d3;

reg [4:0] i;

always @(posedge clk)
  begin
    //$display("Before: %x %x %x %x x=%x y=%x", v[a*64+:64], v[b*64+:64], v[c*64+:64], v[d*64+:64], x, y);
    a0 = v[a*64+:64] + v[b*64+:64] + x;
    d0 = v[d*64+:64] ^ a0;
    // >> 32
    d1 = { d0[0+:32], d0[32+:32] };

    c0 = v[c*64+:64] + d1;
    b0 = v[b*64+:64] ^ c0;
    // >> 24
    b1 = { b0[0+:24], b0[24+:40] };

    a1 = a0 + b1 + y;
    d2 = d1 ^ a1;
    // >> 16
    d3 = { d2[0+:16], d2[16+:48]};

    c1 = c0 + d3;
    b2 = b1 ^ c1;
    // >> 63
    b3 = { b2[0+:63], b2[63+:1] };

    for(i = 0; i < 16; i = i + 1)
    begin
      if(i != a && i != b && i != c && i != d)
      begin
        v_out[i*64+:64] <= v[i*64+:64];
      end
    end

    v_out[a*64+:64] <= a1;
    v_out[b*64+:64] <= b3;
    v_out[c*64+:64] <= c1;
    v_out[d*64+:64] <= d3;

    //$display("After: %x %x %x %x\n", v_out[a*64+:64], v_out[b*64+:64], v_out[c*64+:64], v_out[d*64+:64]);
  end
endmodule
