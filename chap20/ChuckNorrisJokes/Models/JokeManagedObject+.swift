//
//  JokeManagedObject+.swift
//  ChuckNorrisJokes
//
//  Created by Adam Ahrens on 5/25/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData
import ChuckNorrisJokesModel

extension JokeManagedObject {
  
  static func save(joke: Joke, inViewContext viewContext: NSManagedObjectContext) {
    guard joke.id != "error" else { return }
    
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "JokeManagedObject")
    fetchRequest.predicate = NSPredicate(format: "id = %@", joke.id)
    
    
    if let results = try? viewContext.fetch(fetchRequest), let existing = results.first as? JokeManagedObject {
      // Update existing
      existing.value = joke.value
      existing.categories = joke.categories as NSArray
      existing.languageCode = joke.languageCode
      existing.translationLanguageCode = joke.translationLanguageCode
      existing.translatedValue = joke.translatedValue
    } else {
      // New
      let jokeManaged = JokeManagedObject(context: viewContext)
      jokeManaged.id = joke.id
      jokeManaged.value = joke.value
      jokeManaged.categories = joke.categories as NSArray
      jokeManaged.languageCode = joke.languageCode
      jokeManaged.translationLanguageCode = joke.translationLanguageCode
      jokeManaged.translatedValue = joke.translatedValue
    }
    
    if viewContext.hasChanges {
      do {
        try viewContext.save()
      } catch {
        fatalError("Unable to save JokeManagedObject: \(error.localizedDescription)")
      }
    }
  }
}

extension Collection where Element == JokeManagedObject, Index == Int {
  func delete(at indices: IndexSet, inViewContext viewContext: NSManagedObjectContext) {
    indices.forEach { index in
      viewContext.delete(self[index])
    }
    
    if viewContext.hasChanges {
      do {
        try viewContext.save()
      } catch {
        fatalError("Unable to delete JokeManagedObject(s): \(error.localizedDescription)")
      }
    }
  }
}
