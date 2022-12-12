import XCTest
import Metal

fileprivate var _subpaths: [String] = []
fileprivate var _fileMap: [String: String] = [:]

// Returns something different depending on whether it's an Xcode or
// command-line build. Also, `Bundle.module.path(forResource:ofType:)` fails in
// Xcode but works from command-line.
func fetchPath(forResource name: String, ofType ext: String) -> String {
  if let path = Bundle.module.path(forResource: name, ofType: ext) {
    // Command-line build
    return path
  }
  
  // Strangely, the previous statement sometimes fails in command-line builds.
  let resourcesPath = Bundle.module.resourcePath!
  let testResourcesPath = resourcesPath + "/Resources"
  let testContents = try? FileManager.default
    .contentsOfDirectory(atPath: testResourcesPath)
  if testContents != nil {
    // Xcode build
  } else {
    // Command-line build
  }
  
  _subpaths = try! FileManager.default
    .subpathsOfDirectory(atPath: resourcesPath)
  _subpaths = _subpaths.map { resourcesPath + "/" + $0 }
  
  let fileName = name + "." + ext
  if let cachedPath = _fileMap[fileName] {
    return cachedPath
  }
  
  for subpath in _subpaths {
    let possiblePath = subpath + "/" + fileName
    if FileManager.default.fileExists(atPath: possiblePath) {
      _fileMap[fileName] = possiblePath
      return possiblePath
    }
  }
  
  fatalError("Could not find file '\(fileName)'")
}
