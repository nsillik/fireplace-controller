//
//  AppScreen.swift
//  Flame
//
//  Created by Nick Sillik on 3/9/26.
//

import SwiftUI
import ComposableArchitecture

struct AppScreen: View {
    
    @Bindable
    var store: StoreOf<AppReducer>
    
    var mainButtonSize: CGFloat { store.isOn ? 80 : 180 }

    var body: some View {
        ZStack {
            BackgroundView(isOn: store.isOn)
            controlsView
            VStack {
                Picker(options: store.availableFireplaces, currentlySelected: $store.selectedFireplace.sending(\.selectFireplace), placeholder: "SELECT FIREPLACE") { _ in
                }
                Spacer()
            }
        }
        .onAppear {
            store.send(.didLoad)
        }
    }

    var controlsView: some View {
        ZStack {
            VStack {
                Spacer()

                if store.isOn {
                    Spacer()
                }

                onView // This is shown all the time and animated in and out

                if store.isOn {
                    Spacer()
                }
            }
            VStack {
                if store.isOn {
                    Spacer()
                }
                mainButton
            }
        }
        .animation(.easeIn, value: store.isOn)
    }

    var mainButton: some View {
        // This is both the on and the off button
        Button(
            action: {
                if store.isOn {
                    store.send(.turnOffFireplace(store.selectedFireplace))
                } else {
                    store.send(.turnOnFireplace(store.selectedFireplace))
                }
            },
            label: {
                if store.isOn {
                    Image("flameOff")
                } else {
                    VStack(spacing: 12) {
                        Image("flameOn")
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
        )
        .buttonStyle(GlassButtonStyle(bottomText: store.isOn ? "stop" : nil))
        .frame(width: mainButtonSize, height: mainButtonSize)
    }

    var onView: some View {
        HStack {
            Button(
                action: {
                    store.send(.incrementTime(-10))
                },
                label: {
                    Text("-10")
                }
            )
            .buttonStyle(GlassButtonStyle())
            .frame(width: 64)
            .offset(x: store.isOn ? 0 : -200)
            Spacer()
            VStack(spacing: -15) {
                Text("\(store.currentTime)")
                    .font(
                        Font.custom("SF Pro Display", size: 120)
                            .weight(.light)
                    )
                    .kerning(4)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                Text("MINUTES")
                    .font(
                        Font.custom("SF Pro Display", size: 12)
                            .weight(.light)
                    )
                    .kerning(4)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
            }
            .opacity(store.isOn ? 1.0 : 0.0)
            Spacer()
            Button(
                action: {
                    store.send(.incrementTime(10))
                },
                label: {
                    Text("+10")
                }
            )
            .buttonStyle(GlassButtonStyle())
            .frame(width: 64)
            .offset(x: store.isOn ? 0 : 200)
        }
        .padding(.horizontal, 20)
    }
}
