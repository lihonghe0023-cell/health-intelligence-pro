import Foundation
import Combine
import HealthCore

@MainActor
final class JournalStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []
    @Published var errorMessage: String?

    private var fileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrivateJournal", isDirectory: true)
            .appendingPathComponent("entries.json")
    }

    init() { load() }

    func add(category: JournalEntry.Category, title: String, detail: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        entries.insert(JournalEntry(category: category, title: trimmed, detail: detail), at: 0)
        persist()
    }

    func removeAll() {
        entries = []
        persist()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { entries.remove(at: index) }
        persist()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do { entries = try JSONDecoder().decode([JournalEntry].self, from: Data(contentsOf: fileURL)) }
        catch { errorMessage = "本地健康笔记读取失败：\(error.localizedDescription)" }
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch { errorMessage = "健康笔记保存失败：\(error.localizedDescription)" }
    }
}
