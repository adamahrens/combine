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

import Foundation
import Combine
import SwiftUI

final class ReaderViewModel: ObservableObject {
  private let api = API()
  private var subscriptions = Set<AnyCancellable>()
  
  @Published var allStories = [Story]()
  @Published var error: API.Error? = nil
  @Published var filter = [String]()
  @Published var header: String = ""
    
  var filterHeader: String {
    if filter.count == 0 {
      return "Showing all stories"
    }
    
    return "Filter: " + filter.joined(separator: ",")
  }
  
  var stories: [Story] {
    guard
      !filter.isEmpty
    else { return allStories }
    
    return allStories
      .filter { story -> Bool in
        return filter.reduce(false) { isMatch, keyword -> Bool in
          return isMatch || story.title.lowercased().contains(keyword)
        }
      }
  }
  
  func fetchStories() {
    api
      .stories()
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { result in
        if case .failure(let error) = result {
          self.error = error
          self.allStories = []
        }
      }) { stories in
        self.allStories = stories
        self.error = nil
        
        let count = stories.count
        
        if count == 0 {
          self.header = "No stories"
        } else if count == 1 {
          self.header = "1 Story"
        } else {
          self.header = "\(count) Stories"
        }
    }.store(in: &subscriptions)
  }
}
