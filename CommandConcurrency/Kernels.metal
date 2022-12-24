//
//  Kernels.metal
//  TestMetalConcurrency
//
//  Created by Philip Turner on 12/22/22.
//

#include <metal_stdlib>
using namespace metal;

// Start with the same shader function, but different constants. Buffers are
// bound at different offsets. Then, make completely different shader functions.

constant int numIterations [[function_constant(0)]];
constant int transformIndex [[function_constant(1)]];

#define CHOSEN_SIMD 0
#define constant device

#define LOOP_BODY \
if (simd_index == CHOSEN_SIMD) { \
  for (int i = 0; i < numIterations/2; ++i) { \
    value = transform0 * value; \
  } \
  for (int i = numIterations/2; i < numIterations; ++i) { \
    value = transform1 * value; \
  } \
} \

// Number of floating point operations:
//   numIterations * 2 * 64
// You may need numerous iterations to cancel out the memory bandwidth cost of
// reading/writing 16 floats to memory.
kernel void testThroughput1(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[0] += 1 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput2(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[0].xy += 1 + tg_mem[transformIndex];
  transform1[0].zw += 1 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput3(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[0] += 1 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  
}

kernel void testThroughput4(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[1] += 2 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput5(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[1].xy += 2 + tg_mem[transformIndex];
  transform1[1].zw += 2 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput6(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[1] += 2 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput7(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[2] += 3 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput8(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[2].xy += 3 + tg_mem[transformIndex];
  transform1[2].zw += 3 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput9(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            threadgroup float *tg_mem [[threadgroup(0)]],
                            uint tid [[thread_position_in_grid]],
                            ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[2] += 3 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput10(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[3] += 4 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput11(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[3].xy += 4 + tg_mem[transformIndex];
  transform1[3].zw += 4 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput12(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[3] += 4 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput13(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[0] += 5 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput14(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[0].xy += 5 + tg_mem[transformIndex];
  transform1[0].zw += 5 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput15(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[0] += 5 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput16(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[1] += 6 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput17(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[1].xy += 6 + tg_mem[transformIndex];
  transform1[1].zw += 6 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput18(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[1] += 6 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput19(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[2] += 7 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput20(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[2].xy += 7 + tg_mem[transformIndex];
  transform1[2].zw += 7 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput21(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[2] += 7 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput22(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[3] += 8 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput23(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[3].xy += 8 + tg_mem[transformIndex];
  transform1[3].zw += 8 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput24(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[3] += 8 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput25(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[0] += 9 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput26(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[0].xy += 9 + tg_mem[transformIndex];
  transform1[0].zw += 9 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput27(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[0] += 9 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput28(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[1] += 10 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput29(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[1].xy += 10 + tg_mem[transformIndex];
  transform1[1].zw += 10 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput30(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[1] += 10 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput31(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[2] += 11 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput32(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[2].xy += 11 + tg_mem[transformIndex];
  transform1[2].zw += 11 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput33(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[2] += 11 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput34(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  value[3] += 12 + tg_mem[transformIndex];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput35(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  transform0[3].xy += 12 + tg_mem[transformIndex];
  transform1[3].zw += 12 + tg_mem[transformIndex];
  
  LOOP_BODY;
  
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}

kernel void testThroughput36(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             threadgroup float *tg_mem [[threadgroup(0)]],
                             uint tid [[thread_position_in_grid]],
                             ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform0 = transformMatrices[transformIndex];
  float4x4 transform1 = transformMatrices[transformIndex + 1];
  
  LOOP_BODY;
  
  value[3] += 12 + tg_mem[transformIndex];
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
  outputMatrices[tid] = value;
  threadgroup_barrier(mem_flags::mem_threadgroup | mem_flags::mem_device);
}
