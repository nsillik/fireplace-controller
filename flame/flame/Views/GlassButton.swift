//
//  GlassButton.swift
//  flame
//
//  Created by Nick Sillik on 10/5/23.
//

import SwiftUI

struct GlassButtonStyle: ButtonStyle {
  let foregroundColor = Color.white
  let font = Font.custom("SF Pro Display", size: 16).weight(.light)

  // return the label unaltered, but add a hook to watch changes in configuration.isPressed
  func makeBody(configuration: Self.Configuration) -> some View {
    return ZStack {
      Group {
        Rectangle().opacity(0.0)
          .foregroundColor(.clear)
          .background(
            EllipticalGradient(
              stops: [
                Gradient.Stop(color: .white.opacity(0.2), location: 0.00),
                Gradient.Stop(color: .white.opacity(0), location: 1.00),
              ],
              center: UnitPoint(x: 0.5, y: 0)
            )
          )
          .blur(radius: 6)
        Rectangle().opacity(0.0)
          .background(
            EllipticalGradient(
              stops: [
                Gradient.Stop(color: .white.opacity(0.36), location: 0.00),
                Gradient.Stop(color: .white.opacity(0), location: 1.00),
              ],
              center: UnitPoint(x: 0.1, y: 0)
            )
          )
          .overlay(
            Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1)
          )
          .background(Circle().fill().foregroundColor(.white.opacity(0.1)))
          .clipShape(Circle())
      }
      .opacity(configuration.isPressed ? 0.75 : 1.0)
      .animation(.smooth(duration: 0.1), value: configuration.isPressed)
      configuration.label
        .padding()
        .foregroundColor(foregroundColor)
        .font(font)
    }
    .clipShape(Circle())
  }
}

struct GlassButtonLabel: View {
  var body: some View {
    VStack {
      
    }
  }
}

#Preview {
  ZStack {
    VStack {
      Spacer()
      Button {
        // nada
      } label: {
        Text("hi")
      }
      .buttonStyle(GlassButtonStyle())
      Spacer()
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.black)
}
