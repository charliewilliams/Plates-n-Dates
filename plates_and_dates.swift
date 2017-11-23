#!/usr/bin/swift

import Foundation

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

print("Starting up…")

let alprCommand = "alpr -c gb -n 1 " // --config config/gb.conf  // append filename
let fileManager = FileManager.default

let sampleDir = "sampledata"
var realDir: String?

for arg in CommandLine.arguments {
  if arg == "-d" || arg == "--data-directory" {
    realDir = arg
  }
}

private func creationDateForFile(atPath path: String) -> Date {

    var created = Date.distantPast
    do {
        let attrs = try FileManager.default.attributesOfItem(atPath: path) as [FileAttributeKey:Any]
        if let creationDate = attrs[FileAttributeKey.creationDate] as? Date {
          created = creationDate
        }

    } catch let e {
        print("file not found \(e)")
    }
    return created
}

func readFiles(inDirectory dirPath: String) -> [(Date, String)] {

  guard let files = try? fileManager.contentsOfDirectory(atPath: dirPath) else {
    print("Error, no files or path invalid")
    return []
  }
  let basePath = "\(fileManager.currentDirectoryPath)/\(dirPath)"

  var data = [(Date, String)]()

  for file in files {
    let fullPath = "\(basePath)/\(file)"
    data.append((creationDateForFile(atPath: fullPath), "\(dirPath)/\(file)"))
  }

  print("Got data: ")
  data.forEach({print($0)})
  return data
}

func writeJSON() {

}



for dateAndFile in readFiles(inDirectory: realDir ?? sampleDir) {
  shell(alprCommand + dateAndFile.1)
}
