import Metal
import XCTest

final class ClockCycleTests: XCTestCase {
  func testThroughput() throws {
    guard Bundle.safeModule != nil else {
      // Exclude from command-line builds
      return
    }

    let device = MTLCreateSystemDefaultDevice()!
    let library = try! device.makeDefaultLibrary(bundle: Bundle.safeModule!)
    let function = library.makeFunction(name: "testALU")!
    let pipeline = try! device.makeComputePipelineState(function: function)

    let numThreads = 10_000_000  // Calibrated for M1 Max
    let bufferSize = numThreads * MemoryLayout<UInt64>.stride
    let buffer = device.makeBuffer(
      length: bufferSize, options: .storageModeShared)!

    let commandQueue = device.makeCommandQueue()!
    for _ in 0..<100 {
      memset(buffer.contents(), 0, bufferSize)

      let cmdbuf = commandQueue.makeCommandBuffer()!
      let encoder = cmdbuf.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(pipeline)
      encoder.setBuffer(buffer, offset: 0, index: 0)
      encoder.dispatchThreads(
        MTLSizeMake(numThreads, 1, 1),
        threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
      encoder.endEncoding()
      cmdbuf.commit()
      cmdbuf.waitUntilCompleted()

      print(Int((cmdbuf.gpuEndTime - cmdbuf.gpuStartTime) * 1e6))
    }
  }
}
