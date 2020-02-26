import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "collect()") {
  ["A", "B", "C", "D"].publisher.sink(receiveCompletion: { completion in
    print(completion)
  }) { next in
    print(next)
  }.store(in: &subscriptions)
  
  // Perform collect
  ["A", "B", "C", "D"].publisher
  .collect() // Combines all events into an array
  .sink(receiveCompletion: { completion in
    print(completion)
  }) { next in
    print(next)
  }.store(in: &subscriptions)
  
  ["A", "B", "C", "D"].publisher
    .collect(2) // collect arrays of size 2
    .sink(receiveCompletion: { completion in
      print(completion)
    }) { next in
      print(next)
  }.store(in: &subscriptions)
}

example(of: "map()") {
  let spellOutFormatter = NumberFormatter()
  spellOutFormatter.numberStyle = .spellOut
  
  let moneyFormatter = NumberFormatter()
  moneyFormatter.numberStyle = .currency
  
  [1, 1001, 2513, 26, 99.99].publisher
  .map { spellOutFormatter.string(from: NSNumber(value: $0))! }
  .sink(receiveCompletion: { completion in
    print(completion)
  }) { next in
    print(next)
  }.store(in: &subscriptions)
  
  [1, 1001, 2513, 26, 99.99].publisher
    .map { moneyFormatter.string(from: NSNumber(value: $0))! }
    .sink(receiveCompletion: { completion in
      print(completion)
    }) { next in
      print(next)
  }.store(in: &subscriptions)
}

example(of: "map() keypaths") {
  let publisher = PassthroughSubject<Coordinate, Never>()
  publisher
    .map(\.x, \.y)
    .sink { x, y in
      print("The coordinate at (\(x), \(y)) is in quadrant", quadrantOf(x: x, y: y))
    }
    .store(in: &subscriptions)
  
  publisher.send(Coordinate(x: -10, y: 5))
  publisher.send(Coordinate(x: 10, y: 10))
  publisher.send(Coordinate(x: 0, y: 7))
}

example(of: "tryMap() for errors") {
  let file = Just("file/path/")
  file
    .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
    .sink(receiveCompletion: { completion in
      print(completion)
    }) { _ in
      print("Won't happen. Try/Throw ")
    }.store(in: &subscriptions)
}

example(of: "flatMap()") {
  let leroy = Chatter(name: "Leroy", message: "Hello!")
  let jenkins = Chatter(name: "Jenkins", message: "What's going on?")
  let chatroom = CurrentValueSubject<Chatter, Never>(leroy)
  
//  chatroom.sink { chat in
//    print("\(chat.name) - \(chat.message.value)")
//  }.store(in: &subscriptions)
  
  chatroom
  .flatMap { $0.message}
  .sink { chat in
    print(chat)
  }.store(in: &subscriptions)
  
  chatroom.value = jenkins
  leroy.message.value = "What's new" // Wont happen, Publisher is on chatter
}

example(of: "replaceWithNil") {
  [1, 2, nil, 4]
    .publisher
    .replaceNil(with: -1)
    .map { $0! } // Force Unwrapped because we convert all nil options
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "scan()") {
  var stock: Int { .random(in: -100...100) }
  let today = (0...28).map { _ in stock }.publisher
  
  today.scan(50) { latest, current in
    max(0, latest + current)
  }.sink { next in
    print(next)
  }.store(in: &subscriptions)
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
