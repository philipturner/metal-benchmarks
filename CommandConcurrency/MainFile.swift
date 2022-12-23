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
  // GPU cores. It has 5 cores, while the M1 Max has 32. The benchmark only
  // generates 16 unique pipeline states.
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
  
  let numTransforms = 1
  let baseNumThreads = 128
  let usingSerial = false
  
  // Number of concurrent commands - (GFLOPS - seconds) M1 Max, A15
  
  // 128 threads/command
  //  1 -  178 - 0.0918,  184 - 0.0890
  //  2 -  356 - 0.0918,  362 - 0.0904
  //  4 -  713 - 0.0919,  656 - 0.0998
  //  8 - 1427 - 0.0918,  765 - 0.1712
  // 10 -                 870 - 0.1881
  // 12 -                 842 - 0.2333
  // 16 - 2843 - 0.0922
  
  // 256 threads/command
  //  1 -  356 - 0.0918,  368 - 0.0890
  //  2 -  713 - 0.0918,  637 - 0.1027
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
  let numIterations = 1000000
  let constants = MTLFunctionConstantValues()
  var pipelines: [MTLComputePipelineState] = []
  do {
    var _numIterations = Int32(numIterations)
    constants.setConstantValue(&_numIterations, type: .int, index: 0)
    
    for transformIndex in 0..<numTransforms {
      var _transformIndex = Int32(transformIndex)
      constants.setConstantValue(&_transformIndex, type: .int, index: 1)
      
      let name = "testThroughput\(transformIndex + 1)"
      let function = try! library
        .makeFunction(name: name, constantValues: constants)
      let pipeline = try! device
        .makeComputePipelineState(function: function)
      pipelines.append(pipeline)
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
  let transformBuffers: [MTLBuffer] = makeBuffers(size: numTransforms)
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
      encoder.dispatchThreads(
        MTLSizeMake(dispatchSize, 1, 1),
        threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
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
