import Foundation

enum AIError: Error {
    case invalidAPIKey, networkError, emptyResponse, serverError(Int)
}

enum AIAction: String, CaseIterable {
    case corriger, reformuler, continuer, resumer, proposer, raccourcir

    var label: String {
        switch self {
        case .corriger: return "Corriger"
        case .reformuler: return "Reformuler"
        case .continuer: return "Continuer"
        case .resumer: return "Résumer"
        case .proposer: return "Proposer"
        case .raccourcir: return "Raccourcir"
        }
    }

    var systemPrompt: String {
        switch self {
        case .corriger:
            return "Tu es un correcteur de texte professionnel. Corrige uniquement les fautes d'orthographe et de grammaire. Conserve le style et les intentions de l'auteur. Réponds uniquement avec le texte corrigé, sans commentaire."
        case .reformuler:
            return "Tu es un rédacteur professionnel. Reformule le texte en conservant le sens mais avec d'autres tournures. Réponds uniquement avec le texte reformulé, sans commentaire."
        case .continuer:
            return "Tu es un assistant d'écriture. Continue le texte de manière naturelle et cohérente avec le style existant. Génère environ un paragraphe. Réponds uniquement avec la continuation, sans répéter le texte original."
        case .resumer:
            return "Tu es un assistant d'écriture. Produis un résumé concis du texte. Réponds uniquement avec le résumé, sans commentaire."
        case .proposer:
            return "Tu es un assistant d'écriture. Propose une formulation alternative du texte, différente dans la forme mais identique dans le sens. Réponds uniquement avec la proposition, sans commentaire."
        case .raccourcir:
            return "Tu es un assistant d'écriture. Condense le texte d'environ 40% en conservant les idées principales. Réponds uniquement avec le texte condensé, sans commentaire."
        }
    }
}

enum AIService {
    private static let model = "claude-haiku-4-5-20251001"
    private static let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    static func perform(
        _ action: AIAction,
        on text: String,
        apiKey: String,
        session: URLSession = .shared
    ) async throws -> String {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "system": action.systemPrompt,
            "messages": [["role": "user", "content": text]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIError.networkError
        }

        guard let http = response as? HTTPURLResponse else { throw AIError.networkError }

        print("[AIService] HTTP \(http.statusCode)")
        if let body = String(data: data, encoding: .utf8) {
            print("[AIService] Response: \(body)")
        }

        if http.statusCode == 401 { throw AIError.invalidAPIKey }
        guard http.statusCode == 200 else { throw AIError.serverError(http.statusCode) }

        struct Response: Decodable {
            struct Content: Decodable { let type: String; let text: String }
            let content: [Content]
        }
        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let first = decoded.content.first(where: { $0.type == "text" }) else {
                throw AIError.emptyResponse
            }
            return first.text
        } catch let decodeError as DecodingError {
            print("[AIService] Decode error: \(decodeError)")
            throw AIError.emptyResponse
        }
    }

    static func performCustom(
        prompt: String,
        on text: String,
        apiKey: String,
        session: URLSession = .shared
    ) async throws -> String {
        let systemPrompt = "Tu es un assistant d'écriture. L'utilisateur te fournit un texte et une instruction. Applique l'instruction au texte. Réponds uniquement avec le texte résultant, sans commentaire."
        let userMessage = "Texte :\n\(text)\n\nInstruction : \(prompt)"

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userMessage]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIError.networkError
        }

        guard let http = response as? HTTPURLResponse else { throw AIError.networkError }

        print("[AIService] Custom HTTP \(http.statusCode)")
        if http.statusCode != 200, let responseBody = String(data: data, encoding: .utf8) {
            print("[AIService] Custom Response: \(responseBody)")
        }

        if http.statusCode == 401 { throw AIError.invalidAPIKey }
        guard http.statusCode == 200 else { throw AIError.serverError(http.statusCode) }

        struct Response: Decodable {
            struct Content: Decodable { let type: String; let text: String }
            let content: [Content]
        }
        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let first = decoded.content.first(where: { $0.type == "text" }) else {
                throw AIError.emptyResponse
            }
            return first.text
        } catch let decodeError as DecodingError {
            print("[AIService] Custom decode error: \(decodeError)")
            throw AIError.emptyResponse
        }
    }
}
