//
//  AbletonLinkViewController.swift
//  Biofeedback-Orchestra-Listener
//
//  Created by Jason Snell on 4/27/24.
//

import SwiftUI
import UIKit

// A wrapper class to hold the UIViewController
//trying to save the VC without a wrapper wasn't working in ContentView
class ABLinkViewControllerWrapper: ObservableObject {
    @Published var viewController: UIViewController?
}

// Wrapper for your Ableton Link UIViewController
struct ABLinkViewController: UIViewControllerRepresentable {
    var viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        // Return the Ableton Link view controller you want to present
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Leave this empty if the view controller doesn't need updating
        uiViewController.view.backgroundColor = UIColor.white
    }
}
