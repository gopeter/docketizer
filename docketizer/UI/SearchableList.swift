//
//  SearchableList.swift
//  docketizer
//
//  Created by Peter Oesteritz on 15.04.25.
//

import DocketAPI
import Foundation
import SwiftUI

struct SearchableList<Item: Hashable, Label: View>: View {
    @State private var selection: Int = 0
    @State private var search: String = ""
    @FocusState var focused: Bool

    var items: [Item]
    var filter: (_ by: String) -> Void
    var labelFormatter: (_ for: Item, _ isSelected: Bool) -> Label
    var select: (_ ticket: Item) -> Void
    var close: () -> Void
    var placeholder: String
    var defaultSelection: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(placeholder, text: $search)
                .textFieldStyle(.roundedBorder)
                .padding(.bottom, 6)
                .onChange(of: search) { oldValue, newValue in
                    selection = 0
                    filter(newValue)
                }
                .onKeyPress(.downArrow) {
                    if selection < items.count - 1 {
                        selection += 1
                    }
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    if selection > 0 {
                        selection -= 1
                    }
                    return .handled
                }
                .onKeyPress(.return) {
                    select(items[selection])
                    filter("")
                    return .handled
                }
                .onKeyPress(.escape) {
                    close()
                    return .handled
                }
                .focused($focused)
                .onAppear {
                    self.focused = true
                    selection = 0
                }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.1) { index, item in
                            let isSelected = selection == index

                            VStack(alignment: .leading) {
                                labelFormatter(item, isSelected)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                isSelected ? Color.accentColor : Color.clear
                            )
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selection = index
                                select(item)
                                filter("")
                            }
                            .padding(.bottom, (index == items.endIndex - 1) ? 0 : 5)
                            .id(index)
                        }
                    }
                }
                .frame(maxHeight: 300)
                .onChange(of: selection) { oldValue, newValue in
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }.onAppear {
            if defaultSelection != nil {
                selection = defaultSelection!
            }
        }
    }
}
