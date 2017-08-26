// built on https://github.com/Toms42/fpga-hash-breaker/blob/master/design%20files/md5-core.v

module blake2b(
  input clk,
  input wire [80*8-1:0] header,
  output reg [32*8-1:0] hash = 0,
  output reg [63:0] nonce = 0
);

localparam [0:4*8*4-1] v_index = {
  4'd0, 4'd4, 4'd8, 4'd12,
  4'd1, 4'd5, 4'd9, 4'd13,
  4'd2, 4'd6, 4'd10, 4'd14,
  4'd3, 4'd7, 4'd11, 4'd15,

  4'd0, 4'd5, 4'd10, 4'd15,
  4'd1, 4'd6, 4'd11, 4'd12,
  4'd2, 4'd7, 4'd8, 4'd13,
  4'd3, 4'd4, 4'd9, 4'd14
};

localparam [0:4*16*12-1] SIGMA = {
  4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11, 4'd12, 4'd13, 4'd14, 4'd15,
  4'd14, 4'd10, 4'd4, 4'd8, 4'd9, 4'd15, 4'd13, 4'd6, 4'd1, 4'd12, 4'd0, 4'd2, 4'd11, 4'd7, 4'd5, 4'd3,
  4'd11, 4'd8, 4'd12, 4'd0, 4'd5, 4'd2, 4'd15, 4'd13, 4'd10, 4'd14, 4'd3, 4'd6, 4'd7, 4'd1, 4'd9, 4'd4,
  4'd7, 4'd9, 4'd3, 4'd1, 4'd13, 4'd12, 4'd11, 4'd14, 4'd2, 4'd6, 4'd5, 4'd10, 4'd4, 4'd0, 4'd15, 4'd8,
  4'd9, 4'd0, 4'd5, 4'd7, 4'd2, 4'd4, 4'd10, 4'd15, 4'd14, 4'd1, 4'd11, 4'd12, 4'd6, 4'd8, 4'd3, 4'd13,
  4'd2, 4'd12, 4'd6, 4'd10, 4'd0, 4'd11, 4'd8, 4'd3, 4'd4, 4'd13, 4'd7, 4'd5, 4'd15, 4'd14, 4'd1, 4'd9,
  4'd12, 4'd5, 4'd1, 4'd15, 4'd14, 4'd13, 4'd4, 4'd10, 4'd0, 4'd7, 4'd6, 4'd3, 4'd9, 4'd2, 4'd8, 4'd11,
  4'd13, 4'd11, 4'd7, 4'd14, 4'd12, 4'd1, 4'd3, 4'd9, 4'd5, 4'd0, 4'd15, 4'd4, 4'd8, 4'd6, 4'd2, 4'd10,
  4'd6, 4'd15, 4'd14, 4'd9, 4'd11, 4'd3, 4'd0, 4'd8, 4'd12, 4'd2, 4'd13, 4'd7, 4'd1, 4'd4, 4'd10, 4'd5,
  4'd10, 4'd2, 4'd8, 4'd4, 4'd7, 4'd6, 4'd1, 4'd5, 4'd15, 4'd11, 4'd9, 4'd14, 4'd3, 4'd12, 4'd13, 4'd0,
  4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11, 4'd12, 4'd13, 4'd14, 4'd15,
  4'd14, 4'd10, 4'd4, 4'd8, 4'd9, 4'd15, 4'd13, 4'd6, 4'd1, 4'd12, 4'd0, 4'd2, 4'd11, 4'd7, 4'd5, 4'd3
};

reg [1023:0] chunk;
reg [63:0] h [0:7];
reg [64*16-1:0] v;

wire [64*16-1:0] v_con [0:12*8];

reg [7:0] tmp;

mix mix_r0_0(.clk(clk), .v(v), .a(4'd0), .b(4'd4), .c(4'd8), .d(4'd12), .x(chunk[0*64 +: 64]), .y(chunk[1*64 +: 64]), .v_out(v_con[1]));

generate
  genvar i;
  for(i = 1; i < 12*8; i = i + 1)
  begin: generate_mix_rounds
    mix mix_rround_i(
      .clk(clk),
      .v(v_con[i]),
      .a(v_index[ ((i*16) + 0)%128+:4 ]),
      .b(v_index[ ((i*16) + 4)%128+:4 ]),
      .c(v_index[ ((i*16) + 8)%128+:4 ]),
      .d(v_index[ ((i*16) + 12)%128+:4 ]),
      .x(chunk[ SIGMA[ i*8 +: 4 ]*64 +: 64]),
      .y(chunk[ SIGMA[ i*8+4 +: 4 ]*64 +: 64]),
      .v_out(v_con[i+1])
    );
  end
endgenerate

always @(posedge clk)
  begin
    chunk = (header & 640'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | (nonce << 320);
    //$display("Starting with chunk=0x%x\n", chunk);
  	// h[0] has already been XORed with 0x0101kknn, kk=0, nn=0x20 (dec 32)
    // 6A09E667F3BCC908
  	h[0] = 64'h6a09e667f2bdc928;
  	h[1] = 64'hbb67ae8584caa73b;
  	h[2] = 64'h3c6ef372fe94f82b;
  	h[3] = 64'ha54ff53a5f1d36f1;
  	h[4] = 64'h510e527fade682d1;
  	h[5] = 64'h9b05688c2b3e6c1f;
  	h[6] = 64'h1f83d9abfb41bd6b;
  	h[7] = 64'h5be0cd19137e2179;

    v[0*64+:64] = h[0];
  	v[1*64+:64] = h[1];
  	v[2*64+:64] = h[2];
  	v[3*64+:64] = h[3];
  	v[4*64+:64] = h[4];
  	v[5*64+:64] = h[5];
  	v[6*64+:64] = h[6];
  	v[7*64+:64] = h[7];
  	v[8*64+:64] = 64'h6a09e667f3bcc908;
  	v[9*64+:64] = 64'hbb67ae8584caa73b;
  	v[10*64+:64] = 64'h3c6ef372fe94f82b;
  	v[11*64+:64] = 64'ha54ff53a5f1d36f1;
    // supposed to be v[12] xored with 0x50 (decimal 80)
    // but reference implementation xored IV[4] with 0x03 so..
  	v[12*64+:64] = 64'h510e527fade682d2;
  	v[13*64+:64] = 64'h9b05688c2b3e6c1f;
  	// v[14] inverted already because siacoin only has a 80 byte message so this is the last block
  	v[14*64+:64] = 64'he07c265404be4294;
  	v[15*64+:64] = 64'h5be0cd19137e2179;

    h[0] = h[0] ^ v_con[96][0*64 +: 64] ^ v_con[96][8*64 +: 64];
    h[1] = h[1] ^ v_con[96][1*64 +: 64] ^ v_con[96][9*64 +: 64];
    h[2] = h[2] ^ v_con[96][2*64 +: 64] ^ v_con[96][10*64 +: 64];
    h[3] = h[3] ^ v_con[96][3*64 +: 64] ^ v_con[96][11*64 +: 64];
    h[4] = h[4] ^ v_con[96][4*64 +: 64] ^ v_con[96][12*64 +: 64];
    h[5] = h[5] ^ v_con[96][5*64 +: 64] ^ v_con[96][13*64 +: 64];
    h[6] = h[6] ^ v_con[96][6*64 +: 64] ^ v_con[96][14*64 +: 64];
    h[7] = h[7] ^ v_con[96][7*64 +: 64] ^ v_con[96][15*64 +: 64];
    
    hash <= {
      h[0][0+:8], h[0][8+:8], h[0][16+:8], h[0][24+:8], h[0][32+:8], h[0][40+:8], h[0][48+:8], h[0][56+:8],
      h[1][0+:8], h[1][8+:8], h[1][16+:8], h[1][24+:8], h[1][32+:8], h[1][40+:8], h[1][48+:8], h[1][56+:8],
      h[2][0+:8], h[2][8+:8], h[2][16+:8], h[2][24+:8], h[2][32+:8], h[2][40+:8], h[2][48+:8], h[2][56+:8],
      h[3][0+:8], h[3][8+:8], h[3][16+:8], h[3][24+:8], h[3][32+:8], h[3][40+:8], h[3][48+:8], h[3][56+:8]
    };
    /*for(tmp = 1; tmp < 97; tmp = tmp + 1)
      begin
        $display("%x", v_con[tmp]);
      end*/
  end

endmodule
