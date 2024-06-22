//
//  NFCView.swift
//  universalLinkDemo
//
//  Created by Itsuki on 2024/06/16.
//


import SwiftUI

struct NFCView: View {
    @ObservedObject private var readerManager = NFCManager()
    @EnvironmentObject var sceneDelegate: SceneDelegate

    var body: some View {
        VStack(spacing: 20) {
            
            HStack(spacing: 30) {
                Button(action: {
                    readerManager.scan()
                }, label: {
                    Text("Scan!")
                })
                .foregroundStyle(Color.white)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16))
                
                Button(action: {
                    readerManager.write()
                }, label: {
                    Text("Write!")
                })
                .foregroundStyle(Color.white)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16))

            }
            
            Spacer()
                .frame(height: 30)

            if (!readerManager.message.isEmpty) {
                Text(readerManager.message)
                    .foregroundStyle(Color.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16))
            }
            
            if (!sceneDelegate.message.isEmpty) {
                Text(sceneDelegate.message)
                    .foregroundStyle(Color.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16))
            }

        }
        .padding(.top, 100)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray.opacity(0.2))
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb, perform: { userActivity in
            sceneDelegate.processUserActivity(userActivity)
        })
    }
}

#Preview {
    NFCView()
}
