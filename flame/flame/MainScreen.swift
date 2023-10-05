//
//  ContentView.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import SwiftUI

struct MainScreen<T: FireplaceService>: View {
  @EnvironmentObject var fireplaceService: T
  @State var fireplaces: [Fireplace] = []
  @State var selectedFireplace: Fireplace?

  var body: some View {
    ZStack {
      BackgroundView(isOn: selectedFireplace?.status.isOn ?? false)
      VStack {
        Spacer()
          switch selectedFireplace?.status {
          case .off:
            offView
          case .on(_):
            onView
          case .unknown:
            Text("OH NO")
          case nil:
            EmptyView()
          }
        Spacer()
      }

      VStack {
        Picker(options: fireplaces, currentlySelected: $selectedFireplace, placeholder: "SELECT FIREPLACE") { fireplace in
          self.selectedFireplace = selectedFireplace
        }
        Spacer()
      }
    }
    .onAppear {
      self.fireplaces = fireplaceService.fireplaces
    }
    .onChange(of: fireplaceService.fireplaces) { fireplaces in
      self.fireplaces = fireplaces
    }
    .onChange(of: self.fireplaces) { _ in
      if (self.selectedFireplace == nil) {
        self.selectedFireplace = self.fireplaces.first
      }
    }
  }

  var offView: some View {
    StartButton()
      .onTapGesture {
        Task {
          guard let selectedFireplace = selectedFireplace else { return }
          let _ = await fireplaceService.turnOnFireplace(selectedFireplace, minutes: 30) // TODO(nsillik): make this take into account the number
        }
      }
  }

  
  var onView: some View {
    Text("IT'S ON BABY")
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
