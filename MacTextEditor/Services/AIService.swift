import Foundation

enum AIError: Error {
    case invalidAPIKey, networkError, emptyResponse, serverError(Int)
}

enum AIAction: String, CaseIterable {
    case corriger, reformuler, continuer, resumer, proposer, raccourcir, formater

    func label(in lang: AppLanguage) -> String {
        switch self {
        case .corriger:   return lang == .en ? "Correct"   : "Corriger"
        case .reformuler: return lang == .en ? "Rephrase"  : "Reformuler"
        case .continuer:  return lang == .en ? "Continue"  : "Continuer"
        case .resumer:    return lang == .en ? "Summarize" : "Résumer"
        case .proposer:   return lang == .en ? "Suggest"   : "Proposer"
        case .raccourcir: return lang == .en ? "Shorten"   : "Raccourcir"
        case .formater:   return lang == .en ? "Format"    : "Formater"
        }
    }

    func systemPrompt(in lang: AppLanguage) -> String {
        switch self {
        case .corriger:
            return lang == .en
                ? "You are a professional proofreader. Correct only spelling and grammar mistakes. Preserve the author's style and intent. Reply only with the corrected text, without any comment."
                : "Tu es un correcteur de texte professionnel. Corrige uniquement les fautes d'orthographe et de grammaire. Conserve le style et les intentions de l'auteur. Réponds uniquement avec le texte corrigé, sans commentaire."
        case .reformuler:
            return lang == .en
                ? "You are a professional writer. Rephrase the text while keeping the meaning but using different wording. Reply only with the rephrased text, without any comment."
                : "Tu es un rédacteur professionnel. Reformule le texte en conservant le sens mais avec d'autres tournures. Réponds uniquement avec le texte reformulé, sans commentaire."
        case .continuer:
            return lang == .en
                ? "You are a creative writing assistant. Continue the provided text coherently with its style, tone, and narrative. If it is fiction, stay within the fictional world and advance the story — never give practical or real-world advice. Generate about one paragraph. Reply only with the continuation, without repeating the original text."
                : "Tu es un assistant d'écriture créative. Continue le texte fourni de façon cohérente avec son style, son ton et sa narration. S'il s'agit d'une fiction, reste dans l'univers fictif et fais avancer l'histoire — ne donne jamais de conseils pratiques ou réels. Génère environ un paragraphe. Réponds uniquement avec la continuation, sans répéter le texte original."
        case .resumer:
            return lang == .en
                ? "You are a writing assistant. Produce a concise summary of the text. Reply only with the summary, without any comment."
                : "Tu es un assistant d'écriture. Produis un résumé concis du texte. Réponds uniquement avec le résumé, sans commentaire."
        case .proposer:
            return lang == .en
                ? "You are a writing assistant. Suggest an alternative formulation of the text, different in form but identical in meaning. Reply only with the suggestion, without any comment."
                : "Tu es un assistant d'écriture. Propose une formulation alternative du texte, différente dans la forme mais identique dans le sens. Réponds uniquement avec la proposition, sans commentaire."
        case .raccourcir:
            return lang == .en
                ? "You are a writing assistant. Condense the text by about 40% while keeping the main ideas. Reply only with the condensed text, without any comment."
                : "Tu es un assistant d'écriture. Condense le texte d'environ 40% en conservant les idées principales. Réponds uniquement avec le texte condensé, sans commentaire."
        case .formater:
            return lang == .en
                ? "You are a writing assistant. Restructure the text into well-formed paragraphs: group related sentences, add paragraph breaks where the meaning requires it, remove superfluous line breaks. Do not modify the content or style. Reply only with the reformatted text, without any comment."
                : "Tu es un assistant d'écriture. Restructure le texte en paragraphes bien formés : regroupe les phrases liées, ajoute des sauts de paragraphe là où le sens l'exige, supprime les sauts de ligne superflus. Ne modifie pas le contenu ni le style. Réponds uniquement avec le texte reformaté, sans commentaire."
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
        language: AppLanguage = .fr,
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
            "system": action.systemPrompt(in: language),
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
        language: AppLanguage = .fr,
        session: URLSession = .shared
    ) async throws -> String {
        let systemPrompt = language == .en
            ? "You are a creative writing assistant. The user provides a text (which may be fiction, a narrative, a story) and an instruction. Apply the instruction to the text while respecting its world, tone, and narrative — if the text is fiction, stay within the fiction. Reply only with the resulting text, without any comment."
            : "Tu es un assistant d'écriture créative. L'utilisateur te fournit un texte (qui peut être une fiction, un récit, une histoire) et une instruction. Applique l'instruction au texte en respectant son univers, son ton et sa narration — si le texte est une fiction, reste dans la fiction. Réponds uniquement avec le texte résultant, sans commentaire."
        let userMessage = language == .en
            ? "Text:\n\(text)\n\nInstruction: \(prompt)"
            : "Texte :\n\(text)\n\nInstruction : \(prompt)"

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
