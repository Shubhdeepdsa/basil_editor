import AppKit
import SwiftUI

private enum SwipeTarget {
    case note(UUID)
    case draft(EditorNote)

    @MainActor
    func debugDescription(in noteStore: NoteStore) -> String {
        switch self {
        case .note(let noteID):
            if let note = noteStore.note(with: noteID),
               let index = noteStore.notes.firstIndex(where: { $0.id == noteID }) {
                return "note index=\(index), id=\(noteID), title=\(note.title)"
            }

            return "note id=\(noteID), missing"

        case .draft(let note):
            return "draft id=\(note.id), title=\(note.title)"
        }
    }
}

struct EditorLabView: View {
    @StateObject private var noteStore = NoteStore()
    @State private var dragTranslation: CGFloat = 0
    @State private var draftNote: EditorNote?
    @State private var isDraftActive = false
    @State private var isSwitchingNotes = false
    @State private var activeTransitionID = UUID()
    @State private var editorGeneration = 0
    @State private var debugEventCounter = 0

    private let panelBackground = Color(red: 245/255, green: 243/255, blue: 238/255)
    private let outerBackground = Color(red: 234/255, green: 231/255, blue: 223/255)
    private let mainText = Color(red: 31/255, green: 31/255, blue: 28/255)
    private let mutedText = Color(red: 138/255, green: 133/255, blue: 125/255)

    var body: some View {
        ZStack {
            outerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                GeometryReader { proxy in
                    editorPager(width: proxy.size.width)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                footerView
            }
            .frame(width: 440, height: 620)
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(mainText.opacity(0.05), lineWidth: 1)
            )
        }
        .frame(minWidth: 800, minHeight: 700)
        .onAppear {
            logDisplayedNoteRank(reason: "appear")
        }
        .onChange(of: activeDisplayNote.id) {
            logDisplayedNoteRank(reason: "active note changed")
        }
        .onChange(of: isDraftActive) {
            logDisplayedNoteRank(reason: "draft state changed")
        }
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(activeDisplayNote.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(mainText)

                Text("Basil")
                    .font(.system(size: 11))
                    .foregroundStyle(mutedText)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    print("⌘K Palette Triggered")
                } label: {
                    Text("⌘K")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(mainText.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(mutedText)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("k", modifiers: .command)

                Menu {
                    Button("New Note") {
                        draftNote = noteStore.makeDraftNote()
                        isDraftActive = true
                    }
                    Divider()
                    Button("Copy Markdown") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(activeDisplayNote.content.payload, forType: .string)
                    }
                    Button("Delete Note", role: .destructive) { print("Delete") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(mutedText)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    private var footerView: some View {
        HStack {
            Text("Saved · \(activeDisplayNote.wordCount) words")
                .font(.system(size: 11))
                .foregroundStyle(mutedText)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func editorPager(width: CGFloat) -> some View {
        ZStack {
            if let previousNote = noteStore.previousNote {
                previewPage(note: previousNote, position: -1, width: width)
            } else if isDraftActive {
                previewPage(note: noteStore.currentNote, position: -1, width: width)
            }

            if isDraftActive, let draftNote {
                editorPage(note: draftNote, width: width)
            } else {
                editorPage(note: noteStore.currentNote, width: width)
            }

            if isDraftActive {
                EmptyView()
            } else if let nextNote = noteStore.nextNote {
                previewPage(note: nextNote, position: 1, width: width)
            } else {
                previewPage(title: "New note", text: "Start writing...", position: 1, width: width)
            }
        }
        .gesture(swipeGesture(width: width))
    }

    private func editorPage(note: EditorNote, width: CGFloat) -> some View {
        TiptapEditorView(
            noteID: note.id,
            generation: editorGeneration,
            markdown: markdownBinding(for: note),
            wordCount: wordCountBinding(for: note),
            isEditable: isPagerSettled && !isSwitchingNotes,
            acceptsEditorUpdates: !isSwitchingNotes,
            onTrackpadSwipeEvent: { event in
                handleTrackpadSwipeEvent(event, width: width)
            }
        )
        .frame(width: width)
        .offset(x: dragTranslation)
    }

    private func previewPage(note: EditorNote, position: Int, width: CGFloat) -> some View {
        previewPage(title: note.title, text: previewText(for: note), position: position, width: width)
    }

    private func previewPage(title: String, text: String, position: Int, width: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(mainText)

                Text(text)
                    .font(.system(size: 17))
                    .foregroundStyle(text == "Start writing..." ? mutedText : mainText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
        .frame(width: width)
        .offset(x: CGFloat(position) * width + dragTranslation)
        .allowsHitTesting(false)
    }

    private var isPagerSettled: Bool {
        abs(dragTranslation) < 0.5
    }

    private var activeDisplayNote: EditorNote {
        if isDraftActive, let draftNote {
            return draftNote
        }

        return noteStore.currentNote
    }

    private func swipeGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                print("[BasilSwipe] drag changed width=\(value.translation.width), height=\(value.translation.height)")

                if value.translation.width > 0, !noteStore.hasPreviousNote, !isDraftActive {
                    dragTranslation = 0
                    return
                }

                dragTranslation = max(-width, min(width, value.translation.width))
            }
            .onEnded { value in
                let threshold = width * 0.35
                let predictedThreshold = width * 0.55
                let shouldMoveRight = value.translation.width > threshold || value.predictedEndTranslation.width > predictedThreshold
                let shouldMoveLeft = value.translation.width < -threshold || value.predictedEndTranslation.width < -predictedThreshold
                print("[BasilSwipe] drag ended width=\(value.translation.width), predicted=\(value.predictedEndTranslation.width), moveRight=\(shouldMoveRight), moveLeft=\(shouldMoveLeft)")

                if shouldMoveRight {
                    completeSwipe(.older, width: width)
                } else if shouldMoveLeft {
                    completeSwipe(.newer, width: width)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
                        dragTranslation = 0
                    }
                }
            }
    }

    private func handleTrackpadSwipeEvent(_ event: NoteSwipeEvent, width: CGFloat) {
        switch event {
        case .began:
            print("[BasilSwipe] visual swipe began")

        case let .changed(rawOffset):
            let clampedOffset = max(-width, min(width, rawOffset))

            if clampedOffset > 0, !noteStore.hasPreviousNote, !isDraftActive {
                dragTranslation = 0
                return
            }

            dragTranslation = clampedOffset
            print("[BasilSwipe] visual offset=\(clampedOffset)")

        case let .ended(direction):
            print("[BasilSwipe] visual swipe ended direction=\(String(describing: direction))")
            guard let direction else {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.9)) {
                    dragTranslation = 0
                }
                return
            }

            completeSwipe(direction, width: width)
        }
    }

    private func completeSwipe(_ direction: NoteSwipeDirection, width: CGFloat) {
        guard !isSwitchingNotes else {
            print("[BasilSwipe] ignoring swipe while transition is active: \(direction)")
            logPagerState(reason: "ignored swipe while transition active")
            return
        }

        guard let target = resolveSwipeTarget(direction) else {
            print("[BasilSwipe] no target for swipe: \(direction)")
            logPagerState(reason: "swipe had no target")
            withAnimation(.spring(response: 0.26, dampingFraction: 0.9)) {
                dragTranslation = 0
            }
            return
        }

        let transitionID = UUID()
        activeTransitionID = transitionID
        isSwitchingNotes = true

        print("[BasilSwipe] resolved target: \(target.debugDescription(in: noteStore)), fromIndex=\(noteStore.currentIndex), notes=\(noteStore.notes.count)")
        logPagerState(reason: "before transition to \(direction)")

        let targetOffset: CGFloat = direction == .older ? width : -width
        withAnimation(.easeOut(duration: 0.16)) {
            dragTranslation = targetOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            guard activeTransitionID == transitionID else { return }

            commitSwipeTarget(target)

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dragTranslation = 0
            }

            editorGeneration += 1
            isSwitchingNotes = false
            print("[BasilSwipe] after commit: currentIndex=\(noteStore.currentIndex), activeTitle=\(activeDisplayNote.title)")
            logPagerState(reason: "after commit \(direction)")
        }
    }

    private func resolveSwipeTarget(_ direction: NoteSwipeDirection) -> SwipeTarget? {
        switch direction {
        case .newer:
            if let nextNote = noteStore.nextNote {
                return .note(nextNote.id)
            }

            if isDraftActive {
                return nil
            }

            return .draft(noteStore.makeDraftNote())

        case .older:
            if isDraftActive {
                return .note(noteStore.currentNote.id)
            }

            guard let previousNote = noteStore.previousNote else { return nil }
            return .note(previousNote.id)
        }
    }

    private func commitSwipeTarget(_ target: SwipeTarget) {
        switch target {
        case .note(let noteID):
            if isDraftActive, noteID == noteStore.currentNote.id {
                discardDraftIfEmpty()
            } else {
                draftNote = nil
                isDraftActive = false
                noteStore.select(noteID: noteID)
            }

        case .draft(let draft):
            draftNote = draft
            isDraftActive = true
        }
    }

    private func markdownBinding(for note: EditorNote) -> Binding<String> {
        if draftNote?.id == note.id {
            return Binding(
                get: { draftNote?.content.payload ?? "" },
                set: { markdown in
                    guard var draft = draftNote else { return }
                    draft.content = .plainMarkdown(markdown)
                    draft.updatedAt = Date()

                    if isEmptyMarkdown(markdown) {
                        draftNote = draft
                    } else {
                        noteStore.commitDraft(draft)
                        draftNote = nil
                        isDraftActive = false
                    }
                }
            )
        }

        let state = noteStore.binding(for: note.id)
        return Binding(get: state.markdown, set: state.setMarkdown)
    }

    private func wordCountBinding(for note: EditorNote) -> Binding<Int> {
        if draftNote?.id == note.id {
            return Binding(
                get: { draftNote?.wordCount ?? 0 },
                set: { wordCount in
                    guard var draft = draftNote else { return }
                    draft.wordCount = wordCount
                    draftNote = draft
                }
            )
        }

        let state = noteStore.binding(for: note.id)
        return Binding(get: state.wordCount, set: state.setWordCount)
    }

    private func discardDraftIfEmpty() {
        guard let draftNote else {
            isDraftActive = false
            return
        }

        if isEmptyMarkdown(draftNote.content.payload) {
            self.draftNote = nil
            isDraftActive = false
        }
    }

    private func isEmptyMarkdown(_ markdown: String) -> Bool {
        markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func previewText(for note: EditorNote) -> String {
        let markdown = note.content.payload.trimmingCharacters(in: .whitespacesAndNewlines)
        return markdown.isEmpty ? "Start writing..." : markdown
    }

    private func logDisplayedNoteRank(reason: String) {
        let note = activeDisplayNote

        if isDraftActive {
            print("[BasilNote] showing unsaved draft position=\(noteStore.notes.count + 1), savedNotes=\(noteStore.notes.count), id=\(note.id), title=\(note.title), reason=\(reason)")
            logPagerState(reason: "displayed draft: \(reason)")
            return
        }

        let rank = noteStore.notes.firstIndex(where: { $0.id == note.id }).map { $0 + 1 } ?? 0
        print("[BasilNote] showing note rank=\(rank)/\(noteStore.notes.count), id=\(note.id), title=\(note.title), reason=\(reason)")
        logPagerState(reason: "displayed note: \(reason)")
    }

    private func logPagerState(reason: String) {
        debugEventCounter += 1

        let activeNote = activeDisplayNote
        let savedRank = noteStore.notes.firstIndex(where: { $0.id == activeNote.id }).map { $0 + 1 }
        let previousTitle = noteStore.previousNote?.title ?? "nil"
        let nextTitle = noteStore.nextNote?.title ?? "nil"
        let draftDescription: String

        if let draftNote {
            draftDescription = "id=\(draftNote.id), title=\(draftNote.title), empty=\(isEmptyMarkdown(draftNote.content.payload))"
        } else {
            draftDescription = "nil"
        }

        print("[BasilState #\(debugEventCounter)] reason=\(reason)")
        print("[BasilState #\(debugEventCounter)] savedCount=\(noteStore.notes.count), currentIndex=\(noteStore.currentIndex), currentID=\(noteStore.currentNote.id), currentTitle=\(noteStore.currentNote.title)")
        print("[BasilState #\(debugEventCounter)] activeID=\(activeNote.id), activeTitle=\(activeNote.title), activeSavedRank=\(savedRank.map(String.init) ?? "draft"), isDraftActive=\(isDraftActive), draft=\(draftDescription)")
        print("[BasilState #\(debugEventCounter)] hasPrevious=\(noteStore.hasPreviousNote), previousTitle=\(previousTitle), hasNext=\(noteStore.hasNextNote), nextTitle=\(nextTitle), isSwitching=\(isSwitchingNotes), drag=\(dragTranslation), generation=\(editorGeneration)")
        print("[BasilState #\(debugEventCounter)] savedOrder=\(noteStore.notes.enumerated().map { "\($0.offset + 1):\($0.element.title)[\($0.element.id)]" }.joined(separator: " | "))")
    }
}

#Preview {
    EditorLabView()
}
