//
//  File.swift
//  
//
//  Created by ADyatkov on 08.09.2022.
//

import SwiftUI

@available(iOS 14.0, *)
struct WheelSliceShape: Shape {
    let sliceSize: Angle
    let includeOverlap: Bool

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: rect.size.height / 2,
                startAngle: .degrees(-90) - (sliceSize / 2),
                endAngle: .degrees(-90) + (sliceSize / 2) + (includeOverlap ? sliceSize / 4 : .degrees(0)),
                clockwise: false)
        }
    }
}
