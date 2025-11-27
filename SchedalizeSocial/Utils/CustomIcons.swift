//
//  CustomIcons.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct InstagramIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Scale factors
        let scaleX = width / 24
        let scaleY = height / 24

        // Instagram camera icon path
        path.move(to: CGPoint(x: 7.8 * scaleX, y: 2 * scaleY))
        path.addLine(to: CGPoint(x: 16.2 * scaleX, y: 2 * scaleY))
        path.addCurve(
            to: CGPoint(x: 22 * scaleX, y: 7.8 * scaleY),
            control1: CGPoint(x: 19.4 * scaleX, y: 2 * scaleY),
            control2: CGPoint(x: 22 * scaleX, y: 4.6 * scaleY)
        )
        path.addLine(to: CGPoint(x: 22 * scaleX, y: 16.2 * scaleY))
        path.addCurve(
            to: CGPoint(x: 16.2 * scaleX, y: 22 * scaleY),
            control1: CGPoint(x: 22 * scaleX, y: 19.4 * scaleY),
            control2: CGPoint(x: 19.4 * scaleX, y: 22 * scaleY)
        )
        path.addLine(to: CGPoint(x: 7.8 * scaleX, y: 22 * scaleY))
        path.addCurve(
            to: CGPoint(x: 2 * scaleX, y: 16.2 * scaleY),
            control1: CGPoint(x: 4.6 * scaleX, y: 22 * scaleY),
            control2: CGPoint(x: 2 * scaleX, y: 19.4 * scaleY)
        )
        path.addLine(to: CGPoint(x: 2 * scaleX, y: 7.8 * scaleY))
        path.addCurve(
            to: CGPoint(x: 7.8 * scaleX, y: 2 * scaleY),
            control1: CGPoint(x: 2 * scaleX, y: 4.6 * scaleY),
            control2: CGPoint(x: 4.6 * scaleX, y: 2 * scaleY)
        )

        path.move(to: CGPoint(x: 7.6 * scaleX, y: 4 * scaleY))
        path.addCurve(
            to: CGPoint(x: 4 * scaleX, y: 7.6 * scaleY),
            control1: CGPoint(x: 5.6 * scaleX, y: 4 * scaleY),
            control2: CGPoint(x: 4 * scaleX, y: 5.6 * scaleY)
        )
        path.addLine(to: CGPoint(x: 4 * scaleX, y: 16.4 * scaleY))
        path.addCurve(
            to: CGPoint(x: 7.6 * scaleX, y: 20 * scaleY),
            control1: CGPoint(x: 4 * scaleX, y: 18.4 * scaleY),
            control2: CGPoint(x: 5.6 * scaleX, y: 20 * scaleY)
        )
        path.addLine(to: CGPoint(x: 16.4 * scaleX, y: 20 * scaleY))
        path.addCurve(
            to: CGPoint(x: 20 * scaleX, y: 16.4 * scaleY),
            control1: CGPoint(x: 18.4 * scaleX, y: 20 * scaleY),
            control2: CGPoint(x: 20 * scaleX, y: 18.4 * scaleY)
        )
        path.addLine(to: CGPoint(x: 20 * scaleX, y: 7.6 * scaleY))
        path.addCurve(
            to: CGPoint(x: 16.4 * scaleX, y: 4 * scaleY),
            control1: CGPoint(x: 20 * scaleX, y: 5.6 * scaleY),
            control2: CGPoint(x: 18.4 * scaleX, y: 4 * scaleY)
        )
        path.addLine(to: CGPoint(x: 7.6 * scaleX, y: 4 * scaleY))

        // Dot
        path.move(to: CGPoint(x: 17.25 * scaleX, y: 5.5 * scaleY))
        path.addArc(
            center: CGPoint(x: 17.25 * scaleX, y: 6.75 * scaleY),
            radius: 1.25 * scaleX,
            startAngle: .degrees(-90),
            endAngle: .degrees(270),
            clockwise: false
        )

        // Camera lens outer
        path.move(to: CGPoint(x: 17 * scaleX, y: 12 * scaleY))
        path.addArc(
            center: CGPoint(x: 12 * scaleX, y: 12 * scaleY),
            radius: 5 * scaleX,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        // Camera lens inner
        path.move(to: CGPoint(x: 15 * scaleX, y: 12 * scaleY))
        path.addArc(
            center: CGPoint(x: 12 * scaleX, y: 12 * scaleY),
            radius: 3 * scaleX,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        return path
    }
}

struct TikTokIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Scale factors
        let scaleX = width / 24
        let scaleY = height / 24

        // TikTok music note icon path
        // Converted from: M19.59,6.69c-1.38,-0.56 -2.39,-1.71 -2.69,-3.1...
        path.move(to: CGPoint(x: 19.59 * scaleX, y: 6.69 * scaleY))
        path.addCurve(
            to: CGPoint(x: 16.9 * scaleX, y: 3.59 * scaleY),
            control1: CGPoint(x: 18.21 * scaleX, y: 6.13 * scaleY),
            control2: CGPoint(x: 17.2 * scaleX, y: 4.98 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 16.81 * scaleX, y: 2.75 * scaleY),
            control1: CGPoint(x: 16.84 * scaleX, y: 3.32 * scaleY),
            control2: CGPoint(x: 16.81 * scaleX, y: 3.04 * scaleY)
        )
        path.addLine(to: CGPoint(x: 13.7 * scaleX, y: 2.75 * scaleY))
        path.addLine(to: CGPoint(x: 13.7 * scaleX, y: 14.13 * scaleY))
        path.addCurve(
            to: CGPoint(x: 10.64 * scaleX, y: 17.19 * scaleY),
            control1: CGPoint(x: 13.7 * scaleX, y: 15.82 * scaleY),
            control2: CGPoint(x: 12.33 * scaleX, y: 17.19 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 7.58 * scaleX, y: 14.13 * scaleY),
            control1: CGPoint(x: 8.95 * scaleX, y: 17.19 * scaleY),
            control2: CGPoint(x: 7.58 * scaleX, y: 15.82 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 10.64 * scaleX, y: 11.07 * scaleY),
            control1: CGPoint(x: 7.58 * scaleX, y: 12.44 * scaleY),
            control2: CGPoint(x: 8.95 * scaleX, y: 11.07 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 11.53 * scaleX, y: 11.2 * scaleY),
            control1: CGPoint(x: 10.95 * scaleX, y: 11.07 * scaleY),
            control2: CGPoint(x: 11.24 * scaleX, y: 11.12 * scaleY)
        )
        path.addLine(to: CGPoint(x: 11.53 * scaleX, y: 8.01 * scaleY))
        path.addCurve(
            to: CGPoint(x: 10.64 * scaleX, y: 7.95 * scaleY),
            control1: CGPoint(x: 11.24 * scaleX, y: 7.97 * scaleY),
            control2: CGPoint(x: 10.94 * scaleX, y: 7.95 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 4.39 * scaleX, y: 14.2 * scaleY),
            control1: CGPoint(x: 7.19 * scaleX, y: 7.95 * scaleY),
            control2: CGPoint(x: 4.39 * scaleX, y: 10.75 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 10.64 * scaleX, y: 20.45 * scaleY),
            control1: CGPoint(x: 4.39 * scaleX, y: 17.65 * scaleY),
            control2: CGPoint(x: 7.19 * scaleX, y: 20.45 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 16.89 * scaleX, y: 14.2 * scaleY),
            control1: CGPoint(x: 14.09 * scaleX, y: 20.45 * scaleY),
            control2: CGPoint(x: 16.89 * scaleX, y: 17.65 * scaleY)
        )
        path.addLine(to: CGPoint(x: 16.89 * scaleX, y: 9.41 * scaleY))
        path.addCurve(
            to: CGPoint(x: 21.25 * scaleX, y: 10.81 * scaleY),
            control1: CGPoint(x: 18.12 * scaleX, y: 10.29 * scaleY),
            control2: CGPoint(x: 19.63 * scaleX, y: 10.81 * scaleY)
        )
        path.addLine(to: CGPoint(x: 21.25 * scaleX, y: 7.7 * scaleY))
        path.addCurve(
            to: CGPoint(x: 19.59 * scaleX, y: 6.69 * scaleY),
            control1: CGPoint(x: 20.66 * scaleX, y: 7.7 * scaleY),
            control2: CGPoint(x: 20.1 * scaleX, y: 7.41 * scaleY)
        )
        path.closeSubpath()

        return path
    }
}

// View wrappers for easy use
struct InstagramIconView: View {
    var color: Color = .gray
    var size: CGFloat = 24

    var body: some View {
        InstagramIcon()
            .fill(color)
            .frame(width: size, height: size)
    }
}

struct TikTokIconView: View {
    var color: Color = .gray
    var size: CGFloat = 24

    var body: some View {
        TikTokIcon()
            .fill(color)
            .frame(width: size, height: size)
    }
}

struct XIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Scale factors (based on 24x24 viewbox)
        let scaleX = width / 24
        let scaleY = height / 24

        // X logo path - bold angular X
        // Top-right to bottom-left stroke
        path.move(to: CGPoint(x: 18.5 * scaleX, y: 3 * scaleY))
        path.addLine(to: CGPoint(x: 13.5 * scaleX, y: 10.5 * scaleY))
        path.addLine(to: CGPoint(x: 18.5 * scaleX, y: 18 * scaleY))
        path.addLine(to: CGPoint(x: 15.5 * scaleX, y: 21 * scaleY))
        path.addLine(to: CGPoint(x: 10.5 * scaleX, y: 13.5 * scaleY))
        path.addLine(to: CGPoint(x: 5.5 * scaleX, y: 21 * scaleY))
        path.addLine(to: CGPoint(x: 2.5 * scaleX, y: 18 * scaleY))
        path.addLine(to: CGPoint(x: 7.5 * scaleX, y: 10.5 * scaleY))
        path.addLine(to: CGPoint(x: 2.5 * scaleX, y: 3 * scaleY))
        path.addLine(to: CGPoint(x: 5.5 * scaleX, y: 0 * scaleY))
        path.addLine(to: CGPoint(x: 10.5 * scaleX, y: 7.5 * scaleY))
        path.addLine(to: CGPoint(x: 15.5 * scaleX, y: 0 * scaleY))
        path.closeSubpath()

        return path
    }
}

struct XIconView: View {
    var color: Color = .black
    var size: CGFloat = 24

    var body: some View {
        XIcon()
            .fill(color)
            .frame(width: size, height: size)
    }
}
