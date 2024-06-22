//
//  SceneDelegate.swift
//  universalLinkDemo
//
//  Created by Itsuki on 2024/06/16.
//

import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {
    @Published var message: String = ""
    
    private let nfcManager = NFCManager()
    
    func scene(_ scene: UIScene, willConnectTo
               session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let userActivity = connectionOptions.userActivities.first,
            userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return
        }
        
        processUserActivity(userActivity)

    }
    
    func processUserActivity(_ userActivity: NSUserActivity) {
        let ndefMessage = userActivity.ndefMessagePayload
        // Confirm that the NSUserActivity object contains a valid NDEF message.

        guard ndefMessage.records.count > 0,
           ndefMessage.records[0].typeNameFormat != .empty else {
               return
        }
        
        let message = try? nfcManager.processNFCNDEFMessage(ndefMessage)
        DispatchQueue.main.async {
            self.message = message ?? ""
        }
    }

}
