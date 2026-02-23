//
//  Binding+Deferred.swift
//  docketizer
//
//  Created by Peter Oesteritz on 23.05.25.
//

import SwiftUI

extension Binding {
    /// Returns a new Binding that defers all writes to the next run loop cycle.
    ///
    /// Use this to avoid "Publishing changes from within view updates is not allowed"
    /// warnings that occur when a SwiftUI control (e.g. Picker, Toggle) writes to a
    /// @Published property on an ObservableObject synchronously during a view update.
    func deferred() -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                DispatchQueue.main.async {
                    self.wrappedValue = newValue
                }
            }
        )
    }
}
