//
//  Search.swift
//  ChuckNorrisJokes
//
//  Created by Adam Ahrens on 5/25/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import SwiftUI
import Combine

struct Search: View {
  @Binding var text: String
  
    var body: some View {
      HStack {
        HStack {
          Image(systemName: "magnifyingglass")
          
          TextField("Search", text: $text)
            .foregroundColor(.primary)
        }
      }
      .padding(.horizontal)
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search()
    }
}
