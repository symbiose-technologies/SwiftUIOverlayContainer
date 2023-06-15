//////////////////////////////////////////////////////////////////////////////////
//
//  SYMBIOSE
//  Copyright 2023 Symbiose Technologies, Inc
//  All Rights Reserved.
//
//  NOTICE: This software is proprietary information.
//  Unauthorized use is prohibited.
//
// 
// Created by: Ryan Mckinney on 6/13/23
//
////////////////////////////////////////////////////////////////////////////////

import Foundation
import SwiftUI



 struct StackingCompositeView: View {
    
    let identifiableView: IdentifiableContainerView
    let containerConfiguration: ContainerConfigurationProtocol
    let queueHandler: ContainerQueueHandler
    let containerName: String
    let containerFrame: CGRect
    
    let dismissAction: () -> Void
    let environmentValue: ContainerEnvironment
    
    init(identifiableView: IdentifiableContainerView,
         containerConfiguration: ContainerConfigurationProtocol,
         queueHandler: ContainerQueueHandler,
         containerName: String,
         containerFrame: CGRect,
         dismissAction: @escaping () -> Void,
         environmentValue: ContainerEnvironment
    ) {
        self.identifiableView = identifiableView
        self.containerConfiguration = containerConfiguration
        self.queueHandler = queueHandler
        self.containerName = containerName
        self.containerFrame = containerFrame
        self.dismissAction = dismissAction
        self.environmentValue = environmentValue
    
    }
    
    @State var backgroundOpacity: Double = 1.0
    
    @ViewBuilder
    var body: some View {
        let shadowStyle = ContainerViewShadowStyle.merge(
            containerShadow: containerConfiguration.shadowStyle,
            viewShadow: identifiableView.configuration.shadowStyle,
            containerViewDisplayType: containerConfiguration.displayType
        )

        let dismissGesture = ContainerViewDismissGesture.merge(
            containerGesture: containerConfiguration.dismissGesture, viewGesture: identifiableView.configuration.dismissGesture
        )

        let transition = AnyTransition.merge(
            containerTransition: containerConfiguration.transition,
            viewTransition: identifiableView.configuration.transition,
            containerViewDisplayType: containerConfiguration.displayType
        )

        let autoDismissStyle = ContainerViewAutoDismiss.merge(
            containerAutoDismiss: containerConfiguration.autoDismiss, viewAutoDismiss: identifiableView.configuration.autoDismiss
        )


        let compositingView = identifiableView.view
            .containerViewShadow(shadowStyle)
            .transition(transition)
            .dismissGesture(
                gestureType: dismissGesture,
                dismissAction: dismissAction,
                onPartialClose: self.onPartialClose
            )
            .autoDismiss(autoDismissStyle, dismissAction: dismissAction)
            .dismissViewWhenIsPresentedIsFalse(identifiableView.isPresented, preform: dismissAction)
            .environment(\.overlayContainer, environmentValue)

        // background + backgroundDismiss + view + gesture + shadow + transition + autoDismiss + isPresented + alignment + inset
        let backgroundOfIdentifiableView = compositeBackgroundFor(
            identifiableView: identifiableView, containerConfiguration: containerConfiguration, dismissAction: dismissAction
        )

        let alignment = Alignment.merge(
            containerAlignment: containerConfiguration.alignment,
            viewAlignment: identifiableView.configuration.alignment,
            containerViewDisplayType: containerConfiguration.displayType
        )
        
        // the current context of view is ZStack (GenericStack)
        backgroundOfIdentifiableView
            .opacity(self.backgroundOpacity)
            .zIndex(timeStamp: identifiableView.timeStamp, order: containerConfiguration.displayOrder, background: true)
        
        compositingView
            .padding(containerConfiguration.insets) // add insets for each view
            
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: alignment)
            .zIndex(timeStamp: identifiableView.timeStamp, order: containerConfiguration.displayOrder, background: false)
        
    }
    
    func onPartialClose(_ partialClose: InteractiveDismissal.PartialClose) -> Void {
//        print("onPartialClose: percentage: \(partialClose.closePercentage) offset: \(partialClose.offset)")
        
        let bgOpacity = partialClose.closePercentage.opacityFromDismissalPercentage()
//        let backgroundOpacity = 1.0 - partialClose.closePercentage
//        print("[new bg opacity] \(bgOpacity)")
        self.backgroundOpacity = bgOpacity
    }
    
}
