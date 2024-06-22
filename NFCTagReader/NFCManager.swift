//
//  NFCManager.swift
//  universalLinkDemo
//
//  Created by Itsuki on 2024/06/16.
//


import Foundation
import CoreNFC


struct NFCDataModel: Codable {
    var id: String
    var favorite: String
}


class NFCManager: NSObject, NFCNDEFReaderSessionDelegate, ObservableObject {
    private var readerSession: NFCNDEFReaderSession?
    private var sessionMode: NFCSessionMode = .scan
    
    @Published var message: String = ""
    
    
    enum NFCSessionMode {
        case scan
        case write
    }
    
    enum NFCError: Error {
        case recordCreation
    }

    func scan() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("This device doesn't support tag scanning. ")
            return
        }

        self.sessionMode = .scan
        readerSession = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: true)
        readerSession?.alertMessage = "Get Closer to the Tag to Scan!"
        readerSession?.begin()

    }
    
    
    func write() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("This device doesn't support tag scanning. ")
            return
        }
        
        self.sessionMode = .write
        readerSession = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: true)
        readerSession?.alertMessage = "Get Closer to the Tag to Write!"
        readerSession?.begin()
    }
    
    
    // MARK: delegate methods
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Error handling
        print("didInvalidateWithError: \(error)")
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                DispatchQueue.main.async {
                    self.message = "Session invalidate with error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // for scanning NFC Data
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]){ }
    
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {
        let retryInterval = DispatchTimeInterval.milliseconds(500)

        if tags.count > 1 {
            // Restart polling in 500 milliseconds.
            session.alertMessage = "More than 1 tag is detected. Please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        guard let tag = tags.first else {
            print("not able to get the first tag")
            session.alertMessage = "not able to get the first tag, please try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        DispatchQueue.main.async {
            self.message = ""
        }

        Task {
            
            do {
                try await session.connect(to: tag)
                let (status, _) = try await tag.queryNDEFStatus()
                
                switch status {
                case .notSupported:
                    session.alertMessage = "Tag is not NDEF compliant."
                case .readOnly:
                    if (sessionMode == .scan) {
                        print("reading!")
                        let ndefMessage = try await tag.readNDEF()
                        let processedMessage = try processNFCNDEFMessage(ndefMessage)
                        DispatchQueue.main.async {
                            self.message = processedMessage
                        }
                    } else {
                        session.alertMessage = "Tag is read only."
                    }
                case .readWrite:
                    
                    if (sessionMode == .scan) {
                        print("reading!")
                        let ndefMessage = try await tag.readNDEF()
                        let processedMessage = try processNFCNDEFMessage(ndefMessage)
                        DispatchQueue.main.async {
                            self.message = processedMessage
                        }
                    } else {
                        let message = try createNFCNDEFMessage()
                        try await tag.writeNDEF(message)
                    }
                    
                @unknown default:
                    session.alertMessage = "Unknown NDEF tag status."
                }
                
                session.invalidate()

            } catch(let error) {
                print("failed with error: \(error.localizedDescription)")
                session.alertMessage = "Failed to read/write tags."
                session.invalidate()
            }
        }
    }
    
    
    private func createNFCNDEFMessage() throws -> NFCNDEFMessage {
  
        let dataModel = NFCDataModel(id: "itsuki in \(Date())!", favorite: "Pikachu x \(Int.random(in: 1..<100))")
        let data = try JSONEncoder().encode(dataModel)
        print(String(data: data, encoding: .utf8) ?? "Bad data")
        guard let type = "application/json".data(using: .utf8) else {throw NFCError.recordCreation}
        let payloadData = NFCNDEFPayload(format: .media, type: type, identifier: Data(), payload: data, chunkSize: 0)
        
        guard let payloadUrl = NFCNDEFPayload.wellKnownTypeURIPayload(string: "https://852b-1-21-115-205.ngrok-free.app") else {
            throw NFCError.recordCreation
        }

        let message = NFCNDEFMessage(records: [payloadUrl, payloadData])
        return message
        
    }
    
    
    func processNFCNDEFMessage(_ message: NFCNDEFMessage) throws -> String{
        let records = message.records
        var message = ""

        for record in records {
            print(record.typeNameFormat.description)
            switch record.typeNameFormat {
            case .nfcWellKnown:
                if let url = record.wellKnownTypeURIPayload() {
                    message += "url: \(url.absoluteString). "
                }
                let (text, locale) = record.wellKnownTypeTextPayload()
                if let text = text, let locale = locale {
                    message += "Text: \(text) with Locale: \(locale). "
                }
                
            case .absoluteURI:
                if let text = String(data: record.payload, encoding: .utf8) {
                    message += "absoluteURI: \(text). "
                }
            case .media:
                let type = record.type
                print(String(data: type, encoding: .utf8) ?? "type unavailable")

                let data = record.payload
                let dataString = String(data: data, encoding: .utf8)
                print(dataString ?? "data unavailable")
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    let result  = try decoder.decode(NFCDataModel.self, from: data)
                    print("\(result.id): \(result.favorite)")
                    
                    message += "Json Data: \(result.id) loves \(result.favorite). "
                    
                } catch (let error) {
                    print("decode fail with error: \(error)")
                    throw error
                }

            case .nfcExternal, .empty, .unknown, .unchanged:
                continue
            @unknown default:
                continue
            }

            print("---------")

        }
        print("---------------------------")
        
        return message
    }
    
}


extension NFCTypeNameFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nfcWellKnown: return "NFC Well Known type"
        case .media: return "Media type"
        case .absoluteURI: return "Absolute URI type"
        case .nfcExternal: return "NFC External type"
        case .unknown: return "Unknown type"
        case .unchanged: return "Unchanged type"
        case .empty: return "Empty payload"
        @unknown default: return "Invalid data"
        }
    }
}
