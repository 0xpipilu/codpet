import SwiftUI

@main
struct CodpetHybridApp: App {
    @StateObject private var store = CodpetHybridStore()
    
    var body: some Scene {
        WindowGroup {
            HybridContentView()
                .environmentObject(store)
        }
        .windowResizability(.contentSize)
    }
}
