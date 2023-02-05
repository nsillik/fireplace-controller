//
//  ContentView.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import SwiftUI

struct ContentView<T: FireplaceService>: View {
  @EnvironmentObject var fireplaceService: T
  @State var fireplaces: [Fireplace] = []
  @State var selectedFireplace: Fireplace?
  @State var showFireplaceDetail: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      HeaderView(text: "flame", icon: Image(systemName: "flame.fill"))
        .foregroundColor(Color.red.opacity(0.8))
      Divider()
      ScrollView {
        VStack(alignment: .leading) {
          ForEach(fireplaces) { fireplace in
            Row(fireplace: fireplace)
              .onTapGesture {
                self.selectedFireplace = fireplace
              }
            Divider()
          }
          Spacer()
        }
      }
    }
    .padding()
    .sheet(isPresented: $showFireplaceDetail) {
      switch selectedFireplace {
      case .some(let fireplace):
        FireplaceDetail<T>(fireplace: Binding(get: {
          fireplaceService.fireplaces.first { $0 == fireplace }!
        }, set: { _, _ in

        }))
          .onDisappear {
            selectedFireplace = nil
          }
      case .none:
        EmptyView()
      }
    }
    .onChange(of: selectedFireplace) { newValue in
      withAnimation {
        showFireplaceDetail = selectedFireplace != nil
      }
    }
    .onAppear {
      self.fireplaces = fireplaceService.fireplaces
    }
    .onChange(of: fireplaceService.fireplaces) { fireplaces in
      self.fireplaces = fireplaces
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
    ContentView<LiveFireplaceService>()
      .environmentObject(LiveFireplaceService())
  }
}
