//
//  Kernels.metal
//  BenchInstructionCache
//
//  Created by Philip Turner on 12/24/22.
//

#include <metal_stdlib>
using namespace metal;

#define FLOAT uint
#define FLOAT4 vec<FLOAT, 4>
#define TWENTY_FOUR_GROUP TWENTY_FOUR_GROUP_MUL16
#define THIRTIETH_SET 0
#define FIFTEENTH_SET 0
#define TENTH_SET 0
#define SIXTH_SET 0
#define THIRD_SET 0
#define HALF_SET 1
#define TWO_THIRD_SET 0
#define FOUR_THIRD_SET 0
#define TWO_SET 0

// ILP 1  = MUL13
// ILP 2  = MUL12
// ILP 3  = MUL16
// ILP 4  = MUL15
// ILP 8  = MUL14
// ILP 16 = MUL11

#define OP(x, y) x + y;
//#define OP(x, y) mul32x32_64_vec4(x, y)

__attribute__((__always_inline__))
uint mul32x32_64_vec1(uint x, uint y) {
  return insert_bits(y, x, 5, 5) + y;
}

__attribute__((__always_inline__))
uint2 mul32x32_64_vec2(uint2 x, uint2 y) {
  uint pt1 = quad_shuffle(y[0], y[0]);
  uint pt2 = quad_shuffle(y[1], y[1]);
  return uint2(pt1, pt2);
}

__attribute__((__always_inline__))
uint4 mul32x32_64_vec4(uint4 x, uint4 y) {
  uint pt1 = quad_shuffle(y[0], 2);
  uint pt2 = quad_shuffle(y[1], 2);
  uint pt3 = quad_shuffle(y[2], 2);
  uint pt4 = quad_shuffle(y[3], 2);
//  uint pt1 = quad_vote::vote_t(quad_ballot(y[0] > x[0]));
//  uint pt2 = quad_vote::vote_t(quad_ballot(y[1] > x[1]));
//  uint pt3 = quad_vote::vote_t(quad_ballot(y[2] > x[2]));
//  uint pt4 = quad_vote::vote_t(quad_ballot(y[3] > x[3]));
  return uint4(pt1, pt2, pt3, pt4);
}

//template <typename T, typename U = short>
//T float_function(T x, T y) {
////  T cosval;
////  T sinval = sincos(x, cosval);
////  return as_type<U>(sinval) ^ as_type<U>(cosval);
////  return fast::sinpi(x);
//
////  short pt1 = as_type<short>(x.x) + as_type<short>(y.x) ;//+ as_type<short>(y.x);
////  half3 pt2 = as_type<half3>(x.yzw) * as_type<half3>(y.yzw) + as_type<half3>(y.yzw);
////  return half4(as_type<half>(pt1), as_type<half3>(pt2));
//
//#define USHORT_CAST(x, i) as_type<ushort2>(x)[i]
//#define UINT_CAST(x) as_type<uint>(x)
//#define FLOAT_CAST(x) as_type<float>(x)
//
//  ulong result64 = as_type<ulong>(uint2(UINT_CAST(x[0]), UINT_CAST(x[1]))) + as_type<ulong>(uint2(UINT_CAST(y[0]), UINT_CAST(y[1])));
//  uint result_hi = as_type<uint2>(result64)[1];
//
//  ulong result64b = as_type<ulong>(uint2(UINT_CAST(x[0]), UINT_CAST(x[1]))) - as_type<ulong>(uint2(UINT_CAST(y[0]), UINT_CAST(y[1])));
//  uint result_hib = as_type<uint2>(result64b)[1];
//
//  ulong result642 = as_type<ulong>(uint2(UINT_CAST(x[2]), UINT_CAST(x[3]))) + as_type<ulong>(uint2(UINT_CAST(y[2]), UINT_CAST(y[3])));
//  uint result_hi2 = as_type<uint2>(result642)[1];
//
//  ulong result64b2 = as_type<ulong>(uint2(UINT_CAST(x[2]), UINT_CAST(x[3]))) - as_type<ulong>(uint2(UINT_CAST(y[2]), UINT_CAST(y[3])));
//  uint result_hib2 = as_type<uint2>(result64b2)[1];
//
////  uint result_hi = UINT_CAST(x[0]) * UINT_CAST(y[0]) + UINT_CAST(y[0]);
//
////  ulong result64b = uint(UINT_CAST(x[1]) * UINT_CAST(x[1])) + as_type<ulong>(uint2(UINT_CAST(y[1]), UINT_CAST(y[1])));
////  uint result_hib = as_type<uint2>(result64b)[1];
//
////  ulong result64b = as_type<ulong>(uint2(UINT_CAST(x[1]), 0)) + as_type<ulong>(uint2(UINT_CAST(y[1]), 0));
////  uint result_hib = as_type<uint2>(result64b)[0];
//
////  uint result_hib = UINT_CAST(x[1]) + UINT_CAST(y[1]);
//
////  ulong result64c = as_type<ulong>(uint2(UINT_CAST(x[2]), 0)) + as_type<ulong>(uint2(UINT_CAST(y[2]), 0));
////  uint result_hic = as_type<uint2>(result64c)[1];
//
////  ushort pt2a = USHORT_CAST(x[2], 0) + USHORT_CAST(y[2], 0);
////  ushort pt2b = USHORT_CAST(x[2], 1) + USHORT_CAST(y[2], 1);
////  uint pt = as_type<uint>(ushort2(pt2a, pt2b));
//
////  ushort pt2a = USHORT_CAST(x[2], 0) + USHORT_CAST(y[2], 0);
////  ushort pt2b = USHORT_CAST(x[2], 1) + USHORT_CAST(y[2], 1);
////  uint pt2 = as_type<uint>(ushort2(pt2a, pt2b));
////
////  uint result_lo = UINT_CAST(x[3]) + UINT_CAST(y[3]);
////  uint pt4 = UINT_CAST(x[3]) + UINT_CAST(y[0]);
////  ushort pt4a = USHORT_CAST(x[3], 0) ^ USHORT_CAST(y[3], 1);
////  ushort pt4b = USHORT_CAST(x[3], 1) + USHORT_CAST(y[3], 0);
////  uint pt4 = as_type<uint>(ushort2(pt4a, pt4b));
//
////  ulong result64d = as_type<ulong>(uint2(UINT_CAST(x[3]), 0)) + as_type<ulong>(uint2(UINT_CAST(y[3]), 0));
////  uint result_hid = as_type<uint2>(result64d)[1];
//
//  return float4(FLOAT_CAST(result_hi),
//                FLOAT_CAST(result_hib),
//                FLOAT_CAST(result_hi2),
//                FLOAT_CAST(result_hib2));
////                FLOAT_CAST(pt2),
////                FLOAT_CAST(result_lo),
////                FLOAT_CAST(pt4));
//
////#define HALF_CAST(x) as_type<half2>(x)[1]
////#define FLOAT_CAST(x) as_type<half2>(x)[1]
//
////  float part1 = fma(x.x, y.x, y.x);
////  float part2 = (fma(HALF_CAST(x.y), HALF_CAST(y.y), HALF_CAST(y.y)));
////  float part3 = fma(x.z, y.z, y.z);
////  float part4 = (fma(HALF_CAST(x.w), HALF_CAST(y.w), HALF_CAST(y.w)));
////  return T(part1, part2, part3, part4);
//}




////  uint lo = x * y;
////  uint hi = mulhi(x, y);
////  return lo ^ hi;
//};

//template <typename T = half, typename U = short>
//vec<FLOAT, 2> mixedOp(vec<FLOAT, 2> x, vec<FLOAT, 2> y) {
//  T lo_part = as_type<T>(x[0]) + as_type<T>(y[0]);
//  U hi_part = as_type<U>(x[1]) + as_type<U>(y[1]);
//  return vec<FLOAT, 2>(as_type<FLOAT>(lo_part), as_type<FLOAT>(hi_part));
//}

//template <typename T = half2, typename U = short2>
//vec<FLOAT, 4> mixedOp(vec<FLOAT, 4> x, vec<FLOAT, 4> y) {
//  T lo_part = max(as_type<T>(x.xy), as_type<T>(y.xy));
//  U hi_part = as_type<U>(x.zw) + as_type<U>(y.zw);
//  return vec<FLOAT, 4>(as_type<vec<FLOAT, 2>>(lo_part), as_type<vec<FLOAT, 2>>(hi_part));
//}

// MARK: - Multiply Macros

//// ILP = 1
//#define TWENTY_FOUR_GROUP_FMA01_SUBSECTION(vec1, vec6) \
//vec1[0] = OP(vec1[0], vec6[3], vec6[2]); \
//vec1[1] = OP(vec1[1], vec1[0], vec6[3]); \
//vec1[2] = OP(vec1[2], vec1[1], vec1[0]); \
//vec1[3] = OP(vec1[3], vec1[2], vec1[1]); \

// ILP = 1
#define TWENTY_FOUR_GROUP_FMA01_SUBSECTION(vec1, vec6) \
vec1[0] = OP(vec1[0], vec6[3], vec6[2]); \
vec1[1] = OP(vec1[1], vec1[0], vec6[3]); \
vec1[2] = OP(vec1[2], vec1[1], vec1[0]); \
vec1[3] = OP(vec1[3], vec1[2], vec1[1]); \

#define TWENTY_FOUR_GROUP_FMA01 \
TWENTY_FOUR_GROUP_FMA01_SUBSECTION(vec1, vec6) \
TWENTY_FOUR_GROUP_FMA01_SUBSECTION(vec2, vec1) \
TWENTY_FOUR_GROUP_FMA01_SUBSECTION(vec3, vec2) \
TWENTY_FOUR_GROUP_FMA01_SUBSECTION(vec4, vec3) \
TWENTY_FOUR_GROUP_FMA01_SUBSECTION(vec5, vec4) \
TWENTY_FOUR_GROUP_FMA01_SUBSECTION(vec6, vec5) \

// ILP = 1
#define TWENTY_FOUR_GROUP_MUL13 \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec1, vec6) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec2, vec1) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec3, vec2) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec4, vec3) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec5, vec4) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec6, vec5) \

#define TWENTY_FOUR_GROUP_MUL10 \
vec1 = OP(vec1, vec1); \
vec2 = OP(vec2, vec2); \
vec3 = OP(vec3, vec3); \
vec1 = OP(vec1, vec1); \
vec2 = OP(vec2, vec2); \
vec3 = OP(vec3, vec3); \

// ILP = 16
#define TWENTY_FOUR_GROUP_MUL11 \
vec1 = OP(vec1, vec2); \
vec4 = OP(vec4, vec5); \
vec2 = OP(vec2, vec3); \
vec5 = OP(vec5, vec6); \
vec3 = OP(vec3, vec1); \
vec6 = OP(vec6, vec4); \

// ILP = 2
//#define TWENTY_FOUR_GROUP_MUL12_SUBSECTION(vec1, vec6) \
//vec1[0] = OP(vec1[0], vec6[2]); \
//vec1[1] = OP(vec1[1], vec6[3]); \
//vec1[2] = OP(vec1[2], vec1[0]); \
//vec1[3] = OP(vec1[3], vec1[1]); \

#define TWENTY_FOUR_GROUP_MUL12_SUBSECTION(vec1, vec6) \
vec1.xy = OP(vec1.xy, vec6.zw); \
vec1.zw = OP(vec1.zw, vec1.xy); \

#define TWENTY_FOUR_GROUP_MUL12 \
TWENTY_FOUR_GROUP_MUL12_SUBSECTION(vec1, vec6) \
TWENTY_FOUR_GROUP_MUL12_SUBSECTION(vec2, vec1) \
TWENTY_FOUR_GROUP_MUL12_SUBSECTION(vec3, vec2) \
TWENTY_FOUR_GROUP_MUL12_SUBSECTION(vec4, vec3) \
TWENTY_FOUR_GROUP_MUL12_SUBSECTION(vec5, vec4) \
TWENTY_FOUR_GROUP_MUL12_SUBSECTION(vec6, vec5) \

// ILP = 1
#define TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec1, vec6) \
vec1[0] = OP(vec1[0], vec6[3]); \
vec1[1] = OP(vec1[1], vec1[0]); \
vec1[2] = OP(vec1[2], vec1[1]); \
vec1[3] = OP(vec1[3], vec1[2]); \

#define TWENTY_FOUR_GROUP_MUL13 \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec1, vec6) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec2, vec1) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec3, vec2) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec4, vec3) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec5, vec4) \
TWENTY_FOUR_GROUP_MUL13_SUBSECTION(vec6, vec5) \

// ILP = 8
#define TWENTY_FOUR_GROUP_MUL14 \
vec1 = OP(vec1, vec2); \
vec2 = OP(vec2, vec3); \
vec3 = OP(vec3, vec1); \
vec1 = OP(vec1, vec2); \
vec2 = OP(vec2, vec3); \
vec3 = OP(vec3, vec1); \

// ILP = 4
#define TWENTY_FOUR_GROUP_MUL15 \
vec1 = OP(vec1, vec3); \
vec2 = OP(vec2, vec1); \
vec3 = OP(vec3, vec2); \
vec1 = OP(vec1, vec3); \
vec2 = OP(vec2, vec1); \
vec3 = OP(vec3, vec2); \

// ILP = 3
#define TWENTY_FOUR_GROUP_MUL16_SUBSECTION(vec1, vec6) \
vec1[0] = OP(vec1[0], vec6[1]); \
vec1[1] = OP(vec1[1], vec6[2]); \
vec1[2] = OP(vec1[2], vec6[3]); \
vec1[3] = OP(vec1[3], vec1[0]); \

#define TWENTY_FOUR_GROUP_MUL16 \
TWENTY_FOUR_GROUP_MUL16_SUBSECTION(vec1, vec6) \
TWENTY_FOUR_GROUP_MUL16_SUBSECTION(vec2, vec1) \
TWENTY_FOUR_GROUP_MUL16_SUBSECTION(vec3, vec2) \
TWENTY_FOUR_GROUP_MUL16_SUBSECTION(vec4, vec3) \
TWENTY_FOUR_GROUP_MUL16_SUBSECTION(vec5, vec4) \
TWENTY_FOUR_GROUP_MUL16_SUBSECTION(vec6, vec5) \

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
vec1 = OP(vec1, vec2, vec3); \
vec2 = OP(vec1, vec2, vec3); \
vec3 = OP(vec1, vec2, vec3); \
vec4 = OP(vec4, vec5, vec6); \
vec5 = OP(vec4, vec5, vec6); \
vec6 = OP(vec4, vec5, vec6); \

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
                      threadgroup FLOAT *tg_mem [[threadgroup(0)]],
                      ushort simd_index [[simdgroup_index_in_threadgroup]])
{
  threadgroup_barrier(mem_flags::mem_none);
  FLOAT4 vec1 = inputs[0] + tg_mem[0];
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

#if THIRTIETH_SET
    TWENTY_FOUR_GROUP
#elif FIFTEENTH_SET
    TWENTY_FOUR_GROUP
    TWENTY_FOUR_GROUP
#elif TENTH_SET
    TWENTY_FOUR_GROUP
    TWENTY_FOUR_GROUP
    TWENTY_FOUR_GROUP
#elif SIXTH_SET
    ONE_TWENTY_GROUP
#elif THIRD_SET
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
#elif HALF_SET
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
#elif TWO_THIRD_SET
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
#elif FOUR_THIRD_SET
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
    ONE_TWENTY_GROUP
#elif TWO_SET
    SEVEN_TWENTY_GROUP
    SEVEN_TWENTY_GROUP
#else
    SEVEN_TWENTY_GROUP
#endif
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
