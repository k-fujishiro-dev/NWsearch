import Foundation

final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [TestSession] = []

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent("sessions.json")
        load()
    }

    func add(_ session: TestSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func update(_ session: TestSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index] = session
        save()
    }

    func updateNetworkLabel(sessionID: UUID, label: String) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].userNetworkLabel = label.isEmpty ? nil : label
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    func deleteAll() {
        sessions.removeAll()
        save()
    }

    func session(id: UUID) -> TestSession? {
        sessions.first { $0.id == id }
    }

    func previousSession(for session: TestSession) -> TestSession? {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }), index + 1 < sessions.count else {
            return nil
        }
        return sessions[index + 1]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([TestSession].self, from: data) else {
            return
        }
        self.sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
