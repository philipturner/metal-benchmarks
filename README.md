# Metal Benchmarks

Test suite to measure microarchitectural details of the M1 GPU. These details include latencies for each ALU assembly instruction, threadgroup memory bandwidth, and the number of unique instruction pipelines. This information will enable evidence-based reasoning about performance on the M1 GPU. This repository also compares the M1 to generations of AMD and Nvidia microarchitectures. <!-- Finally, it examines how Apple's design choices improve power efficiency compared to other vendors. -->

## Layout of an M1 GPU Core

| Statistic (per core) | Apple 7 | GCN 5 | RDNA 2 | RDNA 3 | Turing | Ampere | Lovelace |
| -------------------- | ------- | ----- | ------ | ------ | ------ | ------ | -------- |
| Max Threads | 1152-3072 | 1024-2560 | ???-2048 | ???-2048 |
| FP32 ALUs | 128 | 64 | 64 | 128 | 256 | 256 |
| Register File | 624 KB | 256 KB | 256 KB | 384 KB | - | - |
| Threadgroup Memory | 32 - 96 KB ?? | 64 KB | - | - |
| L1 Instruction Cache | 24 - 32 KB ?? | 32 KB | 32 KB | 32 KB |

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

The Apple GPU not have dual-dispatch for F32 and I32, like Nvidia does. F16/I16 arithmetic is not faster than 32-bit counterparts. Not sure whether FMA has 3 or 4-cycle latency. Some bad integer multiply benchmarks had cycle throughputs as multiples of 1/3 (2.00, 2.33, 2.67), but potentially because of a 4-instruction recurring register dependency (4 - 1). Benchmarks of concurrency suggest latency must be divisible by 2; the ALU can pipeline up to 2 FMAs from the same SIMD-group simultaneously. The result is exactly half the peak performance of one GPU core. That would mean 4-cycle latency with 4x concurrency, the same scheme used in Firestorm CPU cores and Nvidia GPUs.

This suggests an ALU has four concurrent pipelines. Each can execute either F32 or I32 math; both types share the same circuitry. 64-bit integer operations are one instruction in assembly code, but 4x slower than 32-bit integer ops. This is similar to the Apple AMX, where 64-bit floats are 4x slower than 32-bit floats because they don't have dedicated circuitry. Also like the AMX, F16 is neither faster nor slower than F32.

## Power Efficiency

TODO: higher occupancy, less threadgroup memory, int64 arithmetic, power varying with clock speed, concurrent command execution

![Graph of power vs. performance for an M1 Max at 1296 MHz](./Documentation/Power_Performance_M1_Max.png)

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
