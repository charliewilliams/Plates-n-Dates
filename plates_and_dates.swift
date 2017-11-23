#!/usr/bin/swift

import Foundation

func shell(launchPath: String, arguments: [String]) -> String {

    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)!
    if output.count > 0 {
        //remove newline character.
        let lastIndex = output.index(before: output.endIndex)
        return String(output[output.startIndex ..< lastIndex])
    }
    return output
}

@discardableResult
func bash(_ command: String, arguments: [String]) -> String {
    let whichPathForCommand = shell(launchPath: "/bin/bash", arguments: [ "-l", "-c", "which \(command)" ])
    return shell(launchPath: whichPathForCommand, arguments: arguments)
}

print("Starting up…")

let alprCommand = "-c gb --config config/gb.conf -n 1" // append filename
let fileManager = FileManager.default
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"

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

func readFiles(inDirectory dirPath: String) -> [(date: Date, path: String)] {

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

//    print("Got data: ")
//    data.forEach({print($0)})
    return data
}

var data = "Date, Image file, Reg, Confidence, Notes,, \n"
for dateAndFile in readFiles(inDirectory: realDir ?? sampleDir) {

    var commands = alprCommand.components(separatedBy: " ")
    commands.append(dateAndFile.path)
    let result = bash("alpr", arguments: commands)
    let trimmed = result.replacingOccurrences(of: "plate0: 1 results", with: "")
        .replacingOccurrences(of: "sampledata/", with: "")
        .replacingOccurrences(of: "- ", with: "")
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "No license plates found.", with: ",, No license plates found.")
        .replacingOccurrences(of: "confidence: ", with: ", ")
    let dateString = dateFormatter.string(from: dateAndFile.date)
    print(dateString, dateAndFile.path, trimmed)

    data += "\(dateString),  \(dateAndFile.path),  \(trimmed),, \n"
}

do {
    let url = URL(fileURLWithPath: "output.csv")
    try data.write(to: url, atomically: false, encoding: .utf8)
} catch let e {
    print(e)
}

bash("open", arguments: ["output.csv"])
