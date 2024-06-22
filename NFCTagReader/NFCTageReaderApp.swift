//
//  universalLinkDemoApp.swift
//  universalLinkDemo
//
//  Created by Itsuki on 2024/06/16.
//

import SwiftUI

@main
struct NFCTageReaderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NFCView()
        }
    }
}
