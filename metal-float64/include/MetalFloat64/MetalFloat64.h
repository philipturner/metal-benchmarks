//
//  MetalFloat64.h
//  
//
//  Created by Philip Turner on 11/22/22.
//

#ifndef MetalFloat64_h
#define MetalFloat64_h

// Single-file header for the MetalFloat64 library.

#include <metal_stdlib>
using namespace metal;

// Apply this to exported symbols.
// Place at the function declaration.
#define EXPORT __attribute__((__visibility__("default")))

// Apply this to functions that shouldn't be inlined internally.
// Place at the function definition.
#define NOINLINE __attribute__((__noinline__))

// Apply this to force-inline functions internally.
// The Metal Standard Library uses it, so it should work reliably.
#define ALWAYS_INLINE __attribute__((__always_inline__))

class double_t {
  ulong data;
};

// TODO: Move everything below this statement into an archive repository,
// alongside cycle counters for MoltenCL.

namespace AAPLUserDylib
{
  // Dummy function, just to test that dynamic linking works.
  EXPORT float4 getFullScreenColor(float4 inColor);
  EXPORT float4 attemptCallStackOverflow1(float4 input, device uint *flags);
  EXPORT float4 attemptCallStackOverflow2(float4 input, device uint *flags, int counter);
  EXPORT float4 attemptCallStackOverflow3(float4 input, device uint *flags, int counter);
}

// Measure the overhead of function calls in real-world scenarios.
// - Tests whether vectorization reduces overhead.
// - TODO: Does increasing number of occupied registers increase overhead?
namespace PerformanceTests
{
  EXPORT int increment(int x, int increment_amount);
  EXPORT int2 increment(int2 x, int increment_amount);
  EXPORT int4 increment(int4 x, int increment_amount);
}

#endif /* MetalFloat64_h */
