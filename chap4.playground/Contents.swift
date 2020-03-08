import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "filter") {
  let numbers = (1...69).publisher
  
  numbers
    .filter { $0.isMultiple(of: 3) }
    .sink { next in print("\(next) is multiple of 3") }
    .store(in: &subscriptions)
}

example(of: "removeDuplicates") {
  let string = "hey hey were the best best best around. nothing i mean mean nothing gonna stop"
  let words = string.components(separatedBy: " ").publisher
  words
    .removeDuplicates()
    .sink {  print($0) }
    .store(in: &subscriptions)
}

example(of: "compactMap") {
  let strings = ["a", "1.34", "23", "NAN", "def", "0.23", "45.666"].publisher
  strings
    .compactMap { Float($0) }
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "first(where:)") {
  let numbers = (1...69).publisher
  numbers
    .print("numbers")
    .first { $0 % 9 == 0 }
    .sink(receiveCompletion: { _ in
      print("completed")
    }) { next in
      print("Got \(next)")
  }.store(in: &subscriptions)
}

example(of: "last(where:)") {
  let numbers = (1...69).publisher
  numbers
    .print("n")
    .last { $0 % 9 == 0 }
    .sink(receiveCompletion: { _ in
      print("completed")
    }) { next in
      print("Got \(next)")
  }.store(in: &subscriptions)
}

example(of: "dropFirst") {
  let numbers = (1...10).publisher
  numbers
    .dropFirst(4)
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "drop(while:)") {
  let numbers = (1...10).publisher
  numbers
    .drop { $0 % 5 != 0 }
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "drop(unitilOutputFrom)") {
  let ready = PassthroughSubject<Void, Never>()
  let userTaps = PassthroughSubject<Int, Never>()
  
  userTaps
    .drop(untilOutputFrom: ready)
    .sink { print("Got tap \($0)") }
    .store(in: &subscriptions)
  
  (1...5).forEach {
    userTaps.send($0)
    if $0 == 3 {
      ready.send()
    }
  }
}

example(of: "prefix") {
  let numbers = (1...10).publisher
  numbers
    .prefix(3)
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "prefix(while:)") {
  let numbers = (1...10).publisher
  numbers
    .prefix { $0 < 6 }
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "challenge") {
  let numbers = (1...100).publisher
  numbers
    .dropFirst(50)
    .prefix(20)
    .filter { $0.isMultiple(of: 2) }
    .sink { print($0) }
    .store(in: &subscriptions)
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
