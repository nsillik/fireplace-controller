//
//  FireplaceDetail.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import Foundation
import SwiftUI

struct FireplaceDetail<T: FireplaceService>: View {
  @Binding var fireplace: Fireplace
  @AppStorage("org.sillik.flame.selectedTime") var selectedTime: Int = 30 // default to 30 minutes
  @EnvironmentObject var fireplaceService: T

  var body: some View {
    VStack(alignment: .leading) {
      HeaderView(text: fireplace.name, icon: Image(systemName: fireplace.status == .off ? "flame" : "flame.fill"))
      VStack(alignment: .leading) {
        HStack {
          Spacer()
          Button {
            Task {
              await fireplaceService.turnOnFireplace(fireplace, minutes: UInt16(truncatingIfNeeded: selectedTime))
            }
          } label: {
            Text("Start")
              .padding()
          }
          .disabled(fireplace.status != .off)

          Button {
            Task {
              await fireplaceService.turnOffFireplace(fireplace)
            }
          } label: {
            Text("Stop")
              .padding()
          }
          .disabled(fireplace.status == .off)
          Spacer()
        }

        HStack {
          VStack(alignment: .leading) {
            Text("\(selectedTime) minutes")
              .font(.headline)
            Text("running time")
              .font(.caption)
              .foregroundColor(.gray)
          }
          Spacer()
          Button {
            selectedTime = selectedTime - 10
          } label: {
            Text("-10")
              .padding()
          }
          .disabled(selectedTime <= 10)
          Button {
            selectedTime = selectedTime + 10
          } label: {
            Text("+10")
              .padding()
          }
          .disabled(selectedTime >= 120)
        }
        .disabled(fireplace.status != .off)

        Spacer()
      }
      .padding(.horizontal, 16)
      .buttonStyle(.bordered)
    }
  }
}

struct FireplaceDetail_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      FireplaceDetail<LiveFireplaceService>(fireplace: .constant(.init(ipAddress: "192.168.1.81", name: "Dog Crate Room", status: .on(timeRemaining: 23.3 * 60))))
        .previewDisplayName("On Fireplace")
      FireplaceDetail<LiveFireplaceService>(fireplace: .constant(.init(ipAddress: "192.168.1.82", name: "Dog Crate Room", status: .off)))
        .previewDisplayName("Off Fireplace")
    }
    .environmentObject(LiveFireplaceService())
  }
}
