//
//  ContentView.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import SwiftUI

struct MainScreen<T: FireplaceService>: View {
  @EnvironmentObject var fireplaceService: T
  @State var selectedFireplace: Fireplace?
  @State var currentTime: UInt16 = 30

  var body: some View {
    ZStack {
      BackgroundView(isOn: self.selectedFireplace?.status.isOn ?? false)
      VStack {
        Spacer()
        switch self.selectedFireplace?.status ?? .unknown {
          case .off:
            offView
          case .on(_):
            onView
          case .unknown:
            Text("OH NO")
          }
        Spacer()
      }
      .animation(.easeIn(duration: 0.1), value: self.selectedFireplace?.status)

      VStack {
        Picker(options: fireplaceService.fireplaces, currentlySelected: $selectedFireplace, placeholder: "SELECT FIREPLACE") { fireplace in
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
      case .on(timeRemaining: let timeRemaining):
        self.currentTime = UInt16(ceil(timeRemaining / 60))
      default:
        break
      }
    }
  }

  var offView: some View {
    StartButton()
      .onTapGesture {
        Task {
          guard let selectedFireplace = selectedFireplace else { return }
          let _ = await fireplaceService.turnOnFireplace(selectedFireplace, minutes: self.currentTime) // TODO(nsillik): make this take into account the number
        }
      }
  }

  
  var onView: some View {
    VStack {
      Spacer()
      HStack {
        Image("lowerButton")
          .onTapGesture {
            Task {
              guard let selectedFireplace = selectedFireplace else { return }
              self.currentTime = max(self.currentTime - 10, 10)
              let _ = await fireplaceService.turnOnFireplace(selectedFireplace, minutes: self.currentTime)
            }
          }
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
        Spacer()
        Image("raiseButton")
          .onTapGesture {
            Task {
              guard let selectedFireplace = selectedFireplace else { return }
              self.currentTime = min(self.currentTime + 10, 120)
              let _ = await fireplaceService.turnOnFireplace(selectedFireplace, minutes: self.currentTime)
            }
          }
      }.padding(.horizontal, 20)
      Spacer()
      Image("stopButton")
        .onTapGesture {
          Task {
            guard let selectedFireplace = selectedFireplace else { return }
            let _ = await fireplaceService.turnOffFireplace(selectedFireplace)
          }
        }
    }
  }

  struct Row: View {
    @State var fireplace: Fireplace

    var body: some View {
      HStack {
        Image(systemName: fireplace.status == .off ? "flame" : "flame.fill")
          .foregroundColor(fireplace.status == .off ? Color.gray : Color.orange)
          .font(.title)
        VStack(alignment: .leading) {
          Text(fireplace.name)
            .font(.body)
          if case let .on(timeRemaining) = fireplace.status {
            Text("\(timeRemaining)")
              .font(.caption)
              .foregroundColor(.gray)
          }
        }
      }
      .padding(16)
    }
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    MainScreen<PreviewFireplaceService>()
      .environmentObject(PreviewFireplaceService())
  }
}
