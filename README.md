# Metal Benchmarks

This document thoroughly explains the Apple GPU microarchitecture, focusing on its GPGPU performance. Details include latencies for each ALU assembly instruction, cache sizes, and the number of unique instruction pipelines. This document enables evidence-based reasoning about performance on the M1 GPU, helping people diagnose bottlenecks in real-world software. It also compares the M1 to generations of AMD and Nvidia microarchitectures, showing where it might exhibit different performance patterns. Finally, the document examines how Apple's design choices improve power efficiency compared to other vendors.

This repository also contains open-source benchmarking scripts. They allow anyone to reproduce and verify the author's claims about performance.

<details>
<summary>Overview of Apple-designed GPUs</summary>

| Apple GPU | Generation | Clock Speed | Cores | GFLOPS F32 | GFLOPS F16 | GOPS I16/I32 |
| --------- | ---------- | ----------: | ----: | ---------: | ---------: | -----------: |
| A14 | Apple 7 | 1278 MHz | 4 | 654 | 1309 | 654 |
| M1 | Apple 7 | 1278 MHz | 8 | 2617 | 2617 | 1309 |
| M1 Pro | Apple 7 | 1296 MHz | 16 | 5308 | 5308 | 2654 |
| M1 Max | Apple 7 | 1296 MHz | 32 | 10620 | 10620 | 5308 |
| M1 Ultra | Apple 7 | 1296 MHz | 64 | 21230 | 21230 | 10620 |
| A15 | Apple 8 | 1336 MHz | 5 | 1710 | 1710 | 855 |
| M2 | Apple 8 | 1398 MHz | 10 | 3579 | 3579 | 1789 |
| A16 | Apple 8 | &ge;1336 MHz | 5 | &ge;1710 | &ge;1710 | 855 |
| M2 Pro | Apple 9 | &ge;1398 MHz | 18-20 | &ge;6441 | &ge;6441 | 3221 |
| M2 Max | Apple 9 | &ge;1398 MHz | 38 | &ge;13600 | &ge;13600 | 6800 |
| M2 Ultra | Apple 9 | &ge;1398 MHz | 76 | &ge;27200 | &ge;27200 | 13600 |

_The M2 Pro and later statistics come from recent leaks from Apple's supply chain. They will be updated whenever new information comes out._

</details>

Table of Contents
- [On-Chip Memory](#on-chip-memory)
- [Operations per Second](#operations-per-second)
- [Pipelines per ALU](#pipelines-per-alu)
- [Instruction Throughputs](#instruction-throughputs)
- [ALU Bottlenecks](#alu-bottlenecks)
- [Power Efficiency](#power-efficiency)
- [References](#references)

## On-Chip Memory

| Per Core | Apple 7, 8 | GCN 5 | RDNA 1, 2 | RDNA 3 | Pascal | Turing | Ampere, Ada |
| -------- | ------- | ----- | --------- | ------ | ------ | ------ | ----------- |
| Max Threads (Occupancy) | 768-3072 | 256-2560 | 256-2560 | 384-TBD | 256-2048 | 256-1024 | 256-1536 |
| Register File | 384 KB | 256 KB | 256 KB | 384 KB | 256 KB | 256 KB | 256 KB |
| Shared Memory | 64 KB | 64 KB | 128 KB | 128 KB | 96 KB | 32-64 KB | 8-100 KB |
| L1 Instruction Cache | 12 KB | 32 KB | 32 KB | 32 KB | 8 KB | 12 KB | 32 KB |
| L1 Data Cache | ~8-12 KB | 16 KB | 16 KB | 32 KB | 24-48 KB | 32-64 KB | 28-128 KB |

<img src="./Documentation/Instruction_Cache_M1_Max.png" alt="Graph of executable size vs. performance for an M1 Max at 92% occupancy" width="75%" />

## Operations per Second

The A14 and M1 come from the Apple 7 GPU family. However, the A14 core has half the FP32 processing power. A few months before the M1 launched, Nvidia's Ampere GPUs doubled FP32 performance while keeping everything else constant. _<b> This event likely inspired Apple to take the same approach.</b>_ It happened early enough in the chip design process for Apple to revise the M1 architecture, but probably not the A14. _<b>The original design was optimized for FP16, explaining why the M1's extra FP32 power is notoriously underutilized.</b>_

Future chips will likely retain the same ratio of F32:F16:I32 compute power (most vendors recently converged on 256 FP32 OPs/clock). The microarchitecture may become mostly "frozen" as Moore's Law grinds to a halt. Future improvements will include hardware-accelerated ray tracing, but not tensor cores. Apple's "tensor core" is the `simdgroup_matrix` instruction, which improves ALU utilization of existing FP32 pipelines (M1+) and FP16 pipelines (A14). AI advancements could continue in the Neural Engine, such as FP8.

| Per Core | A14 | M1, A15 | GCN 5 | RDNA 1, 2 | RDNA 3 | Pascal | Turing | Ampere, Ada |
| -------- | ------- | ------- | ----- | --------- | ------ | ------ | ------ | ----------- |
| F16 OPs/Clock | 256 | 256 | 256 | 256 | 512 | 4 | 256 | 256 |
| F32 OPs/Clock | 128 | 256 | 128 | 128 | 256 | 256 | 128 | 256 |
| F64 OPs/Clock | 0   | 0   | 8   | 8   | 16  | 8   | 4   | 4   |
| F16 IPC | 128 | 128 | 128 | 128 | 256 | 2 | 128 | 128 |
| F32 IPC | 64 | 128 | 64 | 64 | 128 | 128 | 64 | 128 |
| F64 IPC | 0 | 0 | 4 | 4 | 8 | 4 | 2 | 2 |
| Transcendental IPC | 16-32 | 16-32 | TBD | 16 | TBD | 32 | 16 | 16 |

_On Nvidia chips, all major transcendentals take the same amount of time. On Apple chips, throughput depends on the operation._

| Per Core | Apple 7, 8 | GCN 5 | RDNA 1, 2 | RDNA 3 | Pascal | Turing | Ampere, Ada |
| -------- | ------- | ----- | --------- | ------ | ------ | ------ | ----------- |
| I16 OPs/Clock | 128 | 256 | 256 | 512 | 0 | 0 | 0 |
| I32 OPs/Clock | 128 | 128 | 128 | 256 | 128 | 128 | 128 |
| I64 OPs/Clock | 32 | 32 | 32 | 64 | 0 | 0 | 0 |
| I16 IPC | 128 | 128 | 128 | 256 | 256 | 0 | 0 | 0 |
| I32 IPC | 128 | 64 | 64 | 128 | 128 | 64 | 64 |
| I64 IPC | 32 | 16 | 16 | 32 | 0 | 0 | 0  |
| I32 Adds/Clock | 128 | 64 | 64 | 128 | 128 | 64 | 64 |
| I32 Muls/Clock | 32 | 64 | 64 | 128 | 0 | 64 | 64 |
| I64 Adds/Clock | 32 | 16 | 16 | 32 | 0 | 0 | 0 |
| I64 Muls/Clock | 8 | 16 | 16 | 32 | 0 | 0 | 0 |

_IPC stands for instructions per clock. Integer IPC consists of adds and/or fused multiply-adds, in whatever combination is fastest. Integer compare-select, which is two operations in one instruction, doesn't count._

## Pipelines per ALU

For marketing, Apple says that each GPU core contains 128 ALUs. These roughly correspond to all the pipelines necessary to sustain one scalar/cycle. Integer pipelines process both I32 and U32 with the same latency. Most pipelines accept 16-bit operands or write 16-bit results, with zero additional cost. For floating-point pipelines, a 32-bit register dependency invokes a ~1-cycle penalty until ILP approaches 4.

On A14, we might have separate F16 and F32 pipelines. This would reflect how Metal Frame Capture shows separate statistics for "F16 utilization" and "F32 utilization". It also reflects Apple's statement of "twice the F32 pipelines" in their A15 video. This scheme would indicate mixed-precision F16/F32 compute similar to RDNA 2 (the F32 pipelines provide half the total F16 power). We omit the A14 design for simplicity.

---

Floating-point pipelines (A15+, M1+)
- 3 cycles: F/IADD32, F/ICMPSEL32, BITSHIFT32(<<4)
- 3 cycles: F/IADD32, F/ICMPSEL32, BITSHIFT32(<<4)
- 3 cycles: F/IADD32, F/ICMPSEL32, BITSHIFT32(<<4)
- 3 cycles: FMUL32, FFMA16, multiply part of FFMA32
- 3 cycles: FMUL32, FFMA16, multiply part of FFMA32
- 3 cycles: FMUL32, FFMA16, multiply part of FFMA32
- 4 cycles: convert I32 to F32, round F32 to U32/I32, extract fractional part
- TODO: Test whether `fract` can happen concurrently to `rint`.

Complex integer and bitwise pipelines:
- 4 cycles: one 32x32 chunk of a large-integer product, BITSHIFT32 by an amount unknown at compile-time
- 1 cycle: BITWISE32

Transcendental math pipelines (1-2x per ALU):
- TODO: The actual pipelines.
- TODO: Can multiple math operations happen simultaneously?

---

This model is somewhat oversimplified. The FFMA16 instruction may share a modular multiplier circuit with FFMA32 (1 cycle/16x16=32). If so, the pipeline begins with a 1-cycle check on the exponent of the F16/F32. It ends with a mantissa addition. FFMA32 takes `1` + `roundup((24x24/16x16)^2)` + `roundup(48/24)` = `6` cycles. FFMA16 takes `1` + `roundup((11x11/16x16)^2)` + `roundup(22/24)` = `3` cycles. This aligns with latency measurements. FFMA16 will not reach higher throughput than FFMA32 because the scheduler only dispatches 1 IPC/ALU. FFMA32 reaches full utilization - 6 cycles latency, harnessing 6 concurrent pipelines.

## Instruction Throughputs

Throughput and latency are measured in cycles. If listed with a comma, throughputs were tested on multiple chips (A14, M1 Max). Latencies are sometimes recorded in two forms separated by a dash. First, half the best recorded throughput at 2 simds/core and ILP = 1. Second, the best recorded throughput at 4 simds/core and ILP = 1. Benchmarks issued 250x the amount of work needed to fully occupy a core's register file.

Concurrency means the number of times each pipeline's circuitry is physically duplicated. For example, a 2-cycle operation needs 2 pipelines/ALU to reach 1 cycle/instruction throughput.

TODO: Transform "optimal repetitions" for instruction sequences into executable size.

> Little's Law: Concurrency = Latency / Throughput
> 
> Cycles Throughput = Cycles Latency / (Pipelines/ALU)

<details>
<summary>Floating-point performance</summary>

| Float Instruction | Throughput | Latency | Concurrency/ALU | Concurrency/Core |
| -------------------------- | ------ | ------- | ----------- | --- |
| FADD16 | 1, 1 | TBD, 2.97-3.33 |
| FMUL16 | 1, 1 | TBD, 2.98-3.34 |
| FFMA16 | 1, 1 | TBD, 2.97-3.35 |
| FADD32 | 2, 1 | TBD, 3.50-3.90 |
| FMUL32 | 2, 1 | TBD, 3.50-3.91 |
| FFMA32 | 2, 1 | TBD, 5.84-6.18 |
| ROUND_EVEN(F->I32) | 4 | 3.78-5.36 |
| ROUND_EVEN(F->I64) |
| FRACT_PART16 |
| FRACT_PART32 |
| CONVERT(I32->F) | 4 |
| CONVERT(I64->F) |
| Fast RECIP16 | TBD, 6 | TBD, &le;7.5 |  |  |
| Fast RECIP32 | TBD, 6 | TBD, &le;8.0 |  |  |
| Fast RSQRT16 | 8, 8 | TBD, 7.11-9.78 |  |  |  
| Fast RSQRT32 | 8, 8 | TBD, 7.13-10.69 |  |  |
| SIN_PT_1 |
| SIN_PT_2 |
| Fast EXP2_16 | TBD, 4 | TBD, 6 |  |  |
| Fast LOG2_16 | TBD, 4 | TBD, 6 |  |  |
| Fast EXP2_32 | TBD, 4 | TBD, 6 |  |  |
| Fast LOG2_32 | TBD, 4 | TBD, 6 |  |  |
| FMAX32 | 1, 1 | 3-4 |
| FMIN32 | 1, 1 | 3-4 |
| FCMPSEL16 | 1, 1 | 3 |
| FCMPSEL32 | 1, 1 | 3-4 |

TODO: Test FFMA and transcendental latencies on A14, verify FADD32 and FMUL32 throughputs. Look for disparities between F16 and F32.

| Instruction Sequence | Throughput | Latency | Optimal Repetitions |
| -------------------------- | ------ | ------- | ---- |
| ROUND_INF | 8.18 | 20.98-21.38 | 240 |
| FMEDIAN16 | 6.54 | 15.00-16.41 | ~120-240 |
| FMEDIAN32 | 3.65 | 9.20-10.86 | ~360-480 |
| Fast DIV16 | TBD, 6 | TBD, &le;9.5 |
| Fast DIV32 | TBD, 6 | TBD, &le;9.0 |
| Fast SQRT16 | TBD, 8 | TBD, 9.56-10.74 | 960 |
| Fast SQRT32 | TBD, 8 | TBD, 8.57-11.13 | 960 |
| Fast SIN16 | TBD, &le;14.6 | TBD, &le;27.8 |
| Fast SINPI16 | TBD, &le;18.7 | TBD, &le;51.5 |
| Fast SIN32 | TBD, &le;14.5 | TBD, &le;27.3 |
| Fast SINPI32 | TBD, &le;26.3 |  TBD, &le;88.8 |
| Precise RECIP |
| Precise DIV |
| Precise RSQRT |
| Precise SQRT |
| Precise SIN | &le;24.4 | &le;225.3 |
| Precise SINPI | &le;30.4 | &le;104.4 |
| Precise EXP2 |
| Precise LOG2 |

| Instruction Sequence | Actual Instructions |
| -------------------------- | ------ |
| Fast DIV | Fast RECIP + FMUL32 |
| TRIG_REDUCE | MUL + FRACT + FMA |
| Fast SIN32 | TRIG_REDUCE + SIN_PT_1 + SIN_PT_2 |
| Fast COS32 | TRIG_REDUCE + SIN_PT_1 + SIN_PT_2 |

</details>

<details>
<summary>Integer performance</summary>

| Int Instruction | Throughput | Latency | Concurrency/ALU | Concurrency/Core |
| -------------------------- | ------ | ------- | ----------- | --- |
| IADD16 | 1, 1 | 2.97-3.34 |
| IMUL16 | 4, 4 | 4.20-5.39 | 
| IMAD16 | 4, 4 | 4.18-5.38 |
| IADD32 | 1, 1 | 3.51-3.91 |
| IMUL32 | 4, 4 | 4.30-5.72 |
| IMAD32 | 4, 4 | 7.13-7.67 |
| IADD(32+32=64) | &le; 3 | TODO |
| IMAD((32x32=32)+64) | 4 | &le;15 |
| IMADHI32 | 8 | 9.83-12.20 |
| IMAD((32x32=64)+64) | 8 | 8 |
| IMAD(64x32+64=64) | 12 | &le;24 |
| IADD64 | 4 | &le;14 |
| IMUL64 | 16 | &le;32 |
| IMAD64 | 16 | &le;32 |
| BITSHIFT32 |
| BITEXTRACT32 |
| BITWISE32 | 1 | 1 |
| BITREV32 | 4 | 3 |
| POPCOUNT32 |
| CTZ/CLZ32 |
| ICMPSEL16 | 1, 1 | 2.98-3.34 |
| IMAX32 | 1, 1 | 6.30-6.61 |
| IMIN32 | 1, 1 | 6.31-6.63 |
| ICMPSEL32 | 1, 1 | 6.31-6.64 |

TODO: Test optimal repetitions on mixed-precision integer math. Are they all performed in a single instruction?

| Instruction Sequence | Throughput | Latency | Optimal Repetitions |
| -------------------------- | ------ | ------- | ----- |
| IMADHI16 | 4 | 6.23-7.29 | 720
| BITREV16 | 4 | 5.76-6.76 | 480
| RHADD16 | 4 | 15.65-16.42 | 480
| RHADD32 | 6 | 18.96-20.89 | 240
| ABSDIFF32 | 4 | &le;10 |
| IMULHI64 | 28 | &le;112 |
| BITSHIFT64 |
| BITEXTRACT64 |
| BITWISE64 |
| BITREV64 |
| POPCOUNT64 |
| CLZ/CTZ64 |
| IMAX64 |
| IMIN64 |
| ICMPSEL64 |

| Instruction Sequence | Actual Instructions |
| -------------------------- | ------ |
| IMADHI16 | IMUL32 + REG_MOVE |

_Register move may be implemented through an instruction that adds zero._

</details>

<details>
<summary>64-bit integer math</summary>

According to the Metal Feature Set Tables, the A11 and later have "64-bit integer math". It turns out that Apple has hardware-accelerated 64-bit integer multiplication and addition. It takes 4 cycles to add two 64-bit integers, the same time it would take to emulate through 32-bit. However, requiring a single assembly instruction reduces executable size. The IADD64 pipeline seems to interfere with the FADD32/IADD32 pipeline in the following way:

> Throughput &ge; 4(number IADD64s) + 1(number IADD32s) + 1(number FADD32s)

This suggests that it hijacks the IADD32 integer pipeline to perform segments of the IADD64 addition. The FADD32 pipeline also uses this circuitry to add floating point mantissas.

With 4 cycles for IMAD32 and 8 cycles for IMAD((32x32=64)+64=64), emulating IMUL64 would take 20 cycles. Hardware performs this in 16 cycles, and is therefore native. This may be slower than emulation on AMD, where IMAD32 takes 1 cycle.

MUL(32x32=64) only takes 8 cycles with the following Metal code. Do not explicitly split it into MUL32 and MULHI32, which takes 12 cycles. A 64-bit addition can also be fused into this multiply, at no additional cost.

```metal
// 12 cycles - don't do this.
ulong naive_mul32x32_64(uint x, uint y) {
  uint lo = x * y;
  uint hi = mulhi(x, y);
  return as_type<ulong>(uint2(lo, hi));
}

// 8 cycles
ulong mul32x32_64(uint x, uint y) {
  return ulong(x) * ulong(y);
}

// 12 cycles
ulong mul64x32_64(ulong x, uint y) {
  return x * ulong(y);
}

// 16 cycles
ulong mul64x64_64(ulong x, ulong y) {
  return x * y;
}
```

</details>

<details>
<summary>Mixed workload performance</summary>

| Instruction Sequence | Throughput |
| -------------------------- | ------ |
| 4 FADD/FFMA/IADD16 | 4.12 |
| 4 FADD/FFMA/IADD32 | 4.12 |
| 2 IADD32 + 2 IADD16 | 4.16 |
| 2 FADD/FFMA32 + 2 FADD/FFMA16 | 4.16 |
| IMUL/MAD16 + 3 FADD/FFMA/IADD16 | 4.84 |
| IADD32 + 4 FADD16 | 5.16 |
| IMUL32 + 4 FADD16 | 5.56 |
| IMAD16 + 4 IADD16 | 5.88 |
| IMAD32 + 4 IADD16 | 6.08 |
| 2 IMAD16 + 4 IADD16 | 9.68 |
| 2 IMAD32 + 4 IADD16 | 9.20 |
| 3 IMAD32 + 2 IADD16 | 12.00 |
| IADD64 + 3 FADD32 | 7.36 |
| IADD64 + 3 IADD32 | 7.32 |
| IADD64 + 4 IADD16 | 8.96 |
| 2 IADD64 + 2 FADD32 | 15.20 |
| 2 IADD64 + 2 IADD32 | 15.24 |
| IADD64 + 2 IADD32 + 2 IADD16 | 9.04 |
| 2 IMAD((32x32=32)+64=64) + 4 IADD16 | 13.04 |
| 2 IMUL32 + 4 IADD16 | 9.20 |
| 2 IMAD32 + 4 IADD16 | 9.20 |
| IMAD32 + IMAD((32x32=32)+64=64) + 4 IADD16 | 11.16 |
| IMAD((32x32=32)+64=64) + 4 IADD16 | 8.44 |

</details>

## ALU Bottlenecks

In low-occupancy situations, or situations with heavy register dependencies, F16/I16 is significantly faster than F32/I32. For back-to-back dependent FMUL, there's a 0.84-cycle throughput penalty for a 32-bit register dependency (1.84 total). When switching to a 16-bit register, that's a 0.56-cycle throughput penalty (1.56 total). In a minimum-occupancy situation, combined latencies are 6.6 and 3.9 cycles. The gap widens to 11.3 vs 3.9 for low-occupancy FMA. Now it makes sense why Apple pushes for half-precision in Metal.

<details>
<summary>Tables for FMUL, FADD, IADD, FFMA</summary>

| ILP | Occupancy | Instruction | F32/I32 Cycles | F16/I16 Cycles |
| - | - | - | - | - |
| 1 | 4 simds/core | FMUL, FADD, IADD | 6.60 | 3.92 |
| 2 | 4 simds/core | FMUL, FADD, IADD | 5.59 | 2.49 |
| 3 | 4 simds/core | FMUL, FADD, IADD | 5.14 | 2.55 |
| 4 | 4 simds/core | FMUL, FADD, IADD | 2.86 | 1.78 |
| 1 | 8 simds/core | FMUL, FADD, IADD | 3.44 | 2.16 |
| 2 | 8 simds/core | FMUL, FADD, IADD | 3.08 | 1.46 |
| 3 | 8 simds/core | FMUL, FADD, IADD | 2.78 | 1.47 |
| 4 | 8 simds/core | FMUL, FADD, IADD | 1.58 | 1.26 |
| 1 | 88 simds/core | FMUL, FADD, IADD | 1.84 | 1.56 |
| 2 | 88 simds/core | FMUL, FADD, IADD | 1.73 | 1.05 |
| 3 | 88 simds/core | FMUL, FADD, IADD | 1.37 | 1.04 |
| 4 | 88 simds/core | FMUL, FADD, IADD | 1.01 | 1.02 |

_ILP stands for instruction-level parallelism. It is the number of operations you could theoretically execute in parallel, on a superscalar processor._

| ILP | Occupancy | Instruction | FP32 Cycles | FP16 Cycles |
| - | - | - | - | - |
| 1 | 4 simds/core | FFMA | 11.34 | 3.94 |
| 2 | 4 simds/core | FFMA | 8.36 | 2.44 |
| 3 | 4 simds/core | FFMA | 4.46 | 2.55 |
| 4 | 4 simds/core | FFMA | 2.75 | 1.79 |
| 1 | 8 simds/core | FFMA | 5.71 | 2.15 |
| 2 | 8 simds/core | FFMA | 4.24 | 1.40 |
| 3 | 8 simds/core | FFMA | 2.75 | 1.47 |
| 4 | 8 simds/core | FFMA | 1.60 | 1.29 |
| 1 | 88 simds/core | FFMA | 1.99 | 1.56 |
| 2 | 88 simds/core | FFMA | 1.87 | 1.04 |
| 3 | 88 simds/core | FFMA | 1.35 | 1.04 |
| 4 | 88 simds/core | FFMA | 1.02 | 1.02 |

</details>

The graphs below depict scalar instructions per cycle across the entire compute unit. This metric relates to the reciprocal of amortized cycles/instruction (throughput). FADD, FMUL, FFMA, and IADD have the same latency/throughput characteristics. As long as FFMA is performed as `(x * y) + y`, it will only have two register dependencies. In this situation only, it behaves similarly to `FADD`.

| ![Instructions per cycle (ILP = 1)](./Documentation/Instructions_Cycle_ILP_1.png) | ![Instructions per cycle (ILP = 2)](./Documentation/Instructions_Cycle_ILP_2.png) |
| - | - |
| ![Instructions per cycle (ILP = 3)](./Documentation/Instructions_Cycle_ILP_3.png) | ![Instructions per cycle (ILP = 4)](./Documentation/Instructions_Cycle_ILP_4.png) |

## Power Efficiency

<img src="./Documentation/Power_Performance_M1_Max.png" alt="Graph of power vs. performance for an M1 Max at 1296 MHz" width="75%" />

The M1 Max has 32 GPU cores, but can perform up to 96 compute commands simultaneously. The A15 has slightly more the concurrency, performing 20 commands on 5 GPU cores. In comparison, all Nvidia GPUs top out at 128 concurrent commands. To reach the same concurrency, an Nvidia GPU must have at most 32-42 SMs. This is true for the RTX 3060, but not for more powerful GPUs. While the concurrency seems excessive for the purpose of multitasking, it has another purpose. Say that one task requires resources from 22 GPU cores, and another requires resources from 11. A naive GPU design would only permit 4 concurrent commands. That would allocate 16 GPU cores to the first task and 8 to the second, wasting the other 8. Apple's design lets you divide work more finely.

There's one more usage. The hypothetical workload divides evenly among 33 GPU cores, but we have 32. You could reimagine each task as requiring 32/33x the resources, but the new resource requirements are fractions. With the M1 GPU, you can divide an individual core into fractions. That drastically reduces the load imbalance between tasks 1 and 2. This benefit is most useful on A-series chips with only 3-5 GPU cores to subdivide. For the Mac, it's overkill but contributes to incredible (power) efficiency. I don't know whether the A15 has greater (4/3x) concurrency because it's from the Apple8 generation, or because it's an A-series GPU.

This sub-core concurrency only happens among commands within the same `MTLComputeCommandEncoder`. For commands on different Metal command queues, there's only 2x concurrency across the entire GPU. This makes it similar to early dual-core CPUs, designed in part to be more responsive. Even if a background task is taking several frames, a high-priority UI command can quickly seize half the GPU cores. Beyond that purpose, there's little motive to create any circuitry for 3+ concurrent command queues.

TODO: less/slower? threadgroup memory, power varying with clock speed

## References

https://github.com/dougallj/applegpu

https://www2.eecs.berkeley.edu/Pubs/TechRpts/2016/EECS-2016-143.pdf

https://rosenzweig.io/blog/asahi-gpu-part-4.html

https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf

https://github.com/AsahiLinux/docs/wiki/HW:AGX

https://arxiv.org/pdf/1804.06826.pdf

https://arxiv.org/pdf/1905.08778.pdf

https://github.com/dougallj/applegpu/issues/21

https://chipsandcheese.com/2022/05/21/igpu-cache-setups-compared-including-m1/

https://www.techspot.com/article/2151-nvidia-ampere-vs-amd-rdna2/

<details>
<summary>Patents related to the Apple GPU</summary>
  
https://www.freepatentsonline.com/y2019/0057484.html

https://patents.justia.com/patent/9633409

https://patents.justia.com/patent/9035956

https://patents.justia.com/patent/20150070367

https://patents.justia.com/patent/9442706

https://patents.justia.com/patent/9508112

https://patents.justia.com/patent/9978343
  
https://patents.justia.com/patent/9727944
 
https://patents.justia.com/patent/10114446

</details>

<details>
<summary> GPU configurations from IORegistry </summary>

M1 (7-core): https://gist.github.com/IMS212/04d2a96a06eb2c8062029e5680d144f6

M1 (8-core): https://gist.github.com/tommythorn/0ba150bd7a377a6bed4443f412825e20

M1 Pro (14-core): https://gist.github.com/useraccessdenied/60e211cc13f6986867b6a43ad08fd798

M1 Max (32-core): https://gist.github.com/philipturner/48c72e3fcce0ce9489071eb083a5086e
 
</details>
