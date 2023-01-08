//
//  HeaderView.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import Foundation
import SwiftUI

struct HeaderView: View {
  var text: String
  var icon: Image?

  var body: some View {
    HStack {
      icon
      Text(text)
      Spacer()
    }
    .font(.largeTitle)
    .padding(16)
  }
}
