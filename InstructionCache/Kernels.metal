//
//  Kernels.metal
//  BenchInstructionCache
//
//  Created by Philip Turner on 12/24/22.
//

#include <metal_stdlib>
using namespace metal;

// Benchmark instruction cache and register cache.

#define FLOAT float
#define FLOAT4 vec<FLOAT, 4>
#define TWENTY_FOUR_GROUP TWENTY_FOUR_GROUP_MUL7

// MARK: - Multiply Macros

#define TWENTY_FOUR_GROUP_MUL1 \
vec1 = vec1 * vec2; \
vec4 = vec4 * vec5; \
vec2 = vec2 * vec3; \
vec5 = vec5 * vec6; \
vec3 = vec3 * vec1; \
vec6 = vec6 * vec4; \

#define TWENTY_FOUR_GROUP_MUL2 \
vec1 = vec1 * vec2; \
vec2 = vec2 * vec3; \
vec3 = vec3 * vec1; \
vec1 = vec1 * vec2; \
vec2 = vec2 * vec3; \
vec3 = vec3 * vec1; \

#define TWENTY_FOUR_GROUP_MUL3 \
vec1 = vec1 * vec3; \
vec2 = vec2 * vec1; \
vec3 = vec3 * vec2; \
vec1 = vec1 * vec3; \
vec2 = vec2 * vec1; \
vec3 = vec3 * vec2; \

#define TWENTY_FOUR_GROUP_MUL4 \
vec1.xy = vec1.xy * vec3.xy; \
vec2.xy = vec2.xy * vec1.xy; \
vec3.xy = vec3.xy * vec2.xy; \
vec1.xy = vec1.xy * vec3.xy; \
vec2.xy = vec2.xy * vec1.xy; \
vec3.xy = vec3.xy * vec2.xy; \
vec1.xy = vec1.xy * vec3.xy; \
vec2.xy = vec2.xy * vec1.xy; \
vec3.xy = vec3.xy * vec2.xy; \
vec1.xy = vec1.xy * vec3.xy; \
vec2.xy = vec2.xy * vec1.xy; \
vec3.xy = vec3.xy * vec2.xy; \

#define TWENTY_FOUR_GROUP_MUL5 \
vec1.xy = vec1.xy * vec4.xy; \
vec2.xy = vec2.xy * vec1.xy; \
vec3.xy = vec3.xy * vec2.xy; \
vec4.xy = vec4.xy * vec3.xy; \
vec1.xy = vec1.xy * vec4.xy; \
vec2.xy = vec2.xy * vec1.xy; \
vec3.xy = vec3.xy * vec2.xy; \
vec4.xy = vec4.xy * vec3.xy; \
vec1.xy = vec1.xy * vec4.xy; \
vec2.xy = vec2.xy * vec1.xy; \
vec3.xy = vec3.xy * vec2.xy; \
vec4.xy = vec4.xy * vec3.xy; \

#define TWENTY_FOUR_GROUP_MUL6 \
vec1.xyz = vec1.xyz * vec4.xyz; \
vec2.xyz = vec2.xyz * vec1.xyz; \
vec3.xyz = vec3.xyz * vec2.xyz; \
vec4.xyz = vec4.xyz * vec3.xyz; \
vec1.xyz = vec1.xyz * vec4.xyz; \
vec2.xyz = vec2.xyz * vec1.xyz; \
vec3.xyz = vec3.xyz * vec2.xyz; \
vec4.xyz = vec4.xyz * vec3.xyz; \

#define TWENTY_FOUR_GROUP_MUL7 \
vec1.xyz = vec1.xyz * vec2.xyz; \
vec2.xyz = vec2.xyz * vec1.xyz; \
vec1.xyz = vec1.xyz * vec2.xyz; \
vec2.xyz = vec2.xyz * vec1.xyz; \
vec1.xyz = vec1.xyz * vec2.xyz; \
vec2.xyz = vec2.xyz * vec1.xyz; \
vec1.xyz = vec1.xyz * vec2.xyz; \
vec2.xyz = vec2.xyz * vec1.xyz; \

//#define TWENTY_FOUR_GROUP_MUL3 \
//vec1 = vec1 * vec1; \
//vec2 = vec2 * vec2; \
//vec3 = vec3 * vec3; \
//
//#define TWENTY_FOUR_GROUP_MUL4 \
//vec1 = vec1 * vec1; \
//vec1 = vec1 * vec1; \
//vec1 = vec1 * vec1; \
//
//#define TWENTY_FOUR_GROUP_MUL5 \
//vec1.xy = vec1.xy * vec1.xy; \
//vec1.xy = vec1.xy * vec1.xy; \
//vec1.xy = vec1.xy * vec1.xy; \
//vec1.xy = vec1.xy * vec1.xy; \
//vec1.xy = vec1.xy * vec1.xy; \
//vec1.xy = vec1.xy * vec1.xy; \
//
//#define TWENTY_FOUR_GROUP_MUL6 \
//vec1.xy = vec1.xy * vec1.xy; \
//vec2.xy = vec2.xy * vec2.xy; \
//vec3.xy = vec3.xy * vec3.xy; \
//vec1.xy = vec1.xy * vec1.xy; \
//vec2.xy = vec2.xy * vec2.xy; \
//vec3.xy = vec3.xy * vec3.xy; \
//
//#define TWENTY_FOUR_GROUP_MUL7 \
//vec1.xy = vec1.xy * vec1.xy; \
//vec2.xy = vec2.xy * vec2.xy; \
//vec3.xy = vec3.xy * vec3.xy; \
//vec1.zw = vec1.zw * vec1.zw; \
//vec2.zw = vec2.zw * vec2.zw; \
//vec3.zw = vec3.zw * vec3.zw; \
//
//#define TWENTY_FOUR_GROUP_MUL8 \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \
//vec1.x = vec1.x * vec1.x; \


// MARK: - FMA Macros

#define TWENTY_FOUR_GROUP_FMA0 \
vec1 = fma(vec1, vec2, vec3); \
vec4 = fma(vec4, vec5, vec6); \
vec2 = fma(vec1, vec2, vec3); \
vec5 = fma(vec4, vec5, vec6); \
vec3 = fma(vec1, vec2, vec3); \
vec6 = fma(vec4, vec5, vec6); \

#define TWENTY_FOUR_GROUP_FMA1 \
vec1 = fma(vec1, vec2, vec3); \
vec2 = fma(vec1, vec2, vec3); \
vec3 = fma(vec1, vec2, vec3); \
vec4 = fma(vec4, vec5, vec6); \
vec5 = fma(vec4, vec5, vec6); \
vec6 = fma(vec4, vec5, vec6); \

#define TWENTY_FOUR_GROUP_FMA2 \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec4.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec5.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec6.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec4.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec5.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec6.xy = fma(vec4.xy, vec5.xy, vec6.xy); \

#define TWENTY_FOUR_GROUP_FMA3 \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec4.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec5.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec6.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec4.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec5.xy = fma(vec4.xy, vec5.xy, vec6.xy); \
vec6.xy = fma(vec4.xy, vec5.xy, vec6.xy); \

#define TWENTY_FOUR_GROUP_FMA4 \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \

#define TWENTY_FOUR_GROUP_FMA5 \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.zw = fma(vec1.zw, vec2.zw, vec3.zw); \

#define TWENTY_FOUR_GROUP_FMA6 \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.zw = fma(vec1.zw, vec2.zw, vec3.zw); \

#define TWENTY_FOUR_GROUP_FMA7 \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec1.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec1.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec2.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec2.zw = fma(vec1.zw, vec2.zw, vec3.zw); \
vec3.xy = fma(vec1.xy, vec2.xy, vec3.xy); \
vec3.zw = fma(vec1.zw, vec2.zw, vec3.zw); \

//#define TWENTY_FOUR_GROUP_FMA5 \
//vec1.xy = fma(vec1.xy, vec1.xy, vec1.xy); \
//vec2.xy = fma(vec2.xy, vec2.xy, vec2.xy); \
//vec3.xy = fma(vec3.xy, vec3.xy, vec3.xy); \
//vec1.xy = fma(vec1.xy, vec1.xy, vec1.xy); \
//vec2.xy = fma(vec2.xy, vec2.xy, vec2.xy); \
//vec3.xy = fma(vec3.xy, vec3.xy, vec3.xy); \
//
//#define TWENTY_FOUR_GROUP_FMA6 \
//vec1.xy = fma(vec1.xy, vec1.xy, vec1.xy); \
//vec2.xy = fma(vec2.xy, vec2.xy, vec2.xy); \
//vec3.xy = fma(vec3.xy, vec3.xy, vec3.xy); \
//vec1.zw = fma(vec1.zw, vec1.zw, vec1.zw); \
//vec2.zw = fma(vec2.zw, vec2.zw, vec2.zw); \
//vec3.zw = fma(vec3.zw, vec3.zw, vec3.zw); \
//
//#define TWENTY_FOUR_GROUP_FMA7 \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \
//vec1.x = fma(vec1.x, vec1.x, vec1.x); \

// MARK: - Shader Function

#define ONE_TWENTY_GROUP \
TWENTY_FOUR_GROUP \
TWENTY_FOUR_GROUP \
TWENTY_FOUR_GROUP \
TWENTY_FOUR_GROUP \
TWENTY_FOUR_GROUP \

#define SEVEN_TWENTY_GROUP \
ONE_TWENTY_GROUP \
ONE_TWENTY_GROUP \
ONE_TWENTY_GROUP \
ONE_TWENTY_GROUP \
ONE_TWENTY_GROUP \
ONE_TWENTY_GROUP \

#define TWO_EIGHT_EIGHTY_GROUP \
SEVEN_TWENTY_GROUP \
SEVEN_TWENTY_GROUP \
SEVEN_TWENTY_GROUP \
SEVEN_TWENTY_GROUP \

kernel void testCache(device FLOAT4 *inputs [[buffer(0)]],
                      device FLOAT4 *outputs [[buffer(1)]],
                      constant ushort &max_simds [[buffer(2)]],
                      ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  threadgroup_barrier(mem_flags::mem_none);
  FLOAT4 vec1 = inputs[0];
  FLOAT4 vec2 = inputs[1];
  FLOAT4 vec3 = inputs[2];
  FLOAT4 vec4 = inputs[3];
  FLOAT4 vec5 = inputs[4];
  FLOAT4 vec6 = inputs[5];
  
  if (simd_index < max_simds) {
//    ONE_TWENTY_GROUP
//    ONE_TWENTY_GROUP
//    ONE_TWENTY_GROUP
//    ONE_TWENTY_GROUP
//    ONE_TWENTY_GROUP
//    ONE_TWENTY_GROUP
    
//    TWENTY_FOUR_GROUP
//    TWENTY_FOUR_GROUP
//    TWENTY_FOUR_GROUP
//    TWENTY_FOUR_GROUP
//    TWENTY_FOUR_GROUP

    SEVEN_TWENTY_GROUP
    SEVEN_TWENTY_GROUP
//    SEVEN_TWENTY_GROUP
//    SEVEN_TWENTY_GROUP

//    TWO_EIGHT_EIGHTY_GROUP
//    TWO_EIGHT_EIGHTY_GROUP
  }
  
  outputs[simd_index + 0] = vec1;
  outputs[simd_index + 1] = vec2;
  outputs[simd_index + 2] = vec3;
  outputs[simd_index + 3] = vec4;
  outputs[simd_index + 4] = vec5;
  outputs[simd_index + 5] = vec6;
  threadgroup_barrier(mem_flags::mem_none);
}