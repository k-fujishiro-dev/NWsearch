import Foundation

final class DNSProbe: NSObject, URLSessionDataDelegate {
    private var continuation: CheckedContinuation<Int?, Never>?
    private var startTime: Date = Date()
    private var timeoutWorkItem: DispatchWorkItem?

    func measure(url: URL, timeoutMs: Int) async -> Int? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.startTime = Date()

            let config = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            let task = session.dataTask(with: url)
            task.resume()

            let workItem = DispatchWorkItem { [weak self] in
                self?.finish(value: nil)
                session.invalidateAndCancel()
            }
            timeoutWorkItem = workItem
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs), execute: workItem)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)
        finish(value: elapsed)
        completionHandler(.cancel)
        session.invalidateAndCancel()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let _ = error {
            finish(value: nil)
        }
    }

    private func finish(value: Int?) {
        guard let continuation = continuation else { return }
        timeoutWorkItem?.cancel()
        self.continuation = nil
        continuation.resume(returning: value)
    }
}
