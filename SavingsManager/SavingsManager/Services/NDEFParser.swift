import Foundation
import CoreNFC

struct NDEFParser {
    private static let savingsTypeName = "savings:card"
    private static let savingsTypeNameData = "savings:card".data(using: .utf8)!

    static func parse(message: NFCNDEFMessage, cardUID: Data) -> SavingsCard? {
        for record in message.records {
            if record.typeNameFormat == .nfcWellKnown,
               record.type == Data([0x55]),
               let payload = parseWellKnownURI(record.payload),
               payload.hasPrefix("savings://") {
                return parseSavingsURI(payload, cardUID: cardUID)
            }

            if record.typeNameFormat == .media,
               record.type == "application/json".data(using: .utf8)! {
                return parseJSONPayload(record.payload, cardUID: cardUID)
            }

            if record.typeNameFormat == .absoluteURI,
               record.type == savingsTypeNameData {
                return parseCustomPayload(record.payload, cardUID: cardUID)
            }
        }
        return nil
    }

    private static func parseWellKnownURI(_ payload: Data) -> String? {
        guard payload.count > 1 else { return nil }
        let prefixByte = payload[0]
        let uriData = payload.dropFirst()

        let prefix: String
        switch prefixByte {
        case 0x00: prefix = ""
        case 0x01: prefix = "http://www."
        case 0x02: prefix = "https://www."
        case 0x03: prefix = "http://"
        case 0x04: prefix = "https://"
        default: prefix = ""
        }

        guard let uriString = String(data: uriData, encoding: .utf8) else { return nil }
        return prefix + uriString
    }

    private static func parseSavingsURI(_ uri: String, cardUID: Data) -> SavingsCard? {
        guard let url = URL(string: uri),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }

        var balance: Decimal = 0
        var currencyCode = "USD"

        for item in queryItems {
            switch item.name {
            case "balance":
                if let value = item.value, let decimal = Decimal(string: value) {
                    balance = decimal
                }
            case "currency":
                if let value = item.value {
                    currencyCode = value
                }
            default:
                break
            }
        }

        return SavingsCard(cardUID: cardUID, balance: balance, currencyCode: currencyCode)
    }

    private static func parseJSONPayload(_ payload: Data, cardUID: Data) -> SavingsCard? {
        do {
            let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
            guard let json = json,
                  let balanceValue = json["balance"] as? NSNumber,
                  let currencyCode = json["currency"] as? String else { return nil }

            return SavingsCard(
                cardUID: cardUID,
                balance: Decimal(balanceValue.doubleValue),
                currencyCode: currencyCode
            )
        } catch {
            return nil
        }
    }

    private static func parseCustomPayload(_ payload: Data, cardUID: Data) -> SavingsCard? {
        do {
            let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
            guard let json = json,
                  let balanceValue = json["balance"] as? NSNumber,
                  let currencyCode = json["currency"] as? String else { return nil }

            return SavingsCard(
                cardUID: cardUID,
                balance: Decimal(balanceValue.doubleValue),
                currencyCode: currencyCode
            )
        } catch {
            return nil
        }
    }

    static func createNDEFMessage(for card: SavingsCard) -> NFCNDEFMessage {
        let jsonPayload: [String: Any] = [
            "balance": NSDecimalNumber(decimal: card.balance).doubleValue,
            "currency": card.currencyCode,
            "updated": ISO8601DateFormatter().string(from: card.lastUpdated),
            "uid": card.cardUID.map { String(format: "%02X", $0) }.joined()
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: jsonPayload)

        let customRecord = NFCNDEFPayload(
            format: .media,
            type: "application/json".data(using: .utf8)!,
            identifier: Data(),
            payload: jsonData
        )

        let uriString = "savings://card?balance=\(card.balance)&currency=\(card.currencyCode)"
        let uriRecord = NFCNDEFPayload.wellKnownTypeURIPayload(
            url: URL(string: uriString)!
        )!

        return NFCNDEFMessage(records: [uriRecord, customRecord])
    }

    static func createBlankNDEFMessage() -> NFCNDEFMessage {
        let jsonPayload: [String: Any] = [
            "balance": 0.0,
            "currency": "USD",
            "updated": ISO8601DateFormatter().string(from: Date())
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonPayload)

        let customRecord = NFCNDEFPayload(
            format: .media,
            type: "application/json".data(using: .utf8)!,
            identifier: Data(),
            payload: jsonData
        )

        let uriRecord = NFCNDEFPayload.wellKnownTypeURIPayload(
            url: URL(string: "savings://card?balance=0&currency=USD")!
        )!

        return NFCNDEFMessage(records: [uriRecord, customRecord])
    }
}

struct SavingsCardData: Codable {
    let balance: Decimal
    let currency: String
    let updated: Date
    let uid: String?
}