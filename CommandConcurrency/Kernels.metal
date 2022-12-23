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

// Number of floating point operations:
//   numIterations * 2 * 64
// You may need numerous iterations to cancel out the memory bandwidth cost of
// reading/writing 16 floats to memory.
kernel void testThroughput1(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  value[0] += 1;
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput2(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  transform[0] += 1;
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput3(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  value[0] += 1;
  outputMatrices[tid] = value;
  
}

kernel void testThroughput4(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  value[1] += 2;
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput5(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  transform[1] += 2;
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput6(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  value[1] += 2;
  outputMatrices[tid] = value;
}

kernel void testThroughput7(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  value[2] += 3;
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput8(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  transform[2] += 3;
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput9(device float4x4 *inputMatrices [[buffer(0)]],
                            constant float4x4 *transformMatrices [[buffer(1)]],
                            device float4x4 *outputMatrices [[buffer(2)]],
                            uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  value[2] += 3;
  outputMatrices[tid] = value;
}

kernel void testThroughput10(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  value[3] += 4;
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput11(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  transform[3] += 4;
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput12(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  value[3] += 4;
  outputMatrices[tid] = value;
}

kernel void testThroughput13(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  value[0] += 5;
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput14(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  transform[0] += 5;
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}

kernel void testThroughput15(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  value[0] += 5;
  outputMatrices[tid] = value;
}

kernel void testThroughput16(device float4x4 *inputMatrices [[buffer(0)]],
                             constant float4x4 *transformMatrices [[buffer(1)]],
                             device float4x4 *outputMatrices [[buffer(2)]],
                             uint tid [[thread_position_in_grid]])
{
  float4x4 value = inputMatrices[tid];
  value[1] += 6;
  float4x4 transform = transformMatrices[transformIndex];
  for (int i = 0; i < numIterations; ++i) {
    value = transform * value;
  }
  outputMatrices[tid] = value;
}
