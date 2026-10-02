import IdentityLookup

final class MessageFilterExtension: ILMessageFilterExtension {
}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
  func handle(
    _ queryRequest: ILMessageFilterQueryRequest,
    context: ILMessageFilterExtensionContext,
    completion: @escaping (ILMessageFilterQueryResponse) -> Void
  ) {
    let sender = queryRequest.sender ?? ""
    let body = queryRequest.messageBody ?? ""

    if SenderClassifier.looksTransactional(sender: sender, body: body) {
      AppGroupWriter.append(sender: sender, body: body)
    }

    // Always .allow: this extension observes and records, it never hides or
    // reclassifies a legitimate message as junk/promotion.
    let response = ILMessageFilterQueryResponse()
    response.action = .allow
    completion(response)
  }
}
