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


extension View {
    
    /// Composite background view of identifiable view in stacking mode, used in compositeContainerView method
    ///
    /// Including transition of background and dismiss action ( tapToDismiss is true )
    @ViewBuilder
    func compositeBackgroundFor(
        identifiableView: IdentifiableContainerView,
        containerConfiguration: ContainerConfigurationProtocol,
        dismissAction: @escaping () -> Void
    ) -> some View {
        let backgroundStyle = ContainerBackgroundStyle.merge(
            containerBackgroundStyle: containerConfiguration.backgroundStyle,
            viewBackgroundStyle: identifiableView.configuration.backgroundStyle,
            containerViewDisplayType: containerConfiguration.displayType
        )
        let backgroundTransition = identifiableView.configuration.backgroundTransitionStyle
        #if !os(tvOS)
        let tapToDismiss = Bool.merge(
            containerTapToDismiss: containerConfiguration.tapToDismiss,
            viewTapToDismiss: identifiableView.configuration.tapToDismiss,
            containerType: containerConfiguration.displayType
        )
        #endif
        backgroundStyle
            .view()
        #if !os(tvOS)
            .if(tapToDismiss) { $0.onTapGesture(perform: dismissAction) }
        #endif
            .transition(backgroundTransition.transition)
    }
}



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
           .ignoresSafeArea(type: containerConfiguration.bgIgnoresSafeArea)

       
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
