import Flutter
import Foundation

enum AppGroupBridge {
  static let appGroupIdentifier = "group.com.expensetracker.expenseTracker"
  static let sharedFileName = "pending_messages.jsonl"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.expensetracker/appgroup", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "readPending":
        result(readPending())
      case "markConsumed":
        guard
          let args = call.arguments as? [String: Any],
          let ids = args["ids"] as? [String]
        else {
          result(
            FlutterError(code: "bad_args", message: "ids array required", details: nil))
          return
        }
        markConsumed(ids: Set(ids))
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func containerURL() -> URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
  }

  private static func sharedFileURL() -> URL? {
    containerURL()?.appendingPathComponent(sharedFileName)
  }

  private static func readPending() -> [[String: Any]] {
    guard
      let url = sharedFileURL(),
      let data = try? Data(contentsOf: url),
      let text = String(data: data, encoding: .utf8)
    else {
      return []
    }
    return
      text
      .split(separator: "\n")
      .compactMap { line -> [String: Any]? in
        guard let lineData = line.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
      }
  }

  private static func markConsumed(ids: Set<String>) {
    guard let url = sharedFileURL() else { return }
    let remaining = readPending().filter { entry in
      guard let id = entry["id"] as? String else { return true }
      return !ids.contains(id)
    }
    let lines = remaining.compactMap { entry -> String? in
      guard
        let data = try? JSONSerialization.data(withJSONObject: entry),
        let line = String(data: data, encoding: .utf8)
      else { return nil }
      return line
    }
    let content = lines.joined(separator: "\n")
    try? content.write(to: url, atomically: true, encoding: .utf8)
  }
}
