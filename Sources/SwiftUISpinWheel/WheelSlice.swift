//
//  File.swift
//  
//
//  Created by ADyatkov on 08.09.2022.
//

import SwiftUI

@available(iOS 14.0, *)
struct WheelSlice<Label>: View where Label: View {

    let label: () -> Label
    let size: Angle
    let color: Color
    let includeOverlap: Bool

    init(size: Angle, color: Color, includeOverlap: Bool = true, @ViewBuilder label: @escaping () -> Label) {
        self.label = label
        self.size = size
        self.color = color
        self.includeOverlap = includeOverlap
    }

    var body: some View {
        ZStack(alignment: .top) {
            WheelSliceShape(
                sliceSize: size,
                includeOverlap: includeOverlap
            ).fill(color)

            label()
                .offset(x: 0, y: 12)
        }
    }
}
