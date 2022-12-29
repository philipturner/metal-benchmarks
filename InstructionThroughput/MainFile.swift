//
//  MainFile.swift
//  BenchInstructionCache
//
//  Created by Philip Turner on 12/24/22.
//

import Metal
import QuartzCore

struct Processor {
  var cores: Int
  var frequency: Int
  var GOPS: Int {
    (cores * 128 * frequency) / 1000
  }
  
  static let M1Max = Processor(cores: 32, frequency: 1296)
  static let A15 = Processor(cores: 5, frequency: 1336)
  static let A14 = Processor(cores: 4, frequency: 1278)
}

func mainFunc() {
  let is32Bit = true
  let residentThreadgroupsRange = 2...8
  
  // Constants to initialize the shader.
  let processor: Processor = .M1Max
  let numCores = processor.cores
  let overSubscription = 250
  let numTrials = 3
  let theoreticalGOPS = processor.GOPS
  
  // Specify amount of work done.
  let numInstructions = 720 * 1/2 + 120 * 0 + 24 * 0
  
  var configs: [Int: (simdsPerThreadgroup: Int, threadgroupMemory: Int)]
  if is32Bit {
    // FADD32 configs
    configs = [
//      1 : (32, 32 * 1024), // 11 (30 simds)
      2 : (23, 31 * 1024), // 19 (46 simds)
      3 : (15, 20 * 1024), // 28 (45 simds)
      4 : (11, 16 * 1024), // 36 (44 simds)
      5 : ( 9, 12 * 1024), // 41 (45 simds)
      6 : ( 8, 12 * 1024), // 44 (48 simds)
//      7 : ( 6,  8 * 1024), // 53 (42 simds)
      8 : ( 4,  8 * 1024), // 62 (32 simds)
    ]
  } else {
    // FADD16 configs
    configs = [
//      2 : (32, 32 * 1024), // 19 (62 simds)
      2 : (31, 31 * 1024), // 22 (62 simds)
      3 : (27, 20 * 1024), // 31 (81 simds)
      4 : (20, 16 * 1024), // 42 (80 simds)
      5 : (16, 10 * 1024), // 53 (80 simds)
      6 : ( 8, 10 * 1024), // 64 (48 simds)
//      7 : (10,  8 * 1024), // 67 (70 simds)
      8 : ( 8,  8 * 1024), // 76 (64 simds)
    ]
  }
  
  // Initialize resources.
  let benchmarkStart = CACurrentMediaTime()
  let device = MTLCreateSystemDefaultDevice()!
  let commandQueue = device.makeCommandQueue()!
  
  let library = device.makeDefaultLibrary()!
  let function = library.makeFunction(name: "testCache")!
  let pipeline = try! device.makeComputePipelineState(function: function)
  let maxSimdsPerThreadgroup = pipeline.maxTotalThreadsPerThreadgroup / 32
  if maxSimdsPerThreadgroup < 32 {
    print("Overallocated registers: \(maxSimdsPerThreadgroup) simds \(pipeline.maxTotalThreadsPerThreadgroup)")
  }
  
  let inputsBuffer = device.makeBuffer(length: 1024 * 1024)!
  let outputsBuffer = device.makeBuffer(length: 1024 * 1024)!
  
  // Sampled measurements in GFLOPS.
  var allSamples: [Int: Double] = [:]
  for _ in 0..<numTrials {
    for residentThreadgroups in residentThreadgroupsRange {
      guard let config = configs[residentThreadgroups] else {
        continue
      }
      let simdsPerThreadgroup = min(
        maxSimdsPerThreadgroup, config.simdsPerThreadgroup)
      let maxActiveSimdgroupsRange: [Int] = (1...simdsPerThreadgroup).map { $0 }
      let numThreadgroups = numCores * residentThreadgroups * overSubscription
      
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
          let numOPs = numThreads * numInstructions
          
          let numGOPS = Double(numOPs) / time / 1e9
          let opsPerCycle = Double(theoreticalGOPS) / numGOPS
          let occupancy = residentThreadgroups * activeSimdgroups
          
          if let previousSample = allSamples[occupancy] {
            allSamples[occupancy] = max(opsPerCycle, previousSample)
          } else {
            allSamples[occupancy] = opsPerCycle
          }
        }
      }
      
      let indicesList = maxActiveSimdgroupsRange.indices.shuffled()
      for i in indicesList {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(inputsBuffer, offset: 0, index: 0)
        encoder.setBuffer(outputsBuffer, offset: 0, index: 1)
        encoder.setThreadgroupMemoryLength(configs[residentThreadgroups]!.threadgroupMemory, index:  0)
        
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
  }
  
  // Display each trial's results, then the maximum.
  print("Occupancy Benchmark")
  let allowedKeys = [
    2, 3, 4, 5, 6, 8, 10,
    12, 15, 16, 18, 20,
    24, 30, 32, 36, 40, 48, 56, 64, 72
  ]
  for key in allSamples.keys.sorted() where allowedKeys.contains(key) {
    // TODO: Blacklist certain highly prime numbers.
    let sample = allSamples[key]!
    var line = String()
    line.append(alignInteger(key, length: 2))
    line.append(" -> ")
    line.append(String(format: "%.2f", sample))
//    line.append(alignInteger(sample, length: 4))
    print(line)
  }
//  for i in maxActiveSimdgroupsRange.indices {
//    let activeSimdgroups = maxActiveSimdgroupsRange[i]
//    let occupancy = residentThreadgroups * activeSimdgroups
//    var line = "\(alignInteger(occupancy, length: 2)): "
//
//    var maxMeasurement: Int = 0
//    for j in 0..<numTrials {
//      let measurement = allSamples[j][i]
//      maxMeasurement = max(maxMeasurement, measurement)
//
//      line.append(alignInteger(measurement, length: 5))
//      if j < numTrials - 1 {
//        line.append(", ")
//      }
//    }
//
//    line.append(" -> ")
////    line.append(alignInteger(maxMeasurement, length: 5))
//    line.append(String(
//      format: "%.0f", 128 / (Double(theoreticalGOPS) / Double(maxMeasurement))))
//    print(line)
//  }
  
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
