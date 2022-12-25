//
//  MainFile.swift
//  BenchInstructionCache
//
//  Created by Philip Turner on 12/24/22.
//

import Metal
import QuartzCore

func mainFunc() {
  // Constants to initialize the shader.
  let simdsPerThreadgroup = 22
  let maxActiveSimdgroupsRange: [Int] = (1...simdsPerThreadgroup).map { $0 }
  let numCores = 32
  let residentThreadgroups = 4
  let overSubscription = 100
  let numThreadgroups = numCores * residentThreadgroups * overSubscription
  let numTrials = 3
  
  // What about half precision with configuration 6? or 0?
  
  let numInstructions = 720 * 2 + 120 * 0 + 24 * 0 // 120 * 2
  let isFMA = false
  let threadFLOPs = isFMA ? numInstructions * 2 : numInstructions
  
  let benchmarkStart = CACurrentMediaTime()
  let device = MTLCreateSystemDefaultDevice()!
  let commandQueue = device.makeCommandQueue()!
  
  let library = device.makeDefaultLibrary()!
  let function = library.makeFunction(name: "testCache")!
  let pipeline = try! device.makeComputePipelineState(function: function)
  
  let inputsBuffer = device.makeBuffer(length: 1024 * 1024)!
  let outputsBuffer = device.makeBuffer(length: 1024 * 1024)!
  
  // Sampled measurements in GFLOPS.
  var allSamples: [[Int]] = []
  for _ in 0..<numTrials {
    // Must be ordered in the non-randomized order.
    var commandBuffers: [MTLCommandBuffer?] = .init(
      repeating: nil, count: maxActiveSimdgroupsRange.count)
    defer {
      var thisSamples: [Int] = []
      for i in commandBuffers.indices {
        let commandBuffer = commandBuffers[i]!
        commandBuffer.waitUntilCompleted()
        
        let time = commandBuffer.gpuEndTime - commandBuffer.gpuStartTime
        let activeSimdgroups = maxActiveSimdgroupsRange[i]
        let numThreads = 32 * activeSimdgroups * numThreadgroups
        let numFLOPs = numThreads * threadFLOPs
        
        let numFLOPS = Double(numFLOPs) / time
        thisSamples.append(Int(numFLOPS / 1e9))
      }
      allSamples.append(thisSamples)
    }
    
    let indicesList = maxActiveSimdgroupsRange.indices.shuffled()
    for i in indicesList {
      let commandBuffer = commandQueue.makeCommandBuffer()!
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(pipeline)
      encoder.setBuffer(inputsBuffer, offset: 0, index: 0)
      encoder.setBuffer(outputsBuffer, offset: 0, index: 1)
      
      var activeSimdgroups = maxActiveSimdgroupsRange[i]
      encoder.setBytes(&activeSimdgroups, length: 2, index: 2)
      encoder.dispatchThreadgroups(
        MTLSizeMake(numThreadgroups, 1, 1),
        threadsPerThreadgroup: MTLSizeMake(simdsPerThreadgroup * 32, 1, 1))
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffers[i] = commandBuffer
    }
  }
  
  // Display each trial's results, then the maximum.
  print("Occupancy Benchmark")
  for i in maxActiveSimdgroupsRange.indices {
    let activeSimdgroups = maxActiveSimdgroupsRange[i]
    let occupancy = residentThreadgroups * activeSimdgroups
    var line = "\(alignInteger(occupancy, length: 2)): "
    
    var maxMeasurement: Int = 0
    for j in 0..<numTrials {
      let measurement = allSamples[j][i]
      maxMeasurement = max(maxMeasurement, measurement)
      
      line.append(alignInteger(measurement, length: 5))
      if j < numTrials - 1 {
        line.append(", ")
      }
    }
    
    line.append(" -> ")
    line.append(alignInteger(maxMeasurement, length: 5))
    print(line)
  }
  
  // Display time taken to profile.
  let benchmarkEnd = CACurrentMediaTime()
  print("Total time taken: \(benchmarkEnd - benchmarkStart)")
}

func alignInteger(_ x: Int, length: Int) -> String {
  let desc = String(describing: x)
  let remainingSpaces = max(0, length - desc.count)
  let spaces = String(repeating: " ", count: remainingSpaces)
  return spaces + desc
}
