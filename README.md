# Metal Benchmarks

Test suite to measure microarchitectural details of the M1 GPU. These details include latencies for each ALU assembly instruction, threadgroup memory bandwidth, and the number of unique instruction pipelines. This information will enable evidence-based reasoning about performance on the M1 GPU. This repository also compares the M1 to generations of AMD and Nvidia microarchitectures. <!-- Finally, it examines how Apple's design choices improve power efficiency compared to other vendors. -->

<!-- Eventually, I would like to make a simulator for an M1 GPU core. This would enable comparing predicted to actual performance patterns, and refining my understanding of the M1 GPU accordingly. -->

## Layout of an M1 GPU Core

TODO: register file, threadgroup memory, arithmetic subunits, occupancy, L1 cache

<!-- ## Power Efficiency

TODO: higher occupancy, less threadgroup memory, int64 arithmetic, power varying with clock speed, concurrent command execution -->

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
