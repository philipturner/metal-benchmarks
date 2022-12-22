import Metal
import MetalPerformanceShaders
import Accelerate
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

    let numThreads = 100_000_000  // Calibrated for M1 Max
    let bufferSize = numThreads * MemoryLayout<UInt64>.stride
    let buffer = device.makeBuffer(
      length: bufferSize, options: .storageModeShared)!

    let commandQueue = device.makeCommandQueue()!
    var maxThroughput: Int = 0
    for _ in 0..<50 {
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

      // TODO: After committing to MoltenCL repo, transfer this over to
      // metal-benchmarks repo.
//      print(Int((cmdbuf.gpuEndTime - cmdbuf.gpuStartTime) * 1e6))
      let time = cmdbuf.gpuEndTime - cmdbuf.gpuStartTime
      let numBlocks = 2 // try 1, 2, 4
      let numOps = (numBlocks * 50 * 24) * numThreads
      let throughputD = Double(numOps) / time
      
      // Throughput in GOPS
      let throughputI = Int(throughputD / 1e9)
      maxThroughput = max(maxThroughput, throughputI)
      print(maxThroughput)
      
    }
  }
  
  func testAccelerateAMX() {
    guard Bundle.safeModule != nil else {
      // Exclude from command-line builds
      return
    }
    
    // Test matrix on AMX, double, single, half precision
    // Test on Int16?
    
    let dataType = Double.self
    let matrixSize = 768
    let numThreads = 1
    let numItems = 1
    
    #if false
    var matrixA = BNNSNDArrayDescriptor.allocateUninitialized(
      scalarType: dataType, shape: [matrixSize, matrixSize])
    var matrixB = BNNSNDArrayDescriptor.allocateUninitialized(
      scalarType: dataType, shape: [matrixSize, matrixSize])
    let matrixCs = (0..<numThreads).map { _ in
      BNNSNDArrayDescriptor.allocateUninitialized(
        scalarType: dataType, shape: [matrixSize, matrixSize])
    }
    
    var _aMatrixC = matrixCs[0]
    let workspaceSize = BNNSMatMulWorkspaceSize(false, false, 1, &matrixA, &matrixB, &_aMatrixC, nil)
    let workspace = malloc(workspaceSize)!
    defer { free(workspace) }
    #else
    func getSize<T>(of type: T.Type) -> Int {
      MemoryLayout<T>.stride
    }
    let matrixMemorySize = matrixSize * matrixSize * getSize(of: dataType)
    let matrixA = malloc(matrixMemorySize)!.assumingMemoryBound(to: dataType)
    let matrixB = malloc(matrixMemorySize)!.assumingMemoryBound(to: dataType)
    let matrixCs = (0..<numThreads).map { _ in
      malloc(matrixMemorySize)!.assumingMemoryBound(to: dataType)
    }
    #endif
    defer { matrixA.deallocate() }
    defer { matrixB.deallocate() }
    defer { matrixCs.forEach { $0.deallocate() } }
    
    var maxThroughput = 0
    var maxThroughput2 = 0
    for _ in 0..<500 {
      var times: SIMD8<Double> = .zero
      
      let anotherStart = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
      DispatchQueue.concurrentPerform(iterations: numThreads) { i in
        var accumulatedTime: Double = 0
        var itemID = i
        var myMatrixC = matrixCs[i]
        while true {
          let start = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
          #if false
          let error = BNNSMatMul(false, false, 1, &matrixA, &matrixB, &myMatrixC, workspace, nil)
          #else
          cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, Int32(matrixSize), Int32(matrixSize), Int32(matrixSize), 1, matrixA, Int32(matrixSize), matrixB, Int32(matrixSize), 0, myMatrixC, Int32(matrixSize))
          #endif
          let end = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
          
          let time = Double(end - start) / 1e9
          accumulatedTime += time
          
          itemID += numThreads
          if itemID >= numItems {
            break
          }
        }
        times[i] = accumulatedTime
      }
      let anotherEnd = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
      
      var time: Double = 0
      for i in 0..<numThreads {
        time += times[i]
      }
      let numOperations = numItems * 2 * matrixSize * matrixSize * matrixSize
      let throughputD = Double(numOperations) / time
      
      // Throughput in GOPS
      let throughputI = Int(throughputD / 1e9)
      maxThroughput = max(maxThroughput, throughputI)
      
      let time2 = Double(anotherEnd - anotherStart) / 1e9
      let numOperations2 = numItems * 2 * matrixSize * matrixSize * matrixSize
      let throughputD2 = Double(numOperations2) / time2
      
      // Throughput in GOPS
      let throughputI2 = Int(throughputD2 / 1e9)
      maxThroughput2 = max(maxThroughput2, throughputI2)
      print(max(maxThroughput, maxThroughput2))
    }
    
    // Test multicore performance
  }
  
  func testMPSMatrix() {
    guard Bundle.safeModule != nil else {
      // Exclude from command-line builds
      return
    }
    
    let isFloat = true
    let elementStride = isFloat ? 4 : 2
    let dataType: MPSDataType = isFloat ? .float32 : .float16
    let matrixSize = 12288
    let numResults = 4
    let batchSize = matrixSize
    
    let device = MTLCreateSystemDefaultDevice()!
    let descA = MPSMatrixDescriptor(
      rows: matrixSize, columns: matrixSize,
      rowBytes: matrixSize * elementStride, dataType: dataType)
    let descB = MPSMatrixDescriptor(
      rows: matrixSize, columns: batchSize,
      rowBytes: batchSize * elementStride, dataType: dataType)
    let descC = MPSMatrixDescriptor(
      rows: matrixSize, columns: batchSize,
      rowBytes: batchSize * elementStride, dataType: dataType)
    
    #if false
    let matrixAs = (0..<numResults).map { _ in
      MPSMatrix(device: device, descriptor: descA)
    }
    let matrixBs = (0..<numResults).map { _ in
      MPSMatrix(device: device, descriptor: descB)
    }
    #else
    let _actualA = MPSMatrix(device: device, descriptor: descA)
    let _actualB = MPSMatrix(device: device, descriptor: descB)
    let matrixAs = (0..<numResults).map { _ in
      _actualA
    }
    let matrixBs = (0..<numResults).map { _ in
      _actualB
    }
    #endif
    let results = (0..<numResults).map { _ in
      MPSMatrix(device: device, descriptor: descC)
    }
    
    let multiplication = MPSMatrixMultiplication(
      device: device, transposeLeft: false, transposeRight: false,
      resultRows: matrixSize, resultColumns: batchSize,
      interiorColumns: matrixSize, alpha: 1, beta: 0)
    
    let commandQueues = results.map {
      _ in device.makeCommandQueue()!
    }
    var maxThroughput: Int = 0
    for _ in 0..<5000 {
      var commandBuffers: [MTLCommandBuffer] = []
      for i in results.indices {
        let result = results[i]
        let commandQueue = commandQueues[i]
        let cmdbuf = commandQueue.makeCommandBuffer()!
        multiplication.encode(
          commandBuffer: cmdbuf, leftMatrix: matrixAs[i], rightMatrix: matrixBs[i],
          resultMatrix: result)
        cmdbuf.commit()
        commandBuffers.append(cmdbuf)
      }
      
      var firstStart: Double?
      var lastEnd: Double?
      for commandBuffer in commandBuffers {
        commandBuffer.waitUntilCompleted()
        if firstStart == nil {
          firstStart = commandBuffer.gpuStartTime
        } else {
          firstStart = min(commandBuffer.gpuStartTime, firstStart!)
        }
        if lastEnd == nil {
          lastEnd = commandBuffer.gpuEndTime
        } else {
          lastEnd = max(commandBuffer.gpuEndTime, lastEnd!)
        }
      }
      
//      print("This round: \(Int((lastEnd! - firstStart!) * 1e6))")
      for commandBuffer in commandBuffers {
        let startDelta = commandBuffer.gpuStartTime - firstStart!
        let endDelta = commandBuffer.gpuEndTime - firstStart!
//        print(Int(startDelta * 1e6), Int(endDelta * 1e6))
      }
      
      let time = lastEnd! - firstStart!
      let numOperations = results.count * 2 * batchSize * matrixSize * matrixSize
      let throughputD = Double(numOperations) / time
      
      // Throughput in GOPS
      let throughputI = Int(throughputD / 1e9)
      maxThroughput = max(maxThroughput, throughputI)
      print(maxThroughput)
    }
  }
}
