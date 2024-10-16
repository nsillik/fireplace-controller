//
//  Picker.swift
//  flame
//
//  Created by Nick Sillik on 10/4/23.
//

import SwiftUI

struct Picker<T: CustomStringConvertible & Hashable>: View {
    let options: [T]
    @Binding var currentlySelected: T?
    let placeholder: String
    let selected: (T) -> Void
    @State var expanded = false

    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Text(topText)
                    .tracking(4)
                    .font(Font.custom("SF Pro Display", size: 12)
                        .weight(.light))
                Image(systemName: "chevron.down")
                    .rotationEffect(expanded ? .degrees(180) : .zero, anchor: .center)
                    .animation(.linear(duration: 0.1), value: currentlySelected)
                    .frame(width: 18)
            }
            .safeAreaInset(edge: .top) {
                Text("").padding(.bottom, 16) // This is just to position the content correctly outside of the safe area while allowing the background to cover the safe area when the picker is open
            }
            if expanded {
                ForEach(options, id: \.self) { option in
                    HStack {
                        Image(systemName: "checkmark")
                            .opacity(currentlySelected == option ? 1.0 : 0.0)
                            .frame(width: 16)
                            .animation(.linear(duration: 0.1), value: currentlySelected)
                        Text(option.description)
                            .font(
                                Font.custom("SF Pro Display", size: 16)
                                    .weight(.light)
                            )
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .onTapGesture {
                                expanded = !expanded
                                currentlySelected = option
                                selected(option)
                                print(option)
                            }
                    }
                    .offset(x: -16)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(expanded ? Color.black : Color.clear)
        .clipShape(
            .rect(
                topLeadingRadius: 0,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: 0
            )
        )
        .onTapGesture {
            expanded = !expanded
        }
        .animation(.easeIn, value: expanded)
        .foregroundColor(.white)
        .edgesIgnoringSafeArea(.top)
    }

    var topText: String {
        switch expanded {
        case true:
            placeholder.uppercased()
        case false:
            currentlySelected?.description.uppercased() ?? "UNKNOWN"
        }
    }
}

struct Picker_PreviewProvider: PreviewProvider {
    static var previews: some View {
        ZStack {
            VStack {
                Spacer()
                Text("blah blah")
                Spacer()
            }
            .frame(width: .infinity, height: .infinity)
            .padding(30)
            .background(Color.orange.opacity(0.3))
            VStack {
                Picker<String>(
                    options: ["Living Room", "Dining Room", "Dungeon"],
                    currentlySelected: .constant("Living Room"),
                    placeholder: "Select Fireplace",
                    selected: { _ in
                    },
                    expanded: true
                )
                Spacer()
            }
        }
    }
}
