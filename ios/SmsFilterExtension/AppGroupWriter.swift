import Foundation

enum AppGroupWriter {
  static let appGroupIdentifier = "group.com.expensetracker.expenseTracker"
  static let sharedFileName = "pending_messages.jsonl"

  static func append(sender: String, body: String, receivedAt: Date = Date()) {
    guard
      let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupIdentifier
      )
    else { return }

    let fileURL = containerURL.appendingPathComponent(sharedFileName)

    let entry: [String: Any] = [
      "id": UUID().uuidString,
      "sender": sender,
      "body": body,
      "receivedAt": ISO8601DateFormatter().string(from: receivedAt),
    ]

    guard
      let data = try? JSONSerialization.data(withJSONObject: entry),
      var line = String(data: data, encoding: .utf8)
    else { return }
    line += "\n"

    guard let lineData = line.data(using: .utf8) else { return }

    if FileManager.default.fileExists(atPath: fileURL.path) {
      if let handle = try? FileHandle(forWritingTo: fileURL) {
        handle.seekToEndOfFile()
        handle.write(lineData)
        try? handle.close()
      }
    } else {
      try? line.write(to: fileURL, atomically: true, encoding: .utf8)
    }
  }
}
