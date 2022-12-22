//
//  ClockCycleTests.metal
//
//
//  Created by Philip Turner on 10/24/22.
//

#include <metal_stdlib>
using namespace metal;

typedef uint FLOAT;
typedef short ALT_FLOAT;
#define FLOAT2 vec<ALT_FLOAT, 4>

// actual cycles = (result - 1200) / 4000
// calibrate M1 Max (32c) = 1_000_000 dispatches
// calibrate A15 (5c) = 1_000_000 / 6 dispatches

vec<FLOAT, 2> mulfloat(vec<FLOAT, 2> x, vec<FLOAT, 2> y) {
  return x * y;
}

vec<FLOAT, 2> madfloat(vec<FLOAT, 2> x, vec<FLOAT, 2> y, vec<FLOAT, 2> z) {
  return x * y + z;
}

vec<ALT_FLOAT, 2> mulint(vec<ALT_FLOAT, 2> x, vec<ALT_FLOAT, 2> y) {
  return x * y;
}

vec<ALT_FLOAT, 2> madint(vec<ALT_FLOAT, 2> x, vec<ALT_FLOAT, 2> y, vec<ALT_FLOAT, 2> z) {
  return x * y + z;
}

//

template <typename V>
V mul32x32_64(V x, V y) {
  auto hi_part = mulhi(x, y);
  auto lo_part = x * y;
  return hi_part + lo_part;
}

// Reduce 128 bits of information into 64 bits, using two 32-bit adds.
ulong combine(ulong hi, ulong lo) {
  uint out_lo = as_type<uint2>(hi)[0] + as_type<uint2>(lo)[1];
  uint out_hi = as_type<uint2>(hi)[0] + as_type<uint2>(lo)[1];
  return as_type<ulong>(uint2(out_lo, out_hi));
}

ulong2 mul64x64_128(ulong2 x, ulong2 y) {
  ulong hi_part_0 = mulhi(x[0], y[0]);
  ulong hi_part_1 = mulhi(x[1], y[1]);
  ulong lo_part_0 = x[0] * y[0];
  ulong lo_part_1 = x[1] * y[1];
  
  // Avoid triggering a madhi
  ulong part_0 = combine(hi_part_0, lo_part_0);
  ulong part_1 = combine(hi_part_1, lo_part_1);
  return {part_0, part_1};
}

ulong2 mad64x64_128(ulong2 x, ulong2 y, ulong2 z) {
  ulong hi_part_0 = madhi(x[0], y[0], z[0]);
  ulong hi_part_1 = madhi(x[1], y[1], z[1]);
  ulong lo_part_0 = x[0] * y[0] + z[0];
  ulong lo_part_1 = x[1] * y[1] + z[1];
  
  // Avoid triggering a madhi
  ulong part_0 = combine(hi_part_0, lo_part_0);
  ulong part_1 = combine(hi_part_1, lo_part_1);
  return {part_0, part_1};
}

template <typename V>
V mad32x32_64(V x, V y, V z) {
  auto hi_part = madhi(x, y, z);
//  auto lo_x = mad24(int(x[0]), int(y[0]), int(z[0]));
//  auto lo_y = mad24(int(x[1]), int(y[1]), int(z[1]));
  auto lo_x = x[0] * y[0] + z[0];
  auto lo_y = x[1] * y[1] + z[1];
//  auto lo_x = ushort(x[0]) * ushort(y[0]) + ushort(z[0]);
//  auto lo_y = ushort(x[1]) * ushort(y[1]) + ushort(z[1]);
  return hi_part + V(lo_x, lo_y);
}

kernel void testALU(device int *in_place_buffer [[buffer(0)]],
                    uint tid [[thread_position_in_grid]])
{
    ulong this_val = ((device ulong*)in_place_buffer)[tid];
    vec<FLOAT, 4> read_value((thread FLOAT&)this_val);
    read_value[1] += 1;
    read_value[2] += read_value[0];
    read_value[3] += read_value[0] * read_value[0];
    
    vec<FLOAT, 4> read_value2 = read_value * read_value;
    vec<FLOAT, 4> read_value3 = read_value * read_value2;
//  FLOAT2 read_value11 = FLOAT2(1 + read_value);
//  FLOAT2 read_value21 = FLOAT2(1 + read_value2);
//  FLOAT2 read_value31 = FLOAT2(1 + read_value3);
    
//#define OP *
//
//#define BLOCK \
//read_value.xy = read_value2.xy OP (read_value3.xy); \
//read_value.zw = read_value2.zw OP (read_value3.zw); \
//read_value2.xy = read_value3.xy OP (read_value.xy); \
//read_value2.zw = read_value3.zw OP (read_value.zw); \
//read_value3.xy = read_value.xy OP (read_value2.xy); \
//read_value3.zw = read_value.zw OP (read_value2.zw); \
//read_value11.xy = read_value21.xy OP (read_value31.xy); \
//read_value11.zw = read_value21.zw OP (read_value31.zw); \
//read_value21.xy = read_value31.xy OP (read_value11.xy); \
//read_value21.zw = read_value31.zw OP (read_value11.zw); \
//read_value31.xy = read_value11.xy OP (read_value21.xy); \
//read_value31.zw = read_value11.zw OP (read_value21.zw); \

//#define BLOCK \
//read_value.xy = read_value.xy OP (read_value.xy); \
//read_value.zw = read_value.zw OP (read_value.zw); \
//read_value2.xy = read_value2.xy OP (read_value2.xy); \
//read_value2.zw = read_value2.zw OP (read_value2.zw); \
//read_value3.xy = read_value3.xy OP (read_value3.xy); \
//read_value3.zw = read_value3.zw OP (read_value3.zw); \
//read_value11.xy = read_value11.xy OP (read_value11.xy); \
//read_value11.zw = read_value11.zw OP (read_value11.zw); \
//read_value21.xy = read_value21.xy OP (read_value21.xy); \
//read_value21.zw = read_value21.zw OP (read_value21.zw); \
//read_value31.xy = read_value31.xy OP (read_value31.xy); \
//read_value31.zw = read_value31.zw OP (read_value31.zw); \

//#define OP1 mul64x64_128
//#define OP2 mulint
//
//#define BLOCK \
//read_value.xy = OP1(read_value2.xy, read_value3.xy); \
//read_value.zw = OP1(read_value2.zw, read_value3.zw); \
//read_value2.xy = OP1(read_value3.xy, read_value.xy); \
//read_value2.zw = OP1(read_value3.zw, read_value.zw); \
//read_value3.xy = OP1(read_value.xy, read_value2.xy); \
//read_value3.zw = OP1(read_value.zw, read_value2.zw); \
//read_value11.xy = OP2(read_value21.xy, read_value31.xy); \
//read_value11.zw = OP2(read_value21.zw, read_value31.zw); \
//read_value21.xy = OP2(read_value31.xy, read_value11.xy); \
//read_value21.zw = OP2(read_value31.zw, read_value11.zw); \
//read_value31.xy = OP2(read_value11.xy, read_value21.xy); \
//read_value31.zw = OP2(read_value11.zw, read_value21.zw); \
  
//#define BLOCK \
//read_value.xy = OP1(read_value.xy, read_value.xy); \
//read_value.zw = OP1(read_value.zw, read_value.zw); \
//read_value2.xy = OP1(read_value2.xy, read_value2.xy); \
//read_value2.zw = OP1(read_value2.zw, read_value2.zw); \
//read_value3.xy = OP1(read_value3.xy, read_value3.xy); \
//read_value3.zw = OP1(read_value3.zw, read_value3.zw); \
//read_value11.xy = OP2(read_value11.xy, read_value11.xy); \
//read_value11.zw = OP2(read_value11.zw, read_value11.zw); \
//read_value21.xy = OP2(read_value21.xy, read_value21.xy); \
//read_value21.zw = OP2(read_value21.zw, read_value21.zw); \
//read_value31.xy = OP2(read_value31.xy, read_value31.xy); \
//read_value31.zw = OP2(read_value31.zw, read_value31.zw); \


#define OP1 mad32x32_64
//#define OP2 madint

//#define BLOCK \
//read_value.xy = OP1(read_value2.xy, read_value3.xy, read_value.xy); \
//read_value.zw = OP1(read_value2.zw, read_value3.zw, read_value.zw); \
//read_value2.xy = OP1(read_value3.xy, read_value.xy, read_value2.xy); \
//read_value2.zw = OP1(read_value3.zw, read_value.zw, read_value2.zw); \
//read_value3.xy = OP1(read_value.xy, read_value2.xy, read_value3.xy); \
//read_value3.zw = OP1(read_value.zw, read_value2.zw, read_value3.zw); \
//read_value11.xy = OP2(read_value21.xy, read_value31.xy, read_value11.xy); \
//read_value11.zw = OP2(read_value21.zw, read_value31.zw, read_value11.zw); \
//read_value21.xy = OP2(read_value31.xy, read_value11.xy, read_value21.xy); \
//read_value21.zw = OP2(read_value31.zw, read_value11.zw, read_value21.zw); \
//read_value31.xy = OP2(read_value11.xy, read_value21.xy, read_value31.xy); \
//read_value31.zw = OP2(read_value11.zw, read_value21.zw, read_value31.zw); \
  
#define BLOCK \
read_value.xy = OP1(read_value.xy, read_value.xy, read_value.xy); \
read_value.zw = OP1(read_value.zw, read_value.zw, read_value.zw); \
read_value2.xy = OP1(read_value2.xy, read_value2.xy, read_value2.xy); \
read_value2.zw = OP1(read_value2.zw, read_value2.zw, read_value2.zw); \
read_value3.xy = OP1(read_value3.xy, read_value3.xy, read_value3.xy); \
read_value3.zw = OP1(read_value3.zw, read_value3.zw, read_value3.zw); \
//read_value11.xy = OP2(read_value11.xy, read_value11.xy, read_value11.xy); \
//read_value11.zw = OP2(read_value11.zw, read_value11.zw, read_value11.zw); \
//read_value21.xy = OP2(read_value21.xy, read_value21.xy, read_value21.xy); \
//read_value21.zw = OP2(read_value21.zw, read_value21.zw, read_value21.zw); \
//read_value31.xy = OP2(read_value31.xy, read_value31.xy, read_value31.xy); \
//read_value31.zw = OP2(read_value31.zw, read_value31.zw, read_value31.zw); \

  
#define FIVE_BLOCK \
BLOCK \
BLOCK \
BLOCK \
BLOCK \
BLOCK \

#define FIFTY_BLOCK \
\
    FIVE_BLOCK \
    FIVE_BLOCK \
    FIVE_BLOCK \
    FIVE_BLOCK \
    FIVE_BLOCK \
    \
    FIVE_BLOCK \
    FIVE_BLOCK \
    FIVE_BLOCK \
    FIVE_BLOCK \
    FIVE_BLOCK \

    FIFTY_BLOCK
    FIFTY_BLOCK
//    FIFTY_BLOCK
//    FIFTY_BLOCK
//    FIFTY_BLOCK
//    FIFTY_BLOCK
//    FIFTY_BLOCK
//    FIFTY_BLOCK
    
//    for (short i = 0; i < 10; ++i) {
//        read_value.xy = read_value.xy + read_value.zw; \
//        read_value.zw = read_value.xz + read_value.yw; \
//        read_value2.xy = read_value.xy + read_value2.zw; \
//        read_value2.zw = read_value2.xz + read_value.yw; \
//        read_value3.xy = read_value3.xy + read_value2.zw; \
//        read_value3.zw = read_value2.xz + read_value3.yw; \

//        read_value.xy = read_value.xy * read_value.zw;
//        read_value.zw = read_value.xz * read_value.yw;
//        read_value2.xy = read_value.xy * read_value2.zw;
//        read_value2.zw = read_value2.xz * read_value.yw;
//        read_value3.xy = read_value3.xy * read_value2.zw;
//        read_value3.zw = read_value2.xz * read_value3.yw;
        
//        read_value.xy = 1.0 / (read_value.zw);
//        read_value.zw = 1.0 / (read_value.xy);
//        read_value2.xy = 1.0 / (read_value2.zw);
//        read_value2.zw = 1.0 / (read_value2.xy);
//        read_value3.xy = 1.0 / (read_value3.zw);
//        read_value3.zw = 1.0 / (read_value3.xy);
        
//        read_value.xy = read_value.xy / read_value.zw;
//        read_value.zw = read_value.xz / read_value.yw;
//        read_value2.xy = read_value.xy / read_value2.zw;
//        read_value2.zw = read_value2.xz / read_value.yw;
//        read_value3.xy = read_value3.xy / read_value2.zw;
//        read_value3.zw = read_value2.xz / read_value3.yw;
//
//        read_value.xy = read_value.xy % read_value.zw;
//        read_value.zw = read_value.xz % read_value.yw;
//        read_value2.xy = read_value.xy % read_value2.zw;
//        read_value2.zw = read_value2.xz % read_value.yw;
//        read_value3.xy = read_value3.xy % read_value2.zw;
//        read_value3.zw = read_value2.xz % read_value3.yw;

//        read_value.xy = mul24(read_value.xy, read_value.zw);
//        read_value.zw = mul24(read_value.xz, read_value.yw);
//        read_value2.xy = mul24(read_value.xy, read_value2.zw);
//        read_value2.zw = mul24(read_value2.xz, read_value.yw);
//        read_value3.xy = mul24(read_value3.xy, read_value2.zw);
//        read_value3.zw = mul24(read_value2.xz, read_value3.yw);
        
//        read_value.xy = fma(read_value.xy, read_value.xy, read_value3.xy);
//        read_value.zw = fma(read_value.zw, read_value.zw, read_value2.zw);
        
//        read_value.xy = fma(read_value.xy, read_value.zw, read_value3.yz);
//        read_value.zw = fma(read_value.xz, read_value.yw, read_value2.wx);
//        read_value2.xy = fma(read_value.xy, read_value2.zw, read_value3.xw);
//        read_value2.zw = fma(read_value2.xz, read_value.yw, read_value.xz);
//        read_value3.xy = fma(read_value3.xy, read_value2.zw, read_value2.zx);
//        read_value3.zw = fma(read_value2.xz, read_value3.yw, read_value.yy);
//    }
    
    FLOAT result = read_value[0] +  read_value[1] +  read_value[2] +  read_value[3]
                + read_value2[0] + read_value2[1] + read_value2[2] + read_value2[3]
  + read_value3[0] + read_value3[1] + read_value3[2] + read_value3[3];
//              + read_value11[0] +  read_value11[1] +  read_value11[2] +  read_value11[3]
//              + read_value21[0] + read_value21[1] + read_value21[2] + read_value21[3]
//              + read_value31[0] + read_value31[1] + read_value31[2] + read_value31[3];
  in_place_buffer[tid] = int(result);// + int(long(result) >> 32);
}
