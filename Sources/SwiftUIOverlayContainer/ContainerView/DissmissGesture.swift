//
//  DismissGesture.swift
//
//
//  Created by Yang Xu on 2022/3/5
//  Copyright © 2022 Yang Xu. All rights reserved.
//
//  Follow me on Twitter: @fatbobman
//  My Blog: https://www.fatbobman.com
//
// swiftlint:disable cyclomatic_complexity
import Foundation
import SwiftUI

/// Gesture for dismiss Container View
///
///   Convert the gesture's type to AnyGesture<Void> when using customGesture
///
///      let gesture = LongPressGesture(minimumDuration: 1, maximumDistance: 5).eraseToAnyGestureForDismiss()
///
///   Examples
///
///     var gesture:ContainerViewDismissGesture {
///            ContainerViewDismissGesture.merge(containerGesture: containerGesture, viewGesture: viewGesture)
///         }
///
///     containerView
///          .addDismissGesture(gestureType:gesture, dismissAction: some action)
///
public enum ContainerViewDismissGesture {
    case tap
    case doubleTap
    case swipeLeft
    case swipeRight
    case swipeUp
    case swipeDown
    case longPress(Double)
    case customGesture(AnyGesture<Void>)
    case disable
    case interactiveSwipe(axes: [InteractiveDismissal.ClosableAxes])
}

extension ContainerViewDismissGesture {
    /// generate the dismiss gesture with execution closure
    ///
    /// The dismiss Action not only includes the cancellation action of Overlay Container view,
    /// but also the dismiss closure specified by user
    func generateGesture(with dismissAction: @escaping DismissAction) -> AnyGesture<Void>? {
        // only support longPress in tvOS
        #if os(tvOS)
        switch self {
        case .longPress(let seconds):
            return LongPressGesture(minimumDuration: seconds).onEnded { _ in dismissAction() }.eraseToAnyGestureForDismiss()
        default:
            return nil
        }
        #else
        switch self {
        case .tap:
            return TapGesture(count: 1).onEnded { _ in dismissAction() }.eraseToAnyGestureForDismiss()
        case .doubleTap:
            return TapGesture(count: 2).onEnded { _ in dismissAction() }.eraseToAnyGestureForDismiss()
        case .longPress(let seconds):
            return LongPressGesture(minimumDuration: seconds).onEnded { _ in dismissAction() }.eraseToAnyGestureForDismiss()
        case .customGesture(let gesture):
            return gesture.onEnded { _ in dismissAction() }.eraseToAnyGestureForDismiss()
        case .disable:
            return nil
        case .swipeUp, .swipeDown, .swipeLeft, .swipeRight:
            return SwipeGesture(minimumDistance: 10, coordinateSpace: .global)
                .onEnded { direction in
                    switch (direction, self) {
                    case (.left, .swipeLeft):
                        dismissAction()
                    case (.right, .swipeRight):
                        dismissAction()
                    case (.up, .swipeUp):
                        dismissAction()
                    case (.down, .swipeDown):
                        dismissAction()
                    default:
                        break
                    }
                }
                .eraseToAnyGestureForDismiss()
        case .interactiveSwipe:
            return TapGesture(count: 1).onEnded { _ in dismissAction() }.eraseToAnyGestureForDismiss()

            
        }
        #endif
    }

    /// Provides the correct gesture of dismiss based on the container configuration and the container view configuration.
    ///
    /// Container view configuration's dismiss gesture has higher priority than the one of container configuration
    ///
    ///     container             view                    result
    ///
    ///         nil               nil                     disable
    ///         disable           disable                 disable
    ///         tap               nil                     tap
    ///         tap               disable                 disable
    ///         tap               swipeLeft               swipeLeft
    ///         nil               tap                     tap
    ///         nil               disable                 disable
    ///
    /// - Returns: ContainerViewDismissGesture
    static func merge(containerGesture: Self?, viewGesture: Self?) -> Self {
        guard let containerGesture = containerGesture else { return viewGesture ?? Self.disable }
        return viewGesture ?? containerGesture
    }
}

public extension Gesture {
    /// Erase SwiftUI Gesture to AnyGesture , and convert value to Void.
    ///
    /// Convert the gesture's type to AnyGesture<Void> when using customGesture
    ///
    ///      let gesture = LongPressGesture(minimumDuration: 1, maximumDistance: 5).eraseToAnyGestureForDismiss()
    ///
    func eraseToAnyGestureForDismiss() -> AnyGesture<Void> {
        AnyGesture(map { _ in () })
    }
}

#if !os(tvOS)
/// Swipe Gesture
///
/// Read my blog [post](https://fatbobman.com/posts/swiftuiGesture/) to learn how to customize gesture in SwiftUI.
struct SwipeGesture: Gesture {
    enum Direction: String {
        case left, right, up, down
    }

    typealias Value = Direction

    private let minimumDistance: CGFloat
    private let coordinateSpace: CoordinateSpace

    init(minimumDistance: CGFloat = 10, coordinateSpace: CoordinateSpace = .local) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
    }

    var body: AnyGesture<Value> {
        AnyGesture(
            DragGesture(minimumDistance: minimumDistance, coordinateSpace: coordinateSpace)
                .map { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height

                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount < 0 { return .left } else { return .right }
                    } else {
                        if verticalAmount < 0 { return .up } else { return .down }
                    }
                }
        )
    }
}
#endif

extension View {
    /// Add dismiss gesture to container view
    ///
    ///   Examples
    ///
    ///     var gesture:ContainerViewDismissGesture {
    ///            ContainerViewDismissGesture.merge(containerGesture: containerGesture, viewGesture: viewGesture)
    ///         }
    ///
    ///     containerView
    ///          .dismissGesture(gestureType:gesture, dismissAction: some action)
    ///
//    @ViewBuilder
//    func dismissGesture(gestureType: ContainerViewDismissGesture, dismissAction: @escaping () -> Void) -> some View {
//        if let gesture = gestureType.generateGesture(with: dismissAction) {
//            self.gesture(gesture)
//        } else { self }
//    }
    
    @ViewBuilder
    func dismissGesture(gestureType: ContainerViewDismissGesture,
                        dismissAction: @escaping () -> Void,
                        onPartialClose: InteractiveDismissal.PartialDismissalCallback? = nil
    ) -> some View {
        self
            .modifier(DismissGestureModifier(gestureType: gestureType,
                                             dismissAction: dismissAction,
                                             onPartialClose: onPartialClose))
    }
}

struct DismissGestureModifier: ViewModifier {
    
    let gesture: ContainerViewDismissGesture
    let dismissAction: () -> Void
    let onPartialClose: InteractiveDismissal.PartialDismissalCallback?
    
    
    init(gestureType: ContainerViewDismissGesture,
         dismissAction: @escaping () -> Void,
         onPartialClose: InteractiveDismissal.PartialDismissalCallback? = nil) {
        self.gesture = gestureType
        self.dismissAction = dismissAction
        self.onPartialClose = onPartialClose
    }
    
    func body(content: Content) -> some View {
        bodyBuilder(content)
    }
    
    @ViewBuilder
    func bodyBuilder(_ content: Content) -> some View {
        if let interactiveAxes = axesForInteractiveDismissal {
            content
                .swipableDismissal(interactiveAxes,
                                   dismissAction: dismissAction,
                                   onPartialClose: self.onPartialClose)
            
        } else if let anyGesture = resolvedGesture {
            content
                .gesture(anyGesture)
        } else {
            content
        }
        
    }
    
    var axesForInteractiveDismissal: [InteractiveDismissal.ClosableAxes]? {
        switch gesture {
        case let .interactiveSwipe(axes):
            return axes
        default:
            return nil
        }
    }
    
    var interactiveDismissal: Bool {
        switch gesture {
        case .interactiveSwipe:
            return true
        default:
            return false
        }
    }
    
    var resolvedGesture: AnyGesture<Void>? {
        return gesture.generateGesture(with: dismissAction)
    }
    
}



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

public struct InteractiveDismissal: ViewModifier {
    public enum ClosableAxes: Equatable, Hashable {
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
    
//    func closePercentage(from size: CGSize) -> CGFloat {
//        let horizontalPercentage = abs(size.width) / closeHorizontalThreshold
//        let verticalPercentage = abs(size.height) / closeVerticalThreshold
//        return max(horizontalPercentage, verticalPercentage)
//    }
    
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
