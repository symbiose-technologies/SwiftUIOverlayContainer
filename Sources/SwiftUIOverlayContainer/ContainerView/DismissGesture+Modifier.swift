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
//        bodyBuilder(content)
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


