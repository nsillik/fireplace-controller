//
//  StartButton.swift
//  flame
//
//  Created by Nick Sillik on 10/4/23.
//

import SwiftUI

struct StartButton: View {
    var body: some View {
      ZStack {
        Image("glass")
        VStack(spacing: 0) {
          Image(systemName: "flame.fill")
            .font(
              Font.custom("SF Pro Display", size: 54)
                .weight(.semibold)
            )
            .multilineTextAlignment(.center)
            .foregroundColor(Color(red: 1, green: 0.31, blue: 0.09))
            .frame(width: 83.25, height: 81, alignment: .top)
          Text("START")
            .font(
              Font.custom("SF Pro Display", size: 12)
                .weight(.light)
            )
            .kerning(4)
            .multilineTextAlignment(.center)
            .foregroundColor(.white.opacity(0.8))
        }
      }
    }
}

#Preview {
    StartButton()
}
