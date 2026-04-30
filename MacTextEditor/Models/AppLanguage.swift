import Foundation

enum AppLanguage: String {
    case fr, en
}

struct Strings {
    let lang: AppLanguage

    init(_ raw: String) { lang = AppLanguage(rawValue: raw) ?? .fr }

    var apiKeyPlaceholder: String     { lang == .en ? "Anthropic API Key"                    : "Clé API Anthropic" }
    var freePromptLabel: String       { lang == .en ? "Free prompt"                           : "Demande libre" }
    var freePromptPlaceholder: String { lang == .en ? "E.g. translate to French…"             : "Ex: traduis en anglais…" }
    var sendButton: String            { lang == .en ? "Send"                                  : "Envoyer" }
    var loadingLabel: String          { lang == .en ? "Processing…"                           : "En cours…" }
    var historyLabel: String          { lang == .en ? "History"                               : "Historique" }
    var unsavedTitle: String          { lang == .en ? "Unsaved document"                      : "Document non sauvegardé" }
    var unsavedMessage: String        { lang == .en ? "Unsaved changes will be lost."         : "Les modifications non sauvegardées seront perdues." }
    var discardButton: String         { lang == .en ? "Discard changes"                       : "Abandonner les modifications" }
    var cancelButton: String          { lang == .en ? "Cancel"                                : "Annuler" }
    var errorInvalidKey: String       { lang == .en ? "Invalid API key."                      : "Clé API invalide." }
    var errorNetwork: String          { lang == .en ? "Network error. Check your connection." : "Erreur réseau. Vérifiez votre connexion." }
    var errorEmpty: String            { lang == .en ? "Empty response from API."              : "Réponse vide de l'API." }
    var errorOpenFile: String         { lang == .en ? "Unable to open this file."             : "Impossible d'ouvrir ce fichier." }
    var errorSaveFile: String         { lang == .en ? "Unable to save the file."              : "Impossible d'enregistrer le fichier." }
    func errorServer(_ code: Int) -> String {
        lang == .en ? "Server error (\(code))." : "Erreur serveur (\(code))."
    }
}
