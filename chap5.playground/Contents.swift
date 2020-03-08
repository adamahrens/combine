import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "prepend(Output)") {
  let publisher = [3, 4, 5].publisher
  
  publisher
    .prepend(0, 1, 2)
    .prepend(-1)
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "prepend(Sequence)") {
  let publisher = [3, 4, 5].publisher
  
  publisher
    .prepend([0, 10, 11])
    .prepend(stride(from: 60, to: 70, by: 2))
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "prepend(Publisher)") {
  let names = ["Bobby", "Bill"].publisher
  let other = ["Francis", "Fran"].publisher
  
  names
    .prepend(other)
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "switchToLatest") {
  let pub1 = PassthroughSubject<Int, Never>()
  let pub2 = PassthroughSubject<Int, Never>()
  let pub3 = PassthroughSubject<Int, Never>()
  
  let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()
  
  publishers.switchToLatest().sink(receiveCompletion: {
    print("Completed \($0)")
  }) { next in
    print("Next: \(next)")
  }.store(in: &subscriptions)
  
  publishers.send(pub1)
  pub1.send(1)
  pub1.send(2)
  
  publishers.send(pub2)
  pub1.send(3)
  pub2.send(4)
  pub2.send(5)
  
  publishers.send(pub3)
  pub2.send(6)
  pub3.send(7)
  pub3.send(8)
  
  pub3.send(completion: .finished)
  publishers.send(completion: .finished)
}

example(of: "switchLatest + networking") {
  let url = URL(string: "https://source.unsplash.com/random")!
  
  func fetchImage() -> AnyPublisher<UIImage?, Never> {
    let data = URLSession.shared.dataTaskPublisher(for: url)
    return data
      .map { data, _ in UIImage(data: data) }
      .print("image")
      .replaceError(with: nil)
      .eraseToAnyPublisher()
  }
  
  let userTaps = PassthroughSubject<Void, Never>()
  
  userTaps
    .map { fetchImage() }
    .switchToLatest()
    .sink { image in
      print("Got an image")
    }.store(in: &subscriptions)
  
  // Use taps download button
//  userTaps.send()
  
  DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//    userTaps.send()
  }
  
  DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
//    userTaps.send()
  }
}

example(of: "merge(with:)") {
  let pub1 = PassthroughSubject<Int, Never>()
  let pub2 = PassthroughSubject<String, Never>()
  let mapped = pub2
    .map { Int($0) }
    .replaceNil(with: -1)
  
  pub1.merge(with: mapped).sink(receiveCompletion: { _ in
    print("Completed")
  }) { next in
    print(next)
  }.store(in: &subscriptions)
  
  pub1.send(1)
  pub1.send(1)
  
  pub2.send("2")
  pub2.send("2")
  
  pub2.send(completion: .finished)
  pub1.send(completion: .finished)
}

example(of: "combineLatest") {
  let zip = PassthroughSubject<Int, Never>()
  let name = PassthroughSubject<String, Never>()
  
  zip.combineLatest(name).sink(receiveCompletion: { _ in print("complete")
  }) { tuple in
    print("Got zip \(tuple.0), name \(tuple.1)")
  }.store(in: &subscriptions)
  
  zip.send(55102)
  name.send("Leroy Jenkins")
  zip.send(55123)
  
  zip.send(completion: .finished)
  name.send(completion: .finished)
}

// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
