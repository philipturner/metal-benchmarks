# Metal Benchmarks

This repository thoroughly documents the Apple GPU microarchitecture, specifically its GPGPU capabilities. Details include latencies for each ALU assembly instruction, register file, and the number of unique instruction pipelines. This document enables evidence-based reasoning about performance on the M1 GPU, to help people diagnose bottlenecks in real-world software. It also compares the M1 to generations of AMD and Nvidia microarchitectures, showing where it might exhibit different performance patterns. Finally, the document examines how Apple's design choices improve power efficiency compared to other vendors.

<details>
<summary>Overview of Apple-designed GPUs</summary>

| Apple GPU | Generation | Clock Speed | Cores | GFLOPS F32 | GFLOPS F16 | GOPS I16/I32 |
| --------- | ---------- | ----------: | ----: | ---------: | ---------: | -----------: |
| A14 | Apple 7 | 1278 MHz | 4 | 654 | 1309 | >654 |
| M1 | Apple 7 | 1278 MHz | 8 | 2617 | 2617 | >1309 |
| M1 Pro | Apple 7 | 1296 MHz | 16 | 5308 | 5308 | >2654 |
| M1 Max | Apple 7 | 1296 MHz | 32 | 10620 | 10620 | >5308 |
| M1 Ultra | Apple 7 | 1296 MHz | 64 | 21230 | 21230 | >10620 |
| A15 | Apple 8 | 1336 MHz | 5 | 1710 | 1710 | >855 |
| M2 | Apple 8 | 1398 MHz | 10 | 3579 | 3579 | >1789 |
| A16 | Apple 8 | &ge;1336 MHz | 5 | &ge;1710 | &ge;1710 | >855 |
| M2 Pro | Apple 9 | &ge;1398 MHz | 18-20 | &ge;6441 | &ge;6441 | >3221 |
| M2 Max | Apple 9 | &ge;1398 MHz | 38 | &ge;13600 | &ge;13600 | >6800 |
| M2 Ultra | Apple 9 | &ge;1398 MHz | 76 | &ge;27200 | &ge;27200 | >13600 |

_The M2 Pro and later statistics come from recent leaks from Apple's supply chain. They will be updated whenever new information comes out._

</details>

Table of Contents
<!-- - [Operations per Second](operations -->

## Operations per Second

The A14 and M1 come from the Apple 7 GPU family. However, the A14 core has half the FP32 processing power. Future chips will likely retain the same ratio of F32:F16:I32 compute power (most vendors recently converged on 256 FP32 OPs/clock). The microarchitecture may become mostly "frozen" as Moore's Law grinds to a halt. Future improvements will include hardware-accelerated ray tracing, but not tensor cores. Apple's "tensor core" is the `simdgroup_matrix` instruction, which improves ALU utilization of existing FP32 pipelines (M1+) and FP16 pipelines (A14). Expect future advancements to continue in the Neural Engine, such as FP8.

| Per Core | A14 | M1, Apple 8 | GCN 5 | RDNA 1, 2 | RDNA 3 | Pascal | Turing | Ampere, Ada |
| -------- | ------- | ------- | ----- | --------- | ------ | ------ | ------ | ----------- |
| FP16 OPs/Clock | 256 | 256 | 256 | 256 | 512 | 4 | 256 | 256 |
| FP32 OPs/Clock | 128 | 256 | 128 | 128 | 256 | 256 | 128 | 256 |
| FP64 OPs/Clock | 0   | 0   | 8   | 8   | 16  | 8   | 4   | 4   |
| Float16 IPC | 128 | 128 | 128 | 128 | 256 | 2 | 128 | 128 |
| Float32 IPC | 64 | 128 | 64 | 64 | 128 | 128 | 64 | 128 |
| Float64 IPC | 0 | 0 | 4 | 4 | 8 | 4 | 2 | 2 |
| Transcendental IPC |  TBD | TBD | TBD | 1/8 FP32 | TBD | 1/8 FP32 | 1/8 FP32 | 1/16 FP32 |

| Per Core | Apple 7, 8 | GCN 5 | RDNA 1, 2 | RDNA 3 | Pascal | Turing | Ampere, Ada |
| -------- | ------- | ----- | --------- | ------ | ------ | ------ | ----------- |
| Int16 OPs/Clock |
| Int32 OPs/Clock |
| Int64 OPs/Clock |
| Int16 IPC | 128 | 128 | 128 | 128 | 256 | 256 | 0 | 0 |
| Int32 IPC | 128 | 128 | 64 | 64 | 128 | 128 | 64 | 64 |
| Int64 IPC | TBD | TBD | - | - | - | - | 0 | 0  |

_IPC stands for instructions per clock._

## SRAM

| Per Core | Apple 7, 8 | GCN 5 | RDNA 1, 2 | RDNA 3 | Pascal | Turing | Ampere, Ada |
| -------- | ------- | ----- | --------- | ------ | ------ | ------ | ----------- |
| Max Threads (Occupancy) | 768-3072 | 256-2560 | 256-2560 | 384-TBD | 256-2048 | 256-1024 | 256-1536 |
| Register File | 384 KB | 256 KB | 256 KB | 384 KB | 256 KB | 256 KB | 256 KB |
| Shared Memory | 64 KB | 64 KB | 128 KB | 128 KB | 96 KB | 32-64 KB | 8-100 KB |
| L1 Instruction Cache | 12 KB | 32 KB | 32 KB | 32 KB | 8 KB | 12 KB | 32 KB |
| L1 Data Cache | ~8-12 KB | 16 KB | 16 KB | 32 KB | 24-48 KB | 32-64 KB | 28-128 KB |

<img src="./Documentation/Instruction_Cache_M1_Max.png" alt="Graph of executable size vs. performance for an M1 Max at 92% occupancy" width="75%" />

## Instruction Throughputs

Throughput and latency are measured in cycles. If listed with a comma, throughputs differ between A14 and M1. A14 is listed first. Concurrency means the number of times each pipeline's circuitry is physically duplicated. For example, a 2-cycle operation needs 2 pipelines/ALU to reach 1 cycle/instruction throughput.

> Little's Law: Concurrency = Latency / Throughput
> 
> Cycles Throughput &ge; Cycles Latency / (Pipelines/ALU)

<details>
<summary>Floating-point performance</summary>

| Float Instruction | Throughput | Latency | Concurrency/ALU | Concurrency/Core |
| -------------------------- | ------ | ------- | ----------- | --- |
| FADD16 | 1, 1 | 3 | 3 | 12 |
| FMUL16 | 1, 1 | 3 | 3 | 12 |
| FFMA16 | 1, 1 | 3 | 3 | 12 |
| FADD32 | 2, 1 | 3, 3 | 1.5, 3 | 6, 12 |
| FMUL32 | 2, 1 | 3, 3 | 1.5, 3 | 6, 12 |
| FFMA32 | 2, 1 | 3, 3 | 1.5, 3 | 6, 12 |
| ROUND_EVEN | 4 | 4 | 1 | 4 |
| CONVERT(I to F) | 4 | 4 | 1 | 4 |
| RECIP |
| DIV |
| RSQRT | 8, 8 | 12 | 1.5 | 6 |
| SQRT |
| SIN |
| COS |
| EXP2 |
| LOG2 |
| FMAX32 | 1, 1 | 3 | 3 | 12 |
| FMIN32 | 1, 1 | 3 | 3 | 12 |
| FCMPSEL |

</details>

<details>
<summary>Integer performance</summary>

| Int Instruction | Throughput | Latency | Concurrency/ALU | Concurrency/Core |
| -------------------------- | ------ | ------- | ----------- | --- |
| IADD16 | 1, 1 | 3 | 3 | 12 |
| IMUL16 | 4, 4 | 4 | 1 | 4 |
| IMAD16 | 4, 4 | 4 | 1 | 4 |
| IADD32 | 1, 1 | 3 | 3 | 12 |
| IMUL32 | 4, 4 | 4 | 1 | 4 |
| IMAD32 | 4, 4 | 4 | 1 | 4 |
| IMADHI32 | 8 | 8 | 1 | 4 |
| IMAD (32x32+??->64) | 11 ??? |
| BITSHIFT32 |
| BITEXTRACT32 |
| BITWISE32 | 1 | 1 | 1 | 4 |
| BITREV32 | 4 | 3 | 1 | 4 |
| POPCOUNT32 |
| CTZ/CLZ32 |
| IMAX32 |
| IMIN32 |
| ICMPSEL32 |

</details>

<details>
<summary>Multi-instruction operations</summary>

| Instruction Sequence | Throughput | Latency | Concurrency/ALU | Concurrency/Core |
| -------------------------- | ------ | ------- | ----------- | --- |
| ROUND_INF | &le;8.3 | &le;22 | 2-3 | 8-12 |
| FMEDIAN | &le;3.6 | &le;10 | 3 | 12 | 
| IMADHI16 | 4 | 8 | 2 | 8 |
| BITREV16 | &le;4.2 | &le;13 | 3 | 12 |
| RHADD16 | 4 | 16 | 4 | 16 |
| RHADD32 | 6 | &le;36 | &le;6 | &le;24 |
| ABSDIFF32 | 4 | 8-10 | 2-3 | 8-12 |
| IADD64 | >4 |
| IMUL64 | >13.4 |
| IMULHI64 |
| BITSHIFT64 |
| BITEXTRACT64 |
| BITWISE64 | 1 | 1 | 1 | 4 |
| BITREV64 |
| POPCOUNT64 |
| CLZ/CTZ64 |
| IMAX64 |
| IMIN64 |
| ICMPSEL64 |
| 3 FFMA32 + IADD64 |
| 3 IADD32 + IADD64 |
| 3 IMUL16 + 2 IADD64 |
| Precise RECIP |
| Precise DIV |
| Precise RSQRT |
| Precise SQRT |
| Precise SIN |
| Precise COS |
| Precise EXP2 |
| Precise LOG2 |

| Instruction Sequence | Actual Instructions |
| -------------------------- | ------ |
| IMADHI16 | IMUL32 + ISHIFT32 ??? |
| RHADD32 | IADD32 + IADD32 + ISHIFT32 ??? |

</details>

TODO: Sort out the number of unique pipelines.

TODO: Test Apple's claims about "double the FP32 math units" on A15.

<!-- TODO: Rethink this analysis. Instructions can be dual-dispatched, but there aren't enough pipelines for this to double maximum FLOPS.

<s>The Apple GPU does not have dual-dispatch for F32 and I32, like Nvidia does. F16/I16 arithmetic is not faster than 32-bit counterparts. Not sure whether FMA has 3 or 4-cycle latency. Some bad integer multiply benchmarks had cycle throughputs as multiples of 1/3 (2.00, 2.33, 2.67), but potentially because of a 4-instruction recurring register dependency (4 - 1). Command concurrency benchmarks suggest latency must be divisible by 2; the ALU can pipeline up to 2 FMAs from the same SIMD-group simultaneously. The result is exactly half the peak performance of one GPU core. That would mean 4-cycle latency with 4x concurrency, the same scheme used in Firestorm CPU cores and Nvidia GPUs.

This analysis suggests an ALU has four concurrent pipelines. Each can execute either F32 or I32 math; both data types might share the same circuitry. 64-bit integer operations are one instruction in assembly code</s>, but 4-6x slower than 32-bit integer ops. <s>This is similar to the Apple AMX, where 64-bit floats are 4x slower than 32-bit floats because they don't have dedicated circuitry.</s> Also like the AMX, F16 is neither faster nor slower than F32. F16 mostly decreases register pressure, which increases occupancy and therefore ALU utilization. The AMD GPU also has Int64 math running 4x slower than Int32, <s>possibly</s> with better multiply throughput than Apple. Nvidia emulates it. </s> -->

## Bottlenecks on Throughput

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

_ILP stands for instruction-level parallelism. It is the number of operations you could theoretically execute in parallel, on a superscalar processor._

</details>

The next graphs show scalar instructions per cycle in the entire compute unit. This relates to the reciprocal of amortized cycles/instruction. FADD, FMUL, FFMA, and IADD have the same latency/throughput characteristics. As long as FFMA is performed as `(x * y) + y`, it will only have two register dependencies. In this situation only, it behaves similarly to `FADD`.

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

## US Patents

<details>
 
<summary>Patents that may reveal design characteristics of the Apple GPU</summary>
  
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

## GPU Configurations

M1 (7-core): https://gist.github.com/IMS212/04d2a96a06eb2c8062029e5680d144f6

M1 (8-core): https://gist.github.com/tommythorn/0ba150bd7a377a6bed4443f412825e20

M1 Pro (14-core): https://gist.github.com/useraccessdenied/60e211cc13f6986867b6a43ad08fd798

M1 Max (32-core): https://gist.github.com/philipturner/48c72e3fcce0ce9489071eb083a5086e
