//////////////////////////////////////////////////////////////////////////////////
//
//  SYMBIOSE
//  Copyright 2023 Symbiose Technologies, Inc
//  All Rights Reserved.
//
//  NOTICE: This software is proprietary information.
//  Unauthorized use is prohibited.
//
// SwiftUIOverlayContainer
// Created by: Ryan Mckinney on 9/25/24
//
////////////////////////////////////////////////////////////////////////////////

import Foundation
import SwiftUI


public extension View {

    func swipableDismissal(_ axes: [InteractiveDismissal.ClosableAxes],
                           dismissAction: @escaping () -> Void,
                           onPartialClose: InteractiveDismissal.PartialDismissalCallback? = nil) -> some View {
        modifier(
            InteractiveDismissal(
                dismissAction,
                onPartialClose: onPartialClose,
                axes: axes
            ))
    }

    func swipableDismissalWithBg<B: View>(_
                                          axes: [InteractiveDismissal.ClosableAxes],
                                          dismissAction: @escaping () -> Void,
                                          bgBuilder: @escaping () -> B,
                           onPartialClose: InteractiveDismissal.PartialDismissalCallback? = nil) -> some View {
        modifier(
            InteractiveDismissalWithBg(
                dismissAction,
                onPartialClose: onPartialClose,
                axes: axes,
                bg: bgBuilder
            ))
    }
}



public extension CGFloat {
    func opacityFromDismissalPercentage() -> CGFloat {
        // Quadratic curve for non-linear effect
        return 1.0 - pow(self, 2)
    }
}




public struct InteractiveDismissal: ViewModifier {
    public enum ClosableAxes: CaseIterable, Equatable, Hashable {
        case up
        case down
        case left
        case right
    }
    public struct PartialClose: Equatable {
        public let offset: CGSize
        public let closePercentage: CGFloat
    }

    public typealias PartialDismissalCallback = (PartialClose) -> Void

    let dismissAction: () -> Void
    let partialCloseCb: PartialDismissalCallback?

    @State var offset: CGSize = .zero

    let closeVerticalThreshold: CGFloat = 200.0
    let closeHorizontalThreshold: CGFloat = 50.0
    let minimumDistanceToStart: CGFloat = 5.0
    let closableAxes: [ClosableAxes]

    public init(_ dismissAction: @escaping () -> Void,
                onPartialClose: PartialDismissalCallback?,
                axes: [ClosableAxes] = [.down]) {
        self.dismissAction = dismissAction
        self.partialCloseCb = onPartialClose
        self.closableAxes = axes
    }

    public func body(content: Content) -> some View {
        let closeGesture = DragGesture(minimumDistance: self.minimumDistanceToStart)
            .onChanged {
                offset = closeSize(from: $0.translation)
                //call the partialclose callback
                let percentage = closePercentage(from: offset)
                partialCloseCb?(PartialClose(offset: offset, closePercentage: percentage))
            }
            .onEnded {
                let predictedTranslation = $0.predictedEndTranslation
                let predictedShouldDismiss = shouldDismiss(from: predictedTranslation)

//                if predictedShouldDismiss {
//                    dismissAction()
//                } else {
////                    offset = .zero
//                    withAnimation(.spring()) {
//                        offset = .zero
//                    }
//                }

                if predictedShouldDismiss {
                    //Experimental to "throw"
                    withAnimation(.spring()) {
                        offset = closeSize(from: predictedTranslation)
                        dismissAction()
                    }
                } else {
                    withAnimation(.spring()) {
                        offset = .zero
                    }
                }

            }

        content
            .offset(offset)
            .simultaneousGesture(closeGesture)

    }

    func closeSize(from size: CGSize) -> CGSize {
        var width = size.width
        var height = size.height

        if !closableAxes.contains(.left) && width < 0 {
            width = 0
        }
        if !closableAxes.contains(.right) && width > 0 {
            width = 0
        }
        if !closableAxes.contains(.up) && height < 0 {
            height = 0
        }
        if !closableAxes.contains(.down) && height > 0 {
            height = 0
        }
        return CGSize(width: width, height: height)
    }

    
    func closePercentage(from size: CGSize) -> CGFloat {
        let horizontalPercentage = max(min(abs(size.width) / closeHorizontalThreshold, 1.0), 0.0)
        let verticalPercentage = max(min(abs(size.height) / closeVerticalThreshold, 1.0), 0.0)
        return max(horizontalPercentage, verticalPercentage)
    }




    func shouldDismiss(from size: CGSize) -> Bool {
        if closableAxes.contains(.down) && size.height >= closeVerticalThreshold {
            return true
        }
        if closableAxes.contains(.up) && -size.height >= closeVerticalThreshold {
            return true
        }
        if closableAxes.contains(.right) && size.width >= closeHorizontalThreshold {
            return true
        }
        if closableAxes.contains(.left) && -size.width >= closeHorizontalThreshold {
            return true
        }
        return false
    }

}




public struct InteractiveDismissalWithBg<Bg: View>: ViewModifier {

    let dismissAction: () -> Void
    let partialCloseCb: InteractiveDismissal.PartialDismissalCallback?
    let backgroundBuilder: () -> Bg


    let closableAxes: [InteractiveDismissal.ClosableAxes]

    public init(_ dismissAction: @escaping () -> Void,
                onPartialClose: InteractiveDismissal.PartialDismissalCallback?,
                axes: [InteractiveDismissal.ClosableAxes] = [.down],
                @ViewBuilder bg: @escaping () -> Bg
    ) {
        self.dismissAction = dismissAction
        self.partialCloseCb = onPartialClose
        self.closableAxes = axes
        self.backgroundBuilder = bg
    }

    @State var bgOpacity: CGFloat = 1.0


    public func body(content: Content) -> some View {
        content
            .background(
                self.backgroundBuilder()
                    .opacity(bgOpacity)
            )
            .swipableDismissal(self.closableAxes,
                               dismissAction: self.dismissAction,
                               onPartialClose: self.onPartialClose(_:))
    }


    func onPartialClose(_ partialClose: InteractiveDismissal.PartialClose) {
        self.bgOpacity = partialClose.closePercentage.opacityFromDismissalPercentage()
        self.partialCloseCb?(partialClose)
    }



}
