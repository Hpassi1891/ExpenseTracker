import Foundation

enum SenderClassifier {
  // Indian DLT sender IDs look like "VM-ICICIB", "AX-HDFCBK", "VD-PAYTM", "JD-SBIINB".
  private static let senderPattern = try! NSRegularExpression(
    pattern: "^[A-Z]{2}-[A-Z0-9]{3,}$",
    options: []
  )

  private static let transactionKeywords = [
    "debited", "credited", "debit", "credit", "upi", "a/c", "acct",
    "withdrawn", "spent", "paid", "received", "txn", "transaction",
  ]

  static func looksTransactional(sender: String, body: String) -> Bool {
    let senderMatches =
      senderPattern.firstMatch(
        in: sender,
        range: NSRange(sender.startIndex..., in: sender)
      ) != nil

    let lowerBody = body.lowercased()
    let keywordMatches = transactionKeywords.contains { lowerBody.contains($0) }

    return senderMatches && keywordMatches
  }
}
