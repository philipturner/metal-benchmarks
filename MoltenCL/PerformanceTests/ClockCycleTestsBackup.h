//
//  ClockCycleTests.metal
//
//
//  Created by Philip Turner on 10/24/22.
//

#include <metal_stdlib>
using namespace metal;

typedef uint FLOAT;

// actual cycles = (result - 1200) / 4000
// calibrate M1 Max (32c) = 1_000_000 dispatches
// calibrate A15 (5c) = 1_000_000 / 6 dispatches

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
//    half4 read_value11 = half4(read_value);
//    half4 read_value21 = half4(read_value2);
//    half4 read_value31 = half4(read_value3);
    
//#define BLOCK \
//read_value.xy = read_value.xy * (read_value.zw); \
//read_value.zw = read_value.xz * (read_value.yw); \
//read_value2.xy = read_value.xy * (read_value2.zw); \
//read_value2.zw = read_value2.xz * (read_value.yw); \
//read_value3.xy = read_value3.xy * (read_value2.zw); \
//read_value3.zw = read_value2.xz * (read_value3.yw); \

#define BLOCK \
read_value.xy = read_value2.xy * (read_value3.xy); \
read_value.zw = read_value2.zw * (read_value3.zw); \
read_value2.xy = read_value3.xy * (read_value.xy); \
read_value2.zw = read_value3.zw * (read_value.zw); \
read_value3.xy = read_value.xy * (read_value2.xy); \
read_value3.zw = read_value.zw * (read_value2.zw); \

  
//\
//read_value11.xy = read_value21.xy * (read_value31.xy); \
//read_value11.zw = read_value21.zw * (read_value31.zw); \
//read_value21.xy = read_value31.xy * (read_value11.xy); \
//read_value21.zw = read_value31.zw * (read_value11.zw); \
//read_value31.xy = read_value11.xy * (read_value21.xy); \
//read_value31.zw = read_value11.zw * (read_value21.zw); \

//#define BLOCK \
//read_value.xy = fma(read_value.xy, read_value.zw, read_value3.yz); \
//read_value.zw = fma(read_value.xz, read_value.yw, read_value2.wx); \
//read_value2.xy = fma(read_value.xy, read_value2.zw, read_value3.xw); \
//read_value2.zw = fma(read_value2.xz, read_value.yw, read_value.xz); \
//read_value3.xy = fma(read_value3.xy, read_value2.zw, read_value2.zx); \
//read_value3.zw = fma(read_value2.xz, read_value3.yw, read_value.yy); \
  
//#define BLOCK \
//read_value.xy = fma(read_value.xy, read_value.xy, read_value.xy); \
//read_value.zw = fma(read_value.zw, read_value.zw, read_value.zw); \
//read_value2.xy = fma(read_value2.xy, read_value2.xy, read_value2.xy); \
//read_value2.zw = fma(read_value2.zw, read_value2.zw, read_value2.zw); \
//read_value3.xy = fma(read_value3.xy, read_value3.xy, read_value3.xy); \
//read_value3.zw = fma(read_value3.zw, read_value3.zw, read_value3.zw); \

//#define BLOCK \
//read_value.xy = read_value.xy * read_value.zw + read_value3.yz; \
//read_value.zw = read_value.xz * read_value.yw + read_value2.wx; \
//read_value2.xy = read_value.xy * read_value2.zw + read_value3.xw; \
//read_value2.zw = read_value2.xz * read_value.yw + read_value.xz; \
//read_value3.xy = read_value3.xy * read_value2.zw + read_value2.zx; \
//read_value3.zw = read_value2.xz * read_value3.yw + read_value.yy; \
  
//#define BLOCK \
//read_value.xy = read_value.xy * read_value.xy + read_value.xy; \
//read_value.zw = read_value.zw * read_value.zw + read_value.zw; \
//read_value2.xy = read_value2.xy * read_value2.xy + read_value2.xy; \
//read_value2.zw = read_value2.zw * read_value2.zw + read_value2.zw; \
//read_value3.xy = read_value3.xy * read_value3.xy + read_value3.xy; \
//read_value3.zw = read_value3.zw * read_value3.zw + read_value3.zw; \
  
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
    FIFTY_BLOCK
    FIFTY_BLOCK
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
    in_place_buffer[tid] = int(result);
}
