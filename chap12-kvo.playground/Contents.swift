import UIKit
import Combine

let operationQueue = OperationQueue()

var subscriptions = Set<AnyCancellable>()

operationQueue.publisher(for: \.operationCount).sink { count in
  print("Operations in Queue = \(count)")
}.store(in: &subscriptions)

let block1 = BlockOperation {
  print("Block1 executed")
}

let block2 = BlockOperation {
  print("Block2 executed")
}

let block3 = BlockOperation {
  print("Block3 executed")
}

block3.addDependency(block1)

operationQueue.addOperations([block3, block2, block1], waitUntilFinished: false)

operationQueue.addOperation {
  print("Another block to run!")
}


final class User: NSObject {
  @objc dynamic var first = ""
  @objc dynamic var last = ""
  @objc dynamic var age = 0
}

let user = User()

user.publisher(for: \.first)
  .filter{ $0.count > 0 }
  .sink { first in
  print("User.first = \(first)")
}.store(in: &subscriptions)


user.publisher(for: \.last)
  .filter{ $0.count > 0 }
  .sink { last in
    print("User.last = \(last)")
}.store(in: &subscriptions)

user.publisher(for: \.age, options: [])
  .sink { age in
    print("User.age = \(age)")
}.store(in: &subscriptions)


user.first = "Leroy"
user.last = "Jenkins"
user.first = "The Leroy"
user.age = 33


final class UserObservable: ObservableObject {
  @Published var first = ""
  @Published var last = ""
}

let user2 = UserObservable()

user2.objectWillChange.sink {
  print("User2 is changing")
}.store(in: &subscriptions)

user2.$first.sink { f in
  print("User2.first = \(f)")
}

user2.first = "Leroy"
user2.last = "Jenkins"
