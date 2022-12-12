//
//  Double.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include <MetalFloat64/MetalFloat64.h>
using namespace metal;

typedef double_t my_double_t;

NOINLINE float4 AAPLUserDylib::getFullScreenColor(float4 inColor)
{
  int x = 2;
#pragma clang loop unroll(full)
  for (int i = 0; i < 4; ++i) {
    x += 1;
  }
  
  return float4(inColor.r, inColor.g, inColor.b, 0);
}

NOINLINE float4 AAPLUserDylib::attemptCallStackOverflow1(float4 input, device uint *flags)
{
  return AAPLUserDylib::attemptCallStackOverflow2(input, flags, 0);
}

NOINLINE float4 AAPLUserDylib::attemptCallStackOverflow2(float4 input, device uint *flags, int counter)
{
  switch (flags[counter]) {
    case 0:
      return input * input;
    case 1:
      return attemptCallStackOverflow2(input, flags, counter + 1);
    default:
      return attemptCallStackOverflow3(input, flags, counter + 1);
  }
}

NOINLINE float4 AAPLUserDylib::attemptCallStackOverflow3(float4 input, device uint *flags, int counter)
{
  switch (flags[counter]) {
    case 0:
      return input + input;
    case 3:
      return attemptCallStackOverflow2(input, flags, counter + 1);
    default:
      return attemptCallStackOverflow3(input, flags, counter + 1);
  }
}

// MARK: - Performance Tests

NOINLINE int PerformanceTests::increment(int x, int increment_amount)
{
  return x + increment_amount;
}

NOINLINE int2 PerformanceTests::increment(int2 x, int increment_amount)
{
  return x + increment_amount;
}

NOINLINE int4 PerformanceTests::increment(int4 x, int increment_amount)
{
  return x + increment_amount;
}
