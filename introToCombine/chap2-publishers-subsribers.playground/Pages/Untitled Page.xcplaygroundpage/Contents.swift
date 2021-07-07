import UIKit
import Combine
import PlaygroundSupport

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

func example(of description: String, action: () -> Void) {
  print("\n ---- Example of \"\(description)\" ----\n")
  action()
}

var subscriptions = Set<AnyCancellable>()

// Publisher is a protocol for transmitting values over time (emits events).
// Two events can be published (value event, and completion event(success/failure(error))

// Subscriber is a protocol for a type to receive input from a Publisher


// Three main components of Combine. Publishers, Operators, Subscribers
// Publishers emit values over time to interested parties (subscribers)
// Operators take in an input (operate on it) then output result to subscribers
// Subscribers are the end of the subscription chain. Combine provides sink and assign
extension Notification.Name {
  /// Loging event that fires
  static let login = Notification.Name("Login")
}

struct User {
  let first: String
  let last: String
  let email: String
}

example(of: "Publisher/Subscriber w/ Notifications") {
  let publisher = NotificationCenter.default.publisher(for: .login)
  let subscriber = publisher.sink { notification in
    print("Next value \(notification). Object \(String(describing: notification.object))")
  }
  
  let user = User(first: "Adam", last: "Ahrens", email: "adam@ahrens.com")
  NotificationCenter.default.post(name: .login, object: user)
  
  subscriber.cancel()
}

example(of: "Just") {
  let publisher = Just("Hello World!")
  _ = publisher.sink(receiveCompletion: { result in
    print("Completion Event: \(result)")
  }, receiveValue: { next in
    print("Next value \(next)")
  })
  
  _ = publisher.sink(receiveCompletion: { result in
    print("Completion Event Other: \(result)")
  }, receiveValue: { next in
    print("Next value Other \(next)")
  })
}

example(of: "assign(to:on:") {
  
  final class Greeting {
    var greeting: String = "" {
      didSet {
        print("Greeting is \(greeting)")
      }
    }
  }
  
  let greeting = Greeting()
  let publisher = ["Good Morning", "Good Afternoon", "Good Evening"].publisher
  _ = publisher.assign(to: \.greeting, on: greeting)
}

example(of: "assign(to)") {
  final class Counter {
    @Published var count = 0
  }
  
  let counter = Counter()
  let publisher = (1...20).publisher
  
  counter.$count.sink { print("Got \($0)")}
  publisher.assign(to: &counter.$count)
}

example(of: "Building Custom Subscriber") {
  final class IntSubscriber: Subscriber {
    func receive(subscription: Subscription) {
      print("receive(subscription)")
      
      // Allow max of 4 values to be emitted (backpressure)
      subscription.request(.max(4))
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
      print("receive(input) -> \(input)")
      return .none
//      return .unlimited
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
      print("receive(completion) -> \(completion)")
    }
    
    typealias Input = Int
    typealias Failure = Never
  }
  
  let publisher = (1...6).publisher
  let subscriber = IntSubscriber()
  publisher.subscribe(subscriber)
}

example(of: "Future") {
  func increment(integer: Int, afterDelay delay: TimeInterval) -> Future<Int, Never> {
    Future<Int, Never> { promise in
      DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
        promise(.success(integer + 1))
      }
    }
  }
  
//  let future = increment(integer: 1, afterDelay: 3)
//  future.sink(receiveCompletion: { print("Future completion \($0)")}) {
//    print("Future next \($0)")
//  }.store(in: &subscriptions)
}

example(of: "Passthrough Subject") {
  enum CustomerError: Error {
    case invalid
  }
  
  final class StringSubscriber: Subscriber {
    func receive(subscription: Subscription) {
      print("receive(subscription)")
      // Allow max of 4 values to be emitted (backpressure)
      subscription.request(.max(4))
    }
    
    func receive(_ input: String) -> Subscribers.Demand {
      print("receive(input) -> \(input)")
      return .none
      //      return .unlimited
    }
    
    func receive(completion: Subscribers.Completion<CustomerError>) {
      print("receive(completion) -> \(completion)")
    }
    
    typealias Input = String
    typealias Failure = CustomerError
  }
  
  let subscriber = StringSubscriber()
  let subject = PassthroughSubject<String, CustomerError>()
  subject.subscribe(subscriber)
  
  subject.sink { result in
    print("Passthrough result: \(result)")
  } receiveValue: { next in
    print("Passthrough next: \(next)")
  }.store(in: &subscriptions)
  
  subject.send("Hello")
  subject.send("World!")
  subject.send(completion: .failure(.invalid))
}

example(of: "CurrentValueSubject") {
  let subject = CurrentValueSubject<Int, Never>(1)
  subject.sink { print("CurrentValue subject is \($0)") }.store(in: &subscriptions)
  subject.send(2)
  subject.send(3)
  
  // Allows accessing current value
  print("Current val is \(subject.value)")
  
  // Can send values also by setting
  subject.value = 500
}
