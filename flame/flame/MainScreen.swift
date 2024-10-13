//
//  MainScreen.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import SwiftUI

struct MainScreen<T: FireplaceService>: View {
    @EnvironmentObject var fireplaceService: T
    @State var selectedFireplace: Fireplace?
    @State var currentTime: UInt16 = 30
    @State var isOn = false
    var mainButtonSize: CGFloat { isOn ? 80 : 180 }

    var body: some View {
        ZStack {
            BackgroundView(isOn: isOn)
            controlsView
            VStack {
                Picker(options: fireplaceService.fireplaces, currentlySelected: $selectedFireplace, placeholder: "SELECT FIREPLACE") { _ in
                    self.selectedFireplace = selectedFireplace
                }
                Spacer()
            }
        }
        .onAppear {
            self.selectedFireplace = fireplaceService.fireplaces.first { $0.id == self.selectedFireplace?.id } ?? fireplaceService.fireplaces.first
        }
        .onChange(of: fireplaceService.fireplaces) { _ in
            self.selectedFireplace = fireplaceService.fireplaces.first { $0.id == self.selectedFireplace?.id } ?? fireplaceService.fireplaces.first
            switch self.selectedFireplace?.status ?? .unknown {
            case let .on(timeRemaining: timeRemaining):
                self.currentTime = UInt16(ceil(timeRemaining / 60))
                self.isOn = true
            default:
                self.isOn = false
            }
        }
    }

    var controlsView: some View {
        ZStack {
            VStack {
                Spacer()

                if isOn {
                    Spacer()
                }

                onView // This is shown all the time and animated in and out

                if isOn {
                    Spacer()
                }
            }
            VStack {
                if isOn {
                    Spacer()
                }
                mainButton
            }
        }
        .animation(.easeIn, value: isOn)
    }

    var mainButton: some View {
        // This is both the on and the off button
        Button(
            action: {
                guard let selectedFireplace = selectedFireplace else { return }
                Task {
                    if isOn {
                        await fireplaceService.turnOffFireplace(selectedFireplace)
                    } else {
                        await fireplaceService.turnOnFireplace(selectedFireplace, minutes: fireplaceService.defaultMinutes)
                    }
                }
            },
            label: {
                if isOn {
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
        .buttonStyle(GlassButtonStyle(bottomText: isOn ? "stop" : nil))
        .frame(width: mainButtonSize, height: mainButtonSize)
    }

    var onView: some View {
        HStack {
            Button(
                action: {
                    Task {
                        guard let selectedFireplace = selectedFireplace else { return }
                        self.currentTime = max(self.currentTime - 10, 10)
                        let _ = await fireplaceService.turnOnFireplace(selectedFireplace, minutes: self.currentTime)
                    }
                },
                label: {
                    Text("-10")
                }
            )
            .buttonStyle(GlassButtonStyle())
            .frame(width: 64)
            .offset(x: isOn ? 0 : -200)
            Spacer()
            VStack(spacing: -15) {
                Text("\(currentTime)")
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
            .opacity(isOn ? 1.0 : 0.0)
            Spacer()
            Button(
                action: {
                    Task {
                        guard let selectedFireplace = selectedFireplace else { return }
                        self.currentTime = min(self.currentTime + 10, 120)
                        let _ = await fireplaceService.turnOnFireplace(selectedFireplace, minutes: self.currentTime)
                    }
                },
                label: {
                    Text("+10")
                }
            )
            .buttonStyle(GlassButtonStyle())
            .frame(width: 64)
            .offset(x: isOn ? 0 : 200)
        }
        .padding(.horizontal, 20)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen<PreviewFireplaceService>()
            .environmentObject(PreviewFireplaceService())
    }
}
