//
//  BackgroundView.swift
//  flame
//
//  Created by Nick Sillik on 10/4/23.
//

import SwiftUI

struct BackgroundView: View {
    var isOn: Bool

    var body: some View {
        Group {
            ZStack {
                onGradient
                    .tag("h")
                    .offset(x: -200, y: -200)
                    .opacity(isOn ? 1.0 : 0.0)
                onGradient
                    .offset(x: 200, y: 200)
                    .opacity(isOn ? 1.0 : 0.0)
                offGradient
                    .tag("h")
                    .offset(x: -80, y: 200)
                    .opacity(isOn ? 0.0 : 1.0)
            }
        }
        .animation(.easeIn, value: isOn)
        .background(Color.black)
    }

    var offGradient: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color.clear.opacity(0), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.31, green: 0.42, blue: 0.53), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                )
                .cornerRadius(575)
                .blur(radius: 175)
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color.clear.opacity(0), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.31, green: 0.42, blue: 0.53).opacity(0.2), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                )
                .blur(radius: 100)
        }
    }

    var onGradient: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 1, green: 0.31, blue: 0.09).opacity(0), location: 0.00),
                            Gradient.Stop(color: Color(red: 1, green: 0.26, blue: 0.09), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                )
                .blur(radius: 100)
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.51, green: 0.22, blue: 0.17), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.82, green: 0.64, blue: 0.17), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                )
                .cornerRadius(493.44238)
                .blur(radius: 150)
        }
    }
}

#Preview {
    Group {
        BackgroundView(isOn: true)
            .previewDisplayName("ON")
        BackgroundView(isOn: false)
            .previewDisplayName("OFF")
    }
}
