import XCTest

final class MetalFloat64Tests: XCTestCase {
  func testResourcesExist() throws {
    _ = fetchPath(forResource: "README", ofType: "md")
    _ = fetchPath(forResource: "libMetalFloat64", ofType: "metallib")
    _ = fetchPath(forResource: "Tests", ofType: "metallib")
  }
  
  func testFullScreenColor() throws {
    // Allocate input buffer
    let device = Context.global.device
    let inputBuffer = device.makeBuffer(length: 16)!
    let inputContents = inputBuffer.contents()
      .assumingMemoryBound(to: SIMD4<Float>.self)
    
    // Initialize input buffer
    inputContents[0] = [1, 2, 3, 4]
    
    Context.global.withComputeEncoder { encoder in
      let pipeline = Context.global.pipelines["testFullScreenColor"]!
      encoder.setComputePipelineState(pipeline)
      
      let unusedBuffer = device.makeBuffer(length: 16)
      encoder.setBuffer(unusedBuffer, offset: 0, index: 0)
      encoder.setBuffer(inputBuffer, offset: 0, index: 1)
      encoder.dispatchThreads(
        MTLSizeMake(1, 1, 1),
        threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    }
    
    // Check input buffer
    XCTAssertEqual(inputContents[0], [1, 2, 3, 0])
  }
  
  func testCallStackOverflow() throws {
    // Allocate input buffer
    let numThreads = 1_000
    let device = Context.global.device
    let inputBuffer = device.makeBuffer(length: numThreads * 16)!
    let inputContents = inputBuffer.contents()
      .assumingMemoryBound(to: SIMD4<Float>.self)
    
    // Initialize input buffer
    for i in 0..<numThreads {
      inputContents[i] = SIMD4<Float>(1, 2, 3, 4) + Float(i)
    }
    
    Context.global.withComputeEncoder { encoder in
      let pipeline = Context.global.pipelines["testCallStackOverFlow"]!
      encoder.setComputePipelineState(pipeline)
      
      let flags: [UInt32] = [1, 1, 2, 3, 1, 0]
      encoder.setBytes(flags, length: flags.count * 4, index: 0)
      encoder.setBuffer(inputBuffer, offset: 0, index: 1)
      encoder.dispatchThreads(
        MTLSizeMake(numThreads, 1, 1),
        threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    }
    
    // Check input buffer
    for i in 0..<numThreads {
      let original = SIMD4<Float>(1, 2, 3, 4) + Float(i)
      let expected = original * original
      XCTAssertEqual(inputContents[i], expected)
    }
  }
  
  func testFunctionCallOverhead() throws {
    // Allocate input/output buffer.
    let numInputs = 4_000
    let numThreads = 100_000
    let opsMultiplier = 8
    let inputBufferSize = numInputs * MemoryLayout<Int32>.stride
    let outputBufferSize = numThreads * MemoryLayout<Int32>.stride
    
    let device = Context.global.device
    let inputBuffer = device.makeBuffer(length: inputBufferSize)!
    let outputBuffer = device.makeBuffer(length: outputBufferSize)!
    let inputContents = inputBuffer.contents()
      .assumingMemoryBound(to: Int32.self)
    let outputContents = outputBuffer.contents()
      .assumingMemoryBound(to: Int32.self)
    
    // Ensure output is zero-initialized
    memset(outputContents, 0, outputBufferSize)
    
    for i in 0..<numThreads {
      outputContents[i] = 0
    }
    
    // Amortizes the cost of reading from memory.
    let incrementAmounts: [Int32] = .init(repeating: 1, count: opsMultiplier)
    
    var expectedSum: Int32 = 0
    for i in 0..<numInputs {
      let originalElement = Int32(i % 19)
      inputContents[i] = originalElement
      
      for j in 0..<opsMultiplier {
        var element = originalElement
        element = element + incrementAmounts[j]
        expectedSum += element
      }
    }
    
    // Iterate over multiple trials.
    var bestThroughput: Double = 0
    for trialID in 0..<10 {
      let commandQueue = Context.global.commandQueue
      let commandBuffer = commandQueue.makeCommandBuffer()!
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      do {
        let pipeline = Context.global.pipelines["testFunctionCallOverhead"]!
        encoder.setComputePipelineState(pipeline)
        
        encoder.setBuffer(inputBuffer, offset: 0, index: 0)
        encoder.setBuffer(outputBuffer, offset: 0, index: 1)
        
        var numBytes_copy = inputBufferSize
        encoder.setBytes(&numBytes_copy, length: 4, index: 2)
        encoder.setBytes(
          incrementAmounts, length: incrementAmounts.count * 4, index: 3)
        
        encoder.dispatchThreads(
          MTLSizeMake(numThreads, 1, 1),
          threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
      }
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
      
      // Check random places in the output buffer.
      for _ in 0..<100 {
        let i = Int.random(in: 0..<numThreads)
//        print(i, outputContents[i] == expectedSum)
        XCTAssertEqual(outputContents[i], expectedSum)
      }
      
      // Report execution time and elements processed/second.
      let startTime = commandBuffer.gpuStartTime
      let endTime = commandBuffer.gpuEndTime
      let elapsedTime = endTime - startTime
      let time_rep = String(format: "%.3f", elapsedTime)
      
      let throughput = Double(numInputs * numThreads * opsMultiplier) / elapsedTime
      let gigaops = throughput / 1e9
      let gigaops_rep = String(format: "%.3f", gigaops)
      
      print("Trial \(trialID + 1): \(time_rep) seconds, \(gigaops_rep) giga-ops")
      bestThroughput = max(bestThroughput, throughput)
    }
    
    let gigaops = bestThroughput / 1e9
    let gigaops_rep = String(format: "%.3f", gigaops)
    print("Best throughput: \(gigaops_rep) gigaops")
  }
}
