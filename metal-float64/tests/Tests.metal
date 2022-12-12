//
//  Tests.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include <MetalFloat64/MetalFloat64.h>
using namespace metal;

typedef double_t float_type;

kernel void testFullScreenColor(device float_type *input1 [[buffer(0)]],
                                device float4 *input2 [[buffer(1)]],
                                uint tid [[thread_position_in_grid]])
{
  if (tid == 0) {
    // Erases the color's last component and returns it.
    float4 color = input2[0];
    color = AAPLUserDylib::getFullScreenColor(color);
    input2[0] = color;
  }
}

kernel void testCallStackOverFlow(device uint *flags [[buffer(0)]],
                                  device float4 *input2 [[buffer(1)]],
                                  uint tid [[thread_position_in_grid]])
{
  float4 color = input2[tid];
  color = AAPLUserDylib::attemptCallStackOverflow1(color, flags);
  input2[tid] = color;
}

#pragma mark - Performance Tests

// The benchmarks below use 100_000 threads/30 trials on the M1 Max. This seems
// to starve the GPU (~96,000 threads). You can re-run with more threads to find
// the greatest performance (~10% faster).
// - Theoretical maximum speed: 10.4 TFLOPS
// - Fastest speed without a function call: 3.53 tera-ops x 2 adds (1:1.47)
// - Fastest speed with function call, 1-wide scalar: 183 giga-ops (1:56.8)
// - Fastest speed with function call, 2-wide vector: 360 giga-ops (1:28.9)
// - Fastest speed with function call, 4-wide vector: 701 giga-ops (1:14.8)
// - Given proper vectorization, function call overhead will not be the primary
//   bottleneck.

// Do not use int2 or int4 with inlined increment. It appears to invoke compiler
// optimizations.
#define TEST_TYPE int4
//#define TEST_INCREMENT inlined_increment
#define TEST_INCREMENT PerformanceTests::increment

// Note: In function call mode, performance drops when OPS_MULTIPLIER > 16.
// Also, avoid 'BYPASS_OPTIMIZATION', which seems to create more variables to
// pop from the stack. It drops performance by the following amounts:
// - 11% at OPS_MULTIPLIER=1
// - 10% at OPS_MULTIPLIER=2
// -  3% at OPS_MULTIPLIER=4
// - 13% at OPS_MULTIPLIER=8
// - 17% at OPS_MULTIPLIER=16
// - 34% at OPS_MULTIPLIER=32
// - 62% at OPS_MULTIPLIER=64
#define OPS_MULTIPLIER 8
#define BYPASS_OPTIMIZATION 0

// int
// OPS_MULTIPLIER  1 x 32_000 inputs - 128.4 giga-ops
// OPS_MULTIPLIER  2 x 16_000 inputs - 146.4 giga-ops
// OPS_MULTIPLIER  4 x  8_000 inputs - 152.2 giga-ops
// OPS_MULTIPLIER  8 x  4_000 inputs - 159.5 giga-ops
// OPS_MULTIPLIER 16 x  2_000 inputs - 157.5 giga-ops
// OPS_MULTIPLIER 32 x  1_000 inputs - 125.6 giga-ops
// OPS_MULTIPLIER 64 x    500 inputs - 122.5 giga-ops
//   500_000 threads, fastest combo  - 177.4 giga-ops
// 2_000_000 threads, fastest combo  - 182.8 giga-ops

// int2
// OPS_MULTIPLIER  1 x 32_000 inputs - 247.7 giga-ops
// OPS_MULTIPLIER  2 x 16_000 inputs - 281.4 giga-ops
// OPS_MULTIPLIER  4 x  8_000 inputs - 304.7 giga-ops
// OPS_MULTIPLIER  8 x  4_000 inputs - 309.3 giga-ops
// OPS_MULTIPLIER 16 x  2_000 inputs - 300.6 giga-ops
// OPS_MULTIPLIER 32 x  1_000 inputs - 238.8 giga-ops
// OPS_MULTIPLIER 64 x    500 inputs - 249.1 giga-ops
//   500_000 threads, fastest combo  - 349.8 giga-ops
// 2_000_000 threads, fastest combo  - 360.2 giga-ops

// int4
// OPS_MULTIPLIER  1 x 32_000 inputs - 469.3 giga-ops
// OPS_MULTIPLIER  2 x 16_000 inputs - 496.9 giga-ops
// OPS_MULTIPLIER  4 x  8_000 inputs - 576.6 giga-ops
// OPS_MULTIPLIER  8 x  4_000 inputs - 608.1 giga-ops
// OPS_MULTIPLIER 16 x  2_000 inputs - 602.3 giga-ops
// OPS_MULTIPLIER 32 x  1_000 inputs - 445.2 giga-ops
// OPS_MULTIPLIER 64 x    500 inputs - 498.7 giga-ops
//   500_000 threads, fastest combo  - 686.1 giga-ops
// 2_000_000 threads, fastest combo  - 698.4 giga-ops
// 8_000_000 threads, fastest combo  - 701.6 giga-ops


// Functions to sum a vectorized intermediate.

int process_element(int x) {
  return x;
}

int process_element(int2 x) {
  return x[0] + x[1];
}

int process_element(int4 x) {
  return x[0] + x[1] + x[2] + x[3];
}

// Reads from an input buffer, increments, and returns the sum.
// - All threads operate on the exact same data.
// - Acquire 'num_bytes' from RAM to prevent compile-time optimizations.
template <typename T, T modify(T x, int increment_amount)>
int _testFunctionCallOverhead
 (
  device T *input,
  device int *num_bytes,
  device int *increment_amounts)
{
  // Needs a local array to counteract compiler optimizations.
#if BYPASS_OPTIMIZATION
  int _increment_amounts[OPS_MULTIPLIER] = {};
#endif
  
  int count = *num_bytes / sizeof(T);
  int sum = 0;
  for (int i = 0; i < count; ++i)
  {
#if BYPASS_OPTIMIZATION
    if ((i >> 10) == 0) {
      for (int j = 0; j < OPS_MULTIPLIER; ++j) {
        _increment_amounts[j] = increment_amounts[j];
      }
    }
#endif
    
    T original_element = input[i];
    for (int j = 0; j < OPS_MULTIPLIER; ++j)
    {
      T element = original_element;
#if BYPASS_OPTIMIZATION
      element = modify(element, _increment_amounts[j]);
#else
      element = modify(element, 1);
#endif
      sum += process_element(element);
    }
  }
  return sum;
}

template <typename T>
T inlined_increment(T input, int increment_amount)
{
  return input + increment_amount;
}



kernel void testFunctionCallOverhead
 ( // This parenthesis trick bypasses Xcode's auto-indentation.
  device TEST_TYPE *input [[buffer(0)]],
  device int *output [[buffer(1)]],
  device int *num_bytes [[buffer(2)]],
  device int *increment_amount [[buffer(3)]],
  uint tid [[thread_position_in_grid]])
{
  output[tid] = _testFunctionCallOverhead<TEST_TYPE, TEST_INCREMENT>
   (
    input, num_bytes, increment_amount);
}
