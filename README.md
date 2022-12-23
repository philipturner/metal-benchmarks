# Metal Benchmarks

Test suite to measure microarchitectural details of the M1 GPU. These details include latencies for each ALU assembly instruction, threadgroup memory bandwidth, and the number of unique instruction pipelines. This information will enable evidence-based reasoning about performance on the M1 GPU. This repository also compares the M1 to generations of AMD and Nvidia microarchitectures. <!-- Finally, it examines how Apple's design choices improve power efficiency compared to other vendors. -->

## Layout of an M1 GPU Core

| Per Core | Apple 7 | Apple 8 | GCN 5 | RDNA 2 | RDNA 3 | Turing | Ampere | Ada |
| -------- | ------- | ------- | ----- | ------ | ------ | ------ | ------ | --- |
| Max Threads | 1152-3072 | TBD | 256-2560 | TBD-2048 | TBD-2048 | 256-1024 | 256-1536 | 256-1536 |
| FP32 ALUs | 128 | 128 | 64 | 64 | 128 | 128 | 128 | 128 |
| Register File | 624 KB | TBD | 256 KB | 256 KB | 384 KB | 256 KB | 256 KB | 256 KB |
| Shared Memory | 64 KB | 64 KB | 64 KB | 128 KB | 128 KB | 32-64 KB | 8-100 KB | 8-100 KB |
| L1 Instruction Cache | ~19-32 KB ??? | TBD | 32 KB | 32 KB | 32 KB | ~12 KB | 32 KB | 32 KB |
| L1 Data Cache | ~8-16 KB ??? | TBD | 16 KB | 16 KB | 32 KB | 32-64 KB | 28-128 KB | 28-128 KB |

https://github.com/dougallj/applegpu/issues/21

| Instruction | Max Throughput (cycles) |
| ----------- | ------------------- |
| FADD32 | 1 |
| FMUL32 | 1 |
| FFMA32 | 1 |
| IADD32 | 1 |
| IMUL32 | 2 - 2.33 |
| IMAD32 | 3 - 3.67 |
| IMADHI32 | 8 |
| IMAD (32x32+??->64) | 11 |
| IADD64 | 4 |
| IMUL64 | ~13.4 |

The Apple GPU does not have dual-dispatch for F32 and I32, like Nvidia does. F16/I16 arithmetic is not faster than 32-bit counterparts. Not sure whether FMA has 3 or 4-cycle latency. Some bad integer multiply benchmarks had cycle throughputs as multiples of 1/3 (2.00, 2.33, 2.67), but potentially because of a 4-instruction recurring register dependency (4 - 1). Command concurrency benchmarks suggest latency must be divisible by 2; the ALU can pipeline up to 2 FMAs from the same SIMD-group simultaneously. The result is exactly half the peak performance of one GPU core. That would mean 4-cycle latency with 4x concurrency, the same scheme used in Firestorm CPU cores and Nvidia GPUs.

This analysis suggests an ALU has four concurrent pipelines. Each can execute either F32 or I32 math; both data types share the same circuitry. 64-bit integer operations are one instruction in assembly code, but 4-6x slower than 32-bit integer ops. This is similar to the Apple AMX, where 64-bit floats are 4x slower than 32-bit floats because they don't have dedicated circuitry. Also like the AMX, F16 is neither faster nor slower than F32.

## Power Efficiency

TODO: higher occupancy, less threadgroup memory, int64 arithmetic, power varying with clock speed, concurrent command execution

![Graph of power vs. performance for an M1 Max at 1296 MHz](./Documentation/Power_Performance_M1_Max.png)

The M1 Max has 32 GPU cores, but can perform up to 96 compute commands simultaneously. The A15 has double the concurrency, performing 30 commands on 5 GPU cores. In comparison, all Nvidia GPUs top out at 128 concurrent commands. To reach the same concurrency, an Nvidia GPU must have at most 42 SMs. This is true for the RTX 3060, but not for more powerful GPUs. While the concurrency seems excessive for the purpose of multitasking, it has another purpose. Say that one task requires resources from 22 GPU cores, and another requires resources from 11. A naive GPU design would only permit 4 concurrent commands. That would allocate 16 GPU cores to the first task and 8 to the second. Apple's design lets you divide work more finely. However, there's one more usage. The total number of requires GPU cores is 33, but we have 32. The M1 lets you increase the load on GPU cores, so that each core performs 33/32x the work. One of those cores is spliced partially between task 1 and task 2. This becomes more useful on A-series chips with only 3-5 GPU cores, and contributes to their (power) efficiency.

This sub-core concurrency only happens among commands within the same `MTLComputeCommandEncoder`. For commands on different Metal command queues, there's only 2x concurrency across the entire GPU. This makes it similar to early dual-core CPUs, designed in part to be more responsive. Even if a background task is taking several frames, a high-priority UI command can quickly seize half the GPU cores. Beyond that purpose, there's little motive to create any circuitry for 3+ concurrent command queues.

## References

https://github.com/dougallj/applegpu

https://www2.eecs.berkeley.edu/Pubs/TechRpts/2016/EECS-2016-143.pdf

https://rosenzweig.io/blog/asahi-gpu-part-4.html

https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf

https://github.com/AsahiLinux/docs/wiki/HW:AGX

https://arxiv.org/pdf/1804.06826.pdf

https://arxiv.org/pdf/1905.08778.pdf

## US Patents

<details>
 
<summary>List of patents that may reveal unique design characteristics of the Apple GPU</summary>
  
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
