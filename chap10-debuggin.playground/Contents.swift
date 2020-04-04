import UIKit
import Combine

var set = Set<AnyCancellable>()

final class Timer: TextOutputStream {
  private var previous = Date()
  private let formatter = NumberFormatter()
  
  init() {
    formatter.maximumFractionDigits = 5
    formatter.minimumFractionDigits = 5
  }
  
  func write(_ string: String) {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.isEmpty == false else { return }
    let now = Date()
    print("+\(formatter.string(for: now.timeIntervalSince(previous))!)s: \(string)")
    previous = now
  }
}

(1...10).publisher
  .print("debugging#")
  .sink { _ in }
  .store(in: &set)

(1...10).publisher
  .print("debugging#", to: Timer())
  .sink { _ in }
  .store(in: &set)

// Performing side effects
let url = URL(string: "https://www.raywenderlich.com/")!
let request = URLSession.shared .dataTaskPublisher(for: url)
  request
    .handleEvents(receiveSubscription: { _ in
      print("Network request will start")
    }, receiveOutput: { _ in
      print("Network request data received")
    }, receiveCompletion: { _ in
      print("Network request completed")
    }, receiveCancel: {
      print("Network request cancelled")
    }, receiveRequest: { _ in
      print("Network requet wants more elements")
    })
  .sink(receiveCompletion: { completion in
  print("Sink received completion: \(completion)")
  }) { (data, _) in
  print("Sink received data: \(data)")
}.store(in: &set)
