import Combine
import Foundation

struct EditorNote: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var wordCount: Int
    var content: NoteContentEnvelope
}

struct NoteContentEnvelope: Codable, Equatable {
    var encoding: String
    var payload: String

    static func plainMarkdown(_ markdown: String) -> NoteContentEnvelope {
        NoteContentEnvelope(encoding: "plainMarkdown.v1", payload: markdown)
    }
}

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [EditorNote]
    @Published private(set) var currentNoteID: UUID

    private let storageKey = "Basil.NoteStore.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let snapshot = Self.loadSnapshot(storageKey: storageKey, decoder: decoder), !snapshot.notes.isEmpty {
            let nonEmptyNotes = snapshot.notes
                .filter { !Self.isEmptyMarkdown($0.content.payload) }
                .sorted { $0.createdAt < $1.createdAt }

            notes = nonEmptyNotes.isEmpty ? [Self.makeNote()] : nonEmptyNotes
            currentNoteID = snapshot.lastActiveNoteID

            if !notes.contains(where: { $0.id == currentNoteID }) {
                currentNoteID = notes[notes.count - 1].id
            }

            if notes.count != snapshot.notes.count {
                save()
            }
        } else {
            let note = Self.makeNote()
            notes = [note]
            currentNoteID = note.id
            save()
        }
    }

    var currentIndex: Int {
        notes.firstIndex { $0.id == currentNoteID } ?? 0
    }

    var currentNote: EditorNote {
        notes[currentIndex]
    }

    var hasPreviousNote: Bool {
        currentIndex > 0
    }

    var hasNextNote: Bool {
        currentIndex < notes.count - 1
    }

    var previousNote: EditorNote? {
        hasPreviousNote ? notes[currentIndex - 1] : nil
    }

    var nextNote: EditorNote? {
        hasNextNote ? notes[currentIndex + 1] : nil
    }

    func binding(for id: UUID) -> BindingState {
        BindingState(
            markdown: { [weak self] in
                self?.note(with: id)?.content.payload ?? ""
            },
            setMarkdown: { [weak self] markdown in
                self?.updateNote(id: id, markdown: markdown)
            },
            wordCount: { [weak self] in
                self?.note(with: id)?.wordCount ?? 0
            },
            setWordCount: { [weak self] wordCount in
                self?.updateNote(id: id, wordCount: wordCount)
            }
        )
    }

    func makeDraftNote() -> EditorNote {
        Self.makeNote()
    }

    func select(noteID: UUID) {
        guard notes.contains(where: { $0.id == noteID }) else { return }
        currentNoteID = noteID
        save()
    }

    func selectPrevious() {
        guard hasPreviousNote else { return }
        select(noteID: notes[currentIndex - 1].id)
    }

    func selectNext() {
        guard hasNextNote else { return }
        select(noteID: notes[currentIndex + 1].id)
    }

    func note(with id: UUID) -> EditorNote? {
        notes.first { $0.id == id }
    }

    func commitDraft(_ draft: EditorNote) {
        guard !Self.isEmptyMarkdown(draft.content.payload) else { return }

        guard !notes.contains(where: { $0.id == draft.id }) else {
            currentNoteID = draft.id
            save()
            return
        }

        notes.append(draft)
        notes.sort { $0.createdAt < $1.createdAt }
        currentNoteID = draft.id
        save()
    }

    private func updateNote(id: UUID, markdown: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        guard notes[index].content.payload != markdown else { return }

        notes[index].content = .plainMarkdown(markdown)
        notes[index].updatedAt = Date()
        currentNoteID = id
        save()
    }

    private func updateNote(id: UUID, wordCount: Int) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        guard notes[index].wordCount != wordCount else { return }

        notes[index].wordCount = wordCount
        save()
    }

    private func save() {
        let snapshot = NoteStoreSnapshot(notes: notes, lastActiveNoteID: currentNoteID)
        guard let data = try? encoder.encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func loadSnapshot(storageKey: String, decoder: JSONDecoder) -> NoteStoreSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? decoder.decode(NoteStoreSnapshot.self, from: data)
    }

    private static func makeNote(now: Date = Date()) -> EditorNote {
        EditorNote(
            id: UUID(),
            title: Self.title(for: now),
            createdAt: now,
            updatedAt: now,
            wordCount: 0,
            content: .plainMarkdown("")
        )
    }

    private static func title(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return "Note \(formatter.string(from: date))"
    }

    private static func isEmptyMarkdown(_ markdown: String) -> Bool {
        markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    struct BindingState {
        var markdown: () -> String
        var setMarkdown: (String) -> Void
        var wordCount: () -> Int
        var setWordCount: (Int) -> Void
    }
}

private struct NoteStoreSnapshot: Codable {
    var notes: [EditorNote]
    var lastActiveNoteID: UUID
}
