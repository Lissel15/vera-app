import SwiftUI
import SwiftData

@main
struct VeraApp: App {

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: MeltdownEvent.self, ChildProfile.self, LearnedStrategy.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            print("[Vera] ✅ ModelContainer listo")
        } catch {
            // Schema mismatch — wipe store and start fresh
            print("[Vera] ⚠️ Error container: \(error). Recreando store...")
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let appSupport = urls.first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            }
            do {
                container = try ModelContainer(
                    for: MeltdownEvent.self, ChildProfile.self, LearnedStrategy.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: false)
                )
                print("[Vera] ✅ Store recreado")
            } catch {
                fatalError("[Vera] ❌ No se pudo crear el container: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
