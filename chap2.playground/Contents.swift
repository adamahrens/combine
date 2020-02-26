import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "Old Way") {
  let notification = Notification.Name("SweetNotification")
  let publisher = NotificationCenter.default.publisher(for: notification, object: nil)
  
  // Old way
  let observer = NotificationCenter.default.addObserver(forName: notification, object: nil, queue: nil) { notification in
    print("Notification received without Combine")
  }
  
  NotificationCenter.default.post(name: notification, object: nil)
  NotificationCenter.default.removeObserver(observer)
}

example(of: "Publish/Subscribe") {
  let notification = Notification.Name("Backgrounded")
  let publisher = NotificationCenter.default.publisher(for: notification, object: nil)
  let subscription = publisher.sink { _ in
    print("Notification received with Combine")
  }
  
  // Hold onto subscription to keep it firing
  subscriptions.insert(subscription)
  
  // Post
  NotificationCenter.default.post(name: notification, object: nil)
  
  // Dont want anymore events emitted
  subscription.cancel()
}

example(of: "Just Once") {
  let once = Just("Will emit one event")
  subscriptions.insert(once.sink(receiveCompletion: { _ in
    print("Completed")
  }, receiveValue: { next in
    print("Received: -- \(next) --")
  }))
  
  subscriptions.insert(once.sink(receiveCompletion: { _ in
    print("Completed Again")
  }, receiveValue: { next in
    print("Received Again: -- \(next) --")
  }))
}

example(of: "assign") {
  class Counter {
    var count: Int = 0  {
      didSet {
        print(count)
      }
    }
  }
  
  let counter = Counter()
  let counts = [1, 2, 3, 4, 5, 6, 7].publisher
  
  // Allows assigning to a KVO compliant property
  subscriptions.insert(counts.assign(to: \.count, on: counter))
}

example(of: "Custom Subscriber") {
  let publisher = (1...10).publisher
  let publisher2 = (1...3).publisher
  
  final class IntSubscriber: Subscriber {
    func receive(subscription: Subscription) {
      // Only want to receive 4 items or less
      subscription.request(.max(4))
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
      print("Received \(input)")
      return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
      print("Complete")
    }
    
    typealias Input = Int
    typealias Failure = Never
  }
  
  let subscriber = IntSubscriber()
  publisher.subscribe(subscriber)
  
  // Will actually get complete since we asked for more than events that will be emitted
  let subscriber2 = IntSubscriber()
  publisher2.subscribe(subscriber2)
}

example(of: "Future") {
  func futureIncrement(integer: Int, afterDelay delay: TimeInterval) -> Future<Int,Never> {
    
  }
}

/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
