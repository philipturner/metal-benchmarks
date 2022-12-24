//
//  MainFile.swift
//  TestMetalConcurrency
//
//  Created by Philip Turner on 12/22/22.
//

import Metal
import simd

func mainFunc() {
  let device = MTLCreateSystemDefaultDevice()!
  let commandQueue = device.makeCommandQueue()!
  let library = device.makeDefaultLibrary()!
  
  // You can achieve parallelism with multiple separate command encoders, with
  // a catch. Each encoder must modify an independent set of resources. The
  // encoder must also be `.concurrent`, even though it's semantically serial.
  // These restrictions cannot be bypassed by disabling Metal hazard tracking.
  // In fact, buffers originating from the same `MTLHeap` will never permit
  // concurrency when using separate command encoders.
  //
  // For M1 Max:
  // It seems that 8192 threads are necessary to achieve peak ALU utilization.
  // Each thread can have two 4-cycle FMAs running concurrently, operating on
  // independent registers. You also need to run the shader for very long,
  // otherwise the GPU will throttle clock speed from 1296 MHz to 389 MHz.
  //
  // Available clock speeds:
  // -   ~0 MHz
  // -  389 MHz (3/10)
  // -  486 MHz (3/8)
  // -  648 MHz (3/6)
  // -  778 MHz (3/5)
  // -  972 MHz (3/4)
  // - 1296 MHz (3/3)
  //
  // According to powermetrics, the GPU has the following usage statistics
  // during a 16 x 1024 dispatch. Note that we're only utilizing ~50% FLOPS.
  // Very large dispatches can reach ~9100 GFLOPS.
  // - 1296 MHz active frequency
  // - 0% GPU idle residency
  // - up to 28 watts
  //
  // It has the following usage statistics during a 1 x 128 dispatch. Note that
  // real-world GPU idle residency should have been ~90%. Perhaps this only
  // measures temporal utilization, and most cores are spatially starved.
  // - 1296 MHz active frequency
  // - 0% GPU idle residency
  // - up to 1.4 watts
  //
  // Any smaller dispatches were ~0.8 watts.
  // For a 2 x 16 dispatch, ~0.9 watts and 44 GFLOPS = 21 W/TFLOPS
  // For a 2 x 32 dispatch, ~1.1 watts and 89 GFLOPS = 12 W/TFLOPS
  // For a 2 x 64 dispatch, ~1.4 watts and 178 GFLOPS = 7.9 W/TFLOPS
  // For a 2 x 128 dispatch, ~2.1 watts and 356 GFLOPS = 5.9 W/TFLOPS
  // For a 2 x 256 dispatch, ~3.8 watts and 713 GFLOPS = 5.3 W/TFLOPS
  // For a 2 x 512 dispatch, ~6.7 watts and 1427 GFLOPS = 4.7 W/TFLOPS
  // For a 2 x 1024 dispatch, ~11 watts and 2395 GFLOPS = 4.6 W/TFLOPS
  // For a 2 x 2048 dispatch, ~17 watts and 3751 GFLOPS = 4.5 W/TFLOPS
  // For a 2 x 4096 dispatch, ~30 watts and 6550 GFLOPS = 4.6 W/TFLOPS
  // For a 2 x 8192 dispatch, ~35 watts and 7003 GFLOPS = 5.0 W/TFLOPS
  // For a 2 x 16384 dispatch, ~40 watts and 7930 GFLOPS = 5.0 W/TFLOPS
  // For a 2 x 32768 dispatch, ~42 watts and 8146 GFLOPS = 5.2 W/TFLOPS
  // For a 2 x 65536 dispatch, ~44 watts and 8265 GFLOPS = 5.3 W/TFLOPS
  // For a 2 x 131072 dispatch, ~46 watts and 9156 GFLOPS = 5.0 W/TFLOPS
  // All measurements appear to be @ 1296 MHz, but lower clock speeds could
  // decrease power at equi-performance.
  //
  // For A15:
  // This chip will test whether maximum concurrency relates to the number of
  // GPU cores. It has 5 cores, while the M1 Max has 32.
  //
  // Potentially useful for power profiling:
  // https://developer.apple.com/forums/thread/91160
  // Not going to profile power ATM because it seems non-straightforward to
  // implement.
  //
  // Max clock speed: 1335 - 1340 MHz
  // Not sure this extrapolation is accurate, because the A15 would have 1708
  // GFLOPS (very large). However, it does align with MPSMatrixMultiplication
  // being max ~1200-1300 GFLOPS.
  //
  // If a command buffer takes >250 ms, the A15 will abort it. This is a
  // feature exclusive to iOS. I have never seen a command buffer aborted on
  // macOS for "hanging", although some ~100,000-thread benchmarks on the M1 Max
  // were aborted at random.
  //
  // M1 Max, 197 transforms, 32 threads, max GFLOPS based on tgmem allocation
  // 20 KB - 2816
  // 17 KB - 2812
  // 16 KB - 2829
  // 14 KB - 2872
  // 12 KB - 2834
  // 10 KB - 2875
  //  4 KB - 2851
  
  // Testing behavior of registers, threadgroup size, and occupancy. From
  // Rozenweig's blog, assume register bank size is 8 x 16 bit in thread-space.
  // That means 16 bytes in thread-space and 512 bytes in simd-space. My small
  // kernels should round to 80-96 bytes (thread-space) and 2560-3072 bytes
  // (simd-space). The data below should help determine the register bank
  // stride, and maybe validate register file size.
  //
  // Helpful resource:
  // https://research.nvidia.com/sites/default/files/pubs/2012-12_Unifying-Primary-Cache/Gebhart_MICRO_2012.pdf
  //
  // A15: 15 transforms
  // 690: 1, 2, 4, 8, 12, 20, 24, 28
  // 480: 16
  // 380: 30, 32
  // Max active threads underestimate: 3x28x32 = 2688
  //
  // A15: 20 transforms, 32 active threads, GFLOPS w.r.t. simds/threadgroup
  // 880: 1-5, 8, 10-13, 15, 17-20
  // 650: 6, 14
  // 540: 7, 9, 16
  // 21 - 510
  // 22 - 525
  // 23 - 483
  // 24 - 523
  // 25 - 483
  // 26 - 528
  // 27 - 521
  // 28 - 486
  // 29 - 528
  // 30 - 493
  // 31 - 490
  // 32 - 481
  // Max active threads underestimate: 4x20x32 = 2560
  // Register file underestimate: 4x20x32 threads, 80 bytes = 200 KB
  // Register file underestimate: 4x20x32 threads, 96 bytes = 240 KB
  // Drops off @ 30-32 simds.
  // - redone with the matrix in device memory instead of constant
  // 760: 1, 2, 4, 8, 10, 12, 13
  // 520: 20, 24, 26, 29
  // 440: 14, 18, 22
  // 380: 16, 28, 30, 32
  // 300: 25, 27
  // Register file underestimate: 4x13x32 threads, 144 bytes = 234 KB
  // Register file underestimate: 4x13x32 threads, 160 bytes = 260 KB
  // Register file underestimate: 2x29x32 threads, 144 bytes = 261 KB
  // Register file underestimate: 2x29x32 threads, 160 bytes = 290 KB
  // - redone with two transforms in registers
  //  1 - 772
  //  2 - 774
  //  4 - 802
  //  8 - 784
  //  9 - 415
  // 10 - 517
  // 11 - 463
  // 12 - 471
  // 13 - 513
  // 14 - 402
  // 15 - 328
  // 16 - 407
  // 17 - 351
  // 18 - 390
  // 19 - 350
  // 20 - 323
  // 21 - 324
  // 22 - 329
  // 23 - 400
  // 24 - 349
  // 25 - 377
  // 26 - 352
  // 27 - 395
  // 28 - 259
  // Register file underestimate:  4x8x32 threads, 208 bytes = 204 KB
  // Register file underestimate:  4x8x32 threads, 224 bytes = 224 KB
  // Register file close estimate: 2x27x32 threads, 208 bytes = 351 KB
  // Register file close estimate: 2x27x32 threads, 224 bytes = 378 KB
  // Register file overestimate:   2x28x32 threads, 224 bytes = 392 KB
  
  let numTransforms = 20
  let baseNumThreads = 32
  let tgmemPerSimdgroup = 1024
  let simdsPerThreadgroup = 28
  
  let usingSerial = false
  
  //
  // M1 Max: 32 transforms, 32 active threads, GFLOPS w.r.t. simds/threadgroup
  // 1660: all tested combinations (1, 11, 32)
  // - redone with the matrix in device memory instead of constant
  // 1640: all tested combinations (1, 11, 32)
  // - redone with two transforms in registers
  // 1650: all tested combinations (1, 11, 28)
  //
  // M1 Max: 64 transforms, 32 active threads, GFLOPS w.r.t. simds/threadgroup
  // 3320: 1, 3, 4, 6, 8, 10, 13, 15, 17, 19, 20, 22, 24, 26, 29, 31
  // 2900: 2, 5, 7, 9, 11, 12, 14, 16, 18, 21, 23, 25, 27, 28, 30, 32
  // - redone with the matrix in device memory instead of constant
  // 3300: 1, 3, 4, 6 ... 31
  // 2350: 2 ... 7 ... 30, 32
  // - redone with two transforms in registers
  // 3250: 1, 3, 4, 6, 8 ... 26
  // 2400: 2, 5, 7, 9 ... 25, 27
  // 1600: 28
  //
  // M1 Max: 96 transforms, 32 active threads, GFLOPS w.r.t. simds/threadgroup
  // ~4300: 1-6, 8, 10-13, 15, 17-22, 24, 26-28
  // ~3020: 7, 9, 14, 16, 23, 25
  // ~2400: 29-32
  // Max active threads underestimate: 3x28x32 = 2688
  // Register file underestimate: 3x28x32 threads, 80 bytes = 210 KB
  // Register file underestimate: 3x28x32 threads, 96 bytes = 252 KB
  // - redone with the matrix in device memory instead of constant
  // ~3400: 1-6, 8, 10-13, 15, 17-19
  // ~2400: 20, 22, 24, 26, 29, 31
  // ~2250: 7, 9, 14, 16
  // ~2100: 21, 23, 27-28, 30
  // ~2000: 25, 32
  // Register file underestimate: 3x19x32 threads, 144 bytes = 256.5 KB
  // Register file underestimate: 3x19x32 threads, 160 bytes = 285 KB
  // - redone with two transforms in registers
  // ~3600: 1-6, 8, 10-13
  // ~2400: 7, 15, 17, 19, 20, 22, 24, 26
  // ~2300: 9
  // ~2200: 18
  // ~2100: 14, 16, 21, 23, 25, 27
  // ~1600: 28
  // Register file underestimate: 3x13x32 threads, 208 bytes = 253.5 KB
  // Register file underestimate: 3x13x32 threads, 224 bytes = 273 KB
  // Register file underestimate: 2x26x32 threads, 208 bytes = 338 KB
  // Register file underestimate: 2x26x32 threads, 224 bytes = 364 KB
  // Register file overestimate:  2x28x32 threads, 224 bytes = 392 KB
  //
  // M1 Max: 128 transforms, 32 active threads, GFLOPS w.r.t. simds/threadgroup
  // ~3250: 1-4, 6, 8, 10, 13, 17-20
  // ~3170: 24, 26, 29
  // ~3100: 5, 12, 15, 21-22
  // ~3000: 7, 9, 11, 14, 25, 27-28
  // ~2650: 16, 23
  // ~2200: 30-32
  // Max active threads underestimate: 4x20x32 = 2560
  // Register file underestimate: 4x20x32 threads, 80 bytes = 200 KB
  // Register file underestimate: 4x20x32 threads, 96 bytes = 240 KB
  // Like with 96 transforms, this also drops off @ 29-30 simds.
  // - redone with two transforms in registers
  //  1 - 3207
  //  2 - 3242
  //  3 - 3213
  //  4 - 3204
  //  5 - 3199
  //  6 - 3214
  //  7 - 2414
  //  8 - 3195
  //  9 - 2459
  // 10 - 3192
  // 11 - 2429
  // 12 - 2601
  // 13 - 3193
  // 14 - 1844
  // 15 - 2185
  // 16 - 2003
  // 17 - 2394
  // 18 - 2118
  // 19 - 2362
  // 20 - 2637
  // 21 - 2101
  // 22 - 2530
  // 23 - 2076
  // 24 - 2708/3039*
  // 25 - 2230
  // 26 - 2169
  // 27 - 2393
  // 28 - 1608
  // Register file underestimate:  4x13x32 threads, 208 bytes = 338 KB
  // Register file underestimate:  4x13x32 threads, 224 bytes = 364 KB
  // Register file close estimate: 2x27x32 threads, 208 bytes = 351 KB
  // Register file close estimate: 2x27x32 threads, 224 bytes = 378 KB
  // Register file overestimate:   2x28x32 threads, 224 bytes = 392 KB
  //
  // *These two data points appear to be outliers. Perhaps the ALU was more
  // efficient at dispatching instructions, because we do have room for
  // improvement. Even with 2 simds/core, we could reach 5308 GFLOPS.
  
  // Number of concurrent commands - (GFLOPS - seconds) M1 Max, A15
  
  // 16 threads/command
  // 32 -  712 - 0.0920
  // 64 - 1394 - 0.0940
  // 80 - 1502 - 0.1090
  // 96 - 1803 - 0.1090
  //112 - 1224 - 0.1874
  
  // 32 threads/command
  //  1 -   44 - 0.0918,   46 - 0.0890
  //  2 -   89 - 0.0918,   92 - 0.0889
  //  3 -                 138 - 0.0889
  //  4 -  178 - 0.0918,  184 - 0.0890
  //  5 -                 230 - 0.0890
  //  6 -                 276 - 0.0890
  //  8 -  356 - 0.0918,  368 - 0.0890
  // 10 -                 460 - 0.0890, never jumps from tgmem allocation
  // 12 -                 500 - 0.0983, jumps when tgmem/simdgroup exceeds 20 KB
  // 14 -                 572 - 0.1003
  // 15 -                 589 - 0.1042, jumps when tgmem/simdgroup exceeds 20 KB
  // 16 -  713 - 0.0918,  615 - 0.1065, jumps when tgmem/simdgroup exceeds 16 KB
  // 20 -                 801 - 0.1022, jumps when tgmem/simdgroup exceeds 16 KB
  // 21 -                 603 - 0.1425, jumps when tgmem/simdgroup exceeds 12 KB
  // 24 -                 689 - 0.1426
  // 25 -                 714 - 0.1434, jumps when tgmem/simdgroup exceeds 12 KB, 20 KB
  // 30 -                 825 - 0.1488, jumps when tgmem/simdgroup exceeds 10 KB, 12 KB, 20 KB
  // 31 -                 722 - 0.1756, jumps when tgmem/simdgroup exceeds 8 KB, 16 KB, 20 KB
  // 32 - 1427 - 0.0918,  737 - 0.1777
  // 40                                 jumps when tgmem/simdgroup exceeds 8 KB
  // 41                                 jumps when tgmem/simdgroup exceeds 6 KB, 12 KB
  // 48 - 2107 - 0.0933
  // 64 - 2827 - 0.0927, never jumps from tgmem allocation
  // 65 - 2641 - 0.1008, jumps when tgmem/simdgroup exceeds 20 KB
  // 66 - 2620 - 0.1032
  // 67 - 2641 - 0.1039
  // 68 - 2642 - 0.1054
  // 71 - 2687 - 0.1082
  // 72 - 2694 - 0.1094
  // 80 - 2946 - 0.1112
  // 96 - 3568 - 0.1102, jumps when tgmem/simdgroup exceeds 20 KB
  // 97 - 2146 - 0.1851, jumps when tgmem/simdgroup exceeds 24 KB
  // 98 - 2173 - 0.1847
  //100 - 2208 - 0.1855, jumps when tgmem/simdgroup exceeds 24 KB
  //108 - 2208 - 0.1855, jumps when tgmem/simdgroup exceeds 24 KB
  //109 - 2208 - 0.1855, jumps when tgmem/simdgroup exceeds 24 KB
  //112 - 2458 - 0.1866, jumps when tgmem/simdgroup exceeds 24 KB
  //114 -       (barely) jumps when tgmem/simdgroup exceeds 24 KB
  //115 -       (barely) jumps when tgmem/simdgroup exceeds 20 KB
  //128 -       (barely) jumps when tgmem/simdgroup exceeds 20 KB
  //196 -       (barely) jumps when tgmem/simdgroup exceeds 20 KB
  //197 -       (barely) jumps when tgmem/simdgroup exceeds 16 KB
  //256 -       (barely) jumps when tgmem/simdgroup exceeds 16 KB
  
  // 64 threads/command
  //  1 -   89 - 0.0918,
  //  2 -  178 - 0.0918,
  //  4 -  356 - 0.0918,
  //  8 -  713 - 0.0918
  // 16 - 1426 - 0.0919
  // 32 - 2825 - 0.0928
  // 48 - 3609 - 0.1090
  // 64 - 4872 - 0.1076
  // 80 - 4389 - 0.1493
  // 96 - 4921 - 0.1598
  
  // 128 threads/command
  //  1 -  178 - 0.0918,  184 - 0.0890
  //  2 -  356 - 0.0918,  362 - 0.0904
  //  3 -                 506 - 0.0971
  //  4 -  713 - 0.0919,  669 - 0.0979
  //  5 -                 604 - 0.1355
  //  6 -                 726 - 0.1353
  //  7 -                 770 - 0.1488
  //  8 - 1427 - 0.0918,  765 - 0.1712
  //  9 -                 822 - 0.1793
  // 10 -                 870 - 0.1881
  // 11 -                 831 - 0.2167
  // 12 - 2190 - 0.0918,  842 - 0.2333
  // 16 - 2843 - 0.0922
  // 18 - 2695 - 0.1094
  // 24 - 3600 - 0.1092
  // 32 - 4876 - 0.1075
  // 36 - 4009 - 0.1471
  // 48 - 5054 - 0.1556
  
  // 256 threads/command
  //  1 -  356 - 0.0918,  368 - 0.0890
  //  2 -  713 - 0.0918,  637 - 0.1027
  //  3
  //  4 - 1424 - 0.0920,  759 - 0.1726
  //  5 -                 874 - 0.1874
  //  6 -                 844 - 0.2329
  //  8 - 2791 - 0.0939
  // 16 - 4537 - 0.1156
  
  // 512 threads/command
  //  1 -  713 - 0.0918,  724 - 0.0904
  //  2 - 1427 - 0.0918,  855 - 0.1533
  //  3 -                1012 - 0.1942
  //  4 - 2552 - 0.1027
  //  8 - 4692 - 0.1117
  // 16 - 4676 - 0.2242
  
  // 1024 threads/command
  //  1 - 1427 - 0.0918,  834 - 0.1571
  //  2 - 2466 - 0.1063, 1162 - 0.2256
  //  4 - 4954 - 0.1058
  //  8 - 4540 - 0.2309
  // 16 - 4935 - 0.4249
  
  // 2048 threads/command
  //  1 - 2854 - 0.0918, 1207 - 0.2172
  //  2 - 3752 - 0.1397
  //  4 - 4317 - 0.2429
  //  8 - 4723 - 0.4439
  // 16 - 4730 - 0.8866
  
  // 4096 threads/command
  //  1 - 5614 - 0.0934
  //  2 - 6531 - 0.1605
  //  4 - 6061 - 0.3460
  //  8 - 5934 - 0.7067
  // 16 - 6018 - 1.3939
  
  // Create all the pipelines we'll use
  let numIterations = 1_000_000
  let constants = MTLFunctionConstantValues()
  var pipelines: [MTLComputePipelineState] = []
  do {
    var _numIterations = Int32(numIterations)
    constants.setConstantValue(&_numIterations, type: .int, index: 0)
    
    var maxThreadgroupSize: Int?
    for transformIndex in 0..<numTransforms {
      var _transformIndex = Int32(transformIndex)
      constants.setConstantValue(&_transformIndex, type: .int, index: 1)
      
      let name = "testThroughput\((transformIndex % 32) + 1)"
      let function = try! library
        .makeFunction(name: name, constantValues: constants)
      let pipeline = try! device
        .makeComputePipelineState(function: function)
      pipelines.append(pipeline)
      if let maxThreadgroupSize = maxThreadgroupSize {
        precondition(pipeline.maxTotalThreadsPerThreadgroup == maxThreadgroupSize)
      } else {
        if pipeline.maxTotalThreadsPerThreadgroup != 1024 {
          print("Max Threads/Threadgroup: \(pipeline.maxTotalThreadsPerThreadgroup)")
        }
        maxThreadgroupSize = pipeline.maxTotalThreadsPerThreadgroup
      }
    }
  }
  
  // Create all the buffers we'll use
  let numThreads = baseNumThreads * numTransforms
  func makeBuffers(size: Int) -> [MTLBuffer] {
    let bufferSize = size * MemoryLayout<simd_float4x4>.stride
//    let heapDesc = MTLHeapDescriptor()
//    heapDesc.hazardTrackingMode = .untracked
//    heapDesc.storageMode = .private
//    heapDesc.size = bufferSize * numTransforms * 3 / 2
//    let heap = device.makeHeap(descriptor: heapDesc)!
    
    var output: [MTLBuffer] = []
    for _ in 0..<numTransforms {
      let buffer = device.makeBuffer(
        length: bufferSize, options: [.storageModePrivate, .hazardTrackingModeUntracked])!
      precondition(buffer.hazardTrackingMode == .untracked)
      output.append(buffer)
    }
    return output
  }
  let inputBuffers: [MTLBuffer] = makeBuffers(size: numThreads)
  let transformBuffers: [MTLBuffer] = makeBuffers(size: numTransforms * 2)
  let outputBuffers: [MTLBuffer] = makeBuffers(size: numThreads)
  
  var outputFLOPS: Double = 0
  var outputTime: Double = .infinity
  for _ in 0..<5 {
    // Make a serial encoder for now, just to validate ~90% FLOPS.
    let numCommands = numTransforms
    let commandBuffer = commandQueue.makeCommandBuffer()!
    var encoder: MTLComputeCommandEncoder!
    if !usingSerial {
      encoder = commandBuffer
        .makeComputeCommandEncoder(
          dispatchType: .concurrent)!
    }
    
    var totalThreadsDispatched = 0
    for commandIndex in 0..<numCommands {
      if usingSerial {
        encoder = commandBuffer
          .makeComputeCommandEncoder(
            dispatchType: .concurrent)!
      }
      encoder.setComputePipelineState(pipelines[commandIndex])
      let threadsStart = (numThreads * commandIndex) / numCommands
      let threadsEnd = (numThreads * (commandIndex + 1)) / numCommands
      let dispatchSize = threadsEnd - threadsStart
      totalThreadsDispatched += dispatchSize
      
      let bufferIndex = usingSerial ? commandIndex : 0
      let bufferOffset = threadsStart * MemoryLayout<simd_float4x4>.stride
      encoder.setBuffer(inputBuffers[bufferIndex], offset: bufferOffset, index: 0)
      encoder.setBuffer(transformBuffers[bufferIndex], offset: 0, index: 1)
      encoder.setBuffer(outputBuffers[bufferIndex], offset: bufferOffset, index: 2)
      encoder.setThreadgroupMemoryLength(tgmemPerSimdgroup, index: 0)
      encoder.dispatchThreads(
        MTLSizeMake(dispatchSize * simdsPerThreadgroup, 1, 1),
        threadsPerThreadgroup: MTLSizeMake(32 * simdsPerThreadgroup, 1, 1))
      if usingSerial {
        encoder.endEncoding()
      }
    }
    precondition(totalThreadsDispatched == numThreads)
    if !usingSerial {
      encoder.endEncoding()
    }
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    
    if commandBuffer.error != nil {
      // Very large dispatches cause errors for some reason.
      continue
    }
    
    let numFLOPs = numThreads * numIterations * 2 * 64
    let executionTime = commandBuffer.gpuEndTime - commandBuffer.gpuStartTime
    let numFLOPS = Double(numFLOPs) / executionTime
    outputFLOPS = max(outputFLOPS, numFLOPS)
    outputTime = min(outputTime, executionTime)
  }
  print(Int(outputFLOPS / 1e9), outputTime)
}
