import UIKit
import Combine
import PlaygroundSupport

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

func example(of description: String, action: () -> Void) {
  print("\n ---- Example of \"\(description)\" ----\n")
  action()
}

struct Coordinate {
  let x: Int
  let y: Int
}

func quadrantOf(x: Int, y: Int) -> String {
  var quadrant = ""
  
  switch (x, y) {
    case (1..., 1...):
      quadrant = "1"
    case (..<0, 1...):
      quadrant = "2"
    case (..<0, ..<0):
      quadrant = "3"
    case (1..., ..<0):
      quadrant = "4"
    default:
      quadrant = "boundary"
  }
  
  return quadrant
}

var subscriptions = Set<AnyCancellable>()

example(of: "collect()") {
  ["A", "d", "a", "m", " ", "A."]
    .publisher
    .collect()
    .sink { value in
      print("collect() next \(value)")
      print("collect() \(value.joined())")
    }.store(in: &subscriptions)
}

example(of: "map") {
  let formatter = NumberFormatter()
  formatter.numberStyle = .spellOut
  
  [201, 10000, 1.99]
    .publisher
    .map { NSNumber(value: $0) }
    .map { formatter.string(from: $0) }
    .sink { value in
      print("map next \(value ?? "unknown value")")
    }.store(in: &subscriptions)
}

example(of: "map keypaths") {
  let publisher = PassthroughSubject<Coordinate, Never>()
  
  publisher
    .map(\.x, \.y)
    .sink { x, y in
      print("Coordinate x: \(x), y: \(y) is in quadrant \(quadrantOf(x: x, y: y))")
    }.store(in: &subscriptions)
  publisher.send(Coordinate(x: 10, y: -8))
  publisher.send(Coordinate(x: 0, y: 5))
}

example(of: "replaceNil") {
  ["A", nil, "B", "C"]
    .publisher
    .eraseToAnyPublisher()
    .replaceNil(with: "?")
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "scan") {
  var weightGainLoss: Int {
    .random(in: -9...9)
  }
  
  let july = (1...31)
    .map { _ in weightGainLoss }
    .publisher
  
  july.scan(200) { latest, current in
    max(0, latest + current)
  }.sink {
    print("Gain/Loss is \($0)")
  }.store(in: &subscriptions)
}

// Challenge
example(of: "Create a phone number lookup") {
  let contacts = [
    "603-555-1234": "Florent",
    "408-555-4321": "Marin",
    "217-555-1212": "Scott",
    "212-555-3434": "Shai"
  ]
  
  func convert(phoneNumber: String) -> Int? {
    if let number = Int(phoneNumber),
       number < 10 {
      return number
    }
    
    let keyMap: [String: Int] = [
      "abc": 2, "def": 3, "ghi": 4,
      "jkl": 5, "mno": 6, "pqrs": 7,
      "tuv": 8, "wxyz": 9
    ]
    
    let converted = keyMap
      .filter { $0.key.contains(phoneNumber.lowercased()) }
      .map { $0.value }
      .first
    
    return converted
  }
  
  func format(digits: [Int]) -> String {
    var phone = digits.map(String.init)
      .joined()
    
    phone.insert("-", at: phone.index(
                  phone.startIndex,
                  offsetBy: 3)
    )
    
    phone.insert("-", at: phone.index(
                  phone.startIndex,
                  offsetBy: 7)
    )
    
    return phone
  }
  
  func dial(phoneNumber: String) -> String {
    guard let contact = contacts[phoneNumber] else {
      return "Contact not found for \(phoneNumber)"
    }
    
    return "Dialing \(contact) (\(phoneNumber))..."
  }
  
  let input = PassthroughSubject<String, Never>()
//  input
//    .map { convert(phoneNumber: $0) }
//    .replaceNil(with: 0)
//    .collect(10)
//    .map { format(digits: $0) }
//    .map { dial(phoneNumber: $0) }
//    .sink { value in
//      print(value)
//    }.store(in: &subscriptions)
  
  // Shorter
  input
    .map(convert)
    .replaceNil(with: 0)
    .collect(10)
    .map(format)
    .map(dial)
    .sink { value in
      print(value)
    }.store(in: &subscriptions)
  
  "0!1234567".forEach {
    input.send(String($0))
  }
  
  "4085554321".forEach {
    input.send(String($0))
  }
  
  "A1BJKLDGEH".forEach {
    input.send("\($0)")
  }
}

example(of: "filter") {
  let numbers = (1...20).publisher
  let multipleOf = 3
  numbers
    .filter { $0.isMultiple(of: multipleOf) }
    .sink { print("\($0) is multiple of \(multipleOf)") }
    .store(in: &subscriptions)
}

example(of: "remove duplicates") {
  let words = "hello hello there there there general kenobi kenobi".components(separatedBy: " ")
  
  words.publisher
    .removeDuplicates()
    .collect()
    .map { $0.joined(separator: " ") }
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "compactMap") {
  ["hello", "1.24", "20", "b"]
    .publisher
    .compactMap { Float($0) }
    .sink { print("Float Number is \($0)") }
    .store(in: &subscriptions)
}

example(of: "drop(untilOutputFrom)") {
  let loaded = PassthroughSubject<Void, Never>()
  let taps = PassthroughSubject<Int, Never>()
  
  taps.drop(untilOutputFrom: loaded)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  (1...5).forEach { number in
    taps.send(number)
    
    if number == 3 {
      loaded.send()
    }
  }
}

example(of: "filtering challenge") {
  (1...100)
    .dropFirst(50)
    .prefix(20)
    .filter { $0 % 2 == 0}
    .publisher
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "switchLatest Networking") {
  func fetchImage() -> AnyPublisher<UIImage?, Never> {
    URLSession.shared
      .dataTaskPublisher(for: URL(string: "https://source.unsplash.com/random")!)
      .map { data, _ in UIImage(data: data) }
      .print("fetchImage")
      .replaceError(with: nil)
      .eraseToAnyPublisher()
  }
  
  let taps = PassthroughSubject<Void, Never>()
  taps
    .map { _ in fetchImage() }
    .switchToLatest()
    .sink { _ in }
    .store(in: &subscriptions)
  
  
  taps.send()
  
  DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    taps.send()
  }
  DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
    taps.send()
  }
}
