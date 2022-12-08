# Metal Benchmarks

Black-box test suite to measure microarchitectural details of the M1 GPU. These details include latencies for each ALU assembly instruction, threadgroup memory bandwidth, and the number of unique instruction pipelines. This information will enable evidence-based reasoning about performance on the M1 GPU. This repository also compares the M1 to generations of AMD and Nvidia microarchitectures. Finally, it examines how Apple's design choices improve power efficiency compared to other vendors.

Eventually, I would like to make a simulator for an M1 GPU core. This would enable comparing predicted to actual performance patterns, and refining our understanding of the M1 GPU accordingly.

## Layout of an M1 GPU Core

TODO: register file, threadgroup memory, arithmetic subunits, occupancy, L1 cache

## Power Efficiency

TODO: higher occupancy, less threadgroup memory, int64 arithmetic, power varying with clock speed, concurrent command execution

## References

https://github.com/dougallj/applegpu

https://www2.eecs.berkeley.edu/Pubs/TechRpts/2016/EECS-2016-143.pdf

https://rosenzweig.io/blog/asahi-gpu-part-4.html

https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf

https://github.com/AsahiLinux/docs/wiki/HW:AGX
