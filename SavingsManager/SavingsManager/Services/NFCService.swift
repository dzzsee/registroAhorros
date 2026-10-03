import Foundation
import CoreNFC
import SwiftData

@MainActor
final class NFCService: NSObject, ObservableObject {
    static let shared = NFCService()

    @Published var isScanning = false
    @Published var scanError: String?
    @Published var lastScannedCard: SavingsCard?

    private var readSession: NFCNDEFReaderSession?
    private var writeSession: NFCNDEFReaderSession?
    private var writePayload: NDEFMessage?
    private var completion: ((Result<SavingsCard, Error>) -> Void)?
    private var writeCompletion: ((Result<Void, Error>) -> Void)?
    private var modelContext: ModelContext?

    private override init() {
        super.init()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func scanForCard() async throws -> SavingsCard {
        scanError = nil
        isScanning = true

        return try await withCheckedThrowingContinuation { continuation in
            self.completion = { result in
                self.isScanning = false
                continuation.resume(with: result)
            }

            guard NFCNDEFReaderSession.readingAvailable else {
                self.scanError = "NFC not available on this device"
                self.completion?(.failure(NFCError.notAvailable))
                self.completion = nil
                return
            }

            let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
            session.alertMessage = "Hold your savings card near the top of your iPhone"
            session.begin()
            self.readSession = session
        }
    }

    func writeBalance(to card: SavingsCard) async throws {
        isScanning = true
        scanError = nil

        return try await withCheckedThrowingContinuation { continuation in
            self.writeCompletion = { result in
                self.isScanning = false
                continuation.resume(with: result)
            }

            guard NFCNDEFReaderSession.readingAvailable else {
                self.scanError = "NFC not available on this device"
                self.writeCompletion?(.failure(NFCError.notAvailable))
                self.writeCompletion = nil
                return
            }

            let message = NDEFParser.createNDEFMessage(for: card)
            self.writePayload = message

            let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
            session.alertMessage = "Hold your card to save the new balance"
            session.begin()
            self.writeSession = session
        }
    }

    private func findOrCreateCard(uid: Data, ndefMessage: NFCNDEFMessage?) throws -> SavingsCard {
        guard let context = modelContext else {
            throw NFCError.noModelContext
        }

        let descriptor = FetchDescriptor<SavingsCard>(
            predicate: #Predicate { $0.cardUID == uid }
        )

        if let existingCard = try context.fetch(descriptor).first {
            if let message = ndefMessage,
               let parsedCard = NDEFParser.parse(message: message, cardUID: uid) {
                existingCard.balance = parsedCard.balance
                existingCard.lastUpdated = Date()
            }
            return existingCard
        } else {
            let newCard: SavingsCard
            if let message = ndefMessage,
               let parsedCard = NDEFParser.parse(message: message, cardUID: uid) {
                newCard = parsedCard
            } else {
                newCard = SavingsCard(cardUID: uid, balance: 0, currencyCode: "USD")
            }
            context.insert(newCard)
            return newCard
        }
    }

    func invalidateSessions() {
        readSession?.invalidate()
        writeSession?.invalidate()
        readSession = nil
        writeSession = nil
    }
}

extension NFCService: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead,
               readerError.code != .readerSessionInvalidationErrorUserCanceled {
                scanError = readerError.localizedDescription
                completion?(.failure(readerError))
                writeCompletion?(.failure(readerError))
            }
        }
        completion = nil
        writeCompletion = nil
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first else { return }

        if session === readSession {
            guard let tag = session.connectedTag else { return }
            let uid = tag.identifier

            do {
                let card = try findOrCreateCard(uid: uid, ndefMessage: message)
                lastScannedCard = card
                completion?(.success(card))
            } catch {
                completion?(.failure(error))
            }
        }
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard session === writeSession,
              let tag = tags.first,
              let payload = writePayload else { return }

        session.connect(to: tag) { error in
            if let error = error {
                self.writeCompletion?(.failure(error))
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    self.writeCompletion?(.failure(error))
                    return
                }

                switch status {
                case .notSupported:
                    self.writeCompletion?(.failure(NFCError.notSupported))
                case .readOnly:
                    self.writeCompletion?(.failure(NFCError.readOnly))
                case .readWrite:
                    tag.writeNDEF(payload) { error in
                        if let error = error {
                            self.writeCompletion?(.failure(error))
                        } else {
                            self.writeCompletion?(.success(()))
                        }
                    }
                @unknown default:
                    self.writeCompletion?(.failure(NFCError.unknown))
                }
            }
        }
    }
}

enum NFCError: LocalizedError {
    case notAvailable
    case notSupported
    case readOnly
    case noModelContext
    case unknown
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "NFC is not available on this device"
        case .notSupported: return "This tag doesn't support NDEF writing"
        case .readOnly: return "This tag is read-only"
        case .noModelContext: return "Database context not available"
        case .unknown: return "An unknown NFC error occurred"
        case .parsingFailed: return "Failed to parse card data"
        }
    }
}