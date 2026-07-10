import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PetLibraryStore

    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            panelSection(title: "Apply Mode") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose what happens when you apply a pet.")
                        .font(ClassicMacTheme.font(12))

                    Picker("Apply mode", selection: $store.applyMode) {
                        ForEach(ApplyMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()

                    Text(store.applyMode.subtitle)
                        .font(ClassicMacTheme.font(11))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button("Enable Live Apply Once") {
                            store.restartCodexOnceForPetRefresh()
                        }
                        .buttonStyle(ClassicButtonStyle(filled: false))

                        Text("Codpet relaunches Codex one time with its hidden live apply channel. After that, double-click apply can stay invisible for the rest of this session.")
                            .font(ClassicMacTheme.font(11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            panelSection(title: "Dock Layout") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose how the pet selector floats on your desktop.")
                        .font(ClassicMacTheme.font(12))

                    Picker("Dock layout", selection: $store.dockLayoutMode) {
                        ForEach(DockLayoutMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()

                    Text(store.dockLayoutMode.subtitle)
                        .font(ClassicMacTheme.font(11))
                        .foregroundStyle(.secondary)
                }
            }

            panelSection(title: "Library") {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Catalog Source") {
                        Text("Built-in cod.pet catalog")
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Installed Pets Folder") {
                        Text("~/.codex/pets")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button("Import Local") {
                            store.importLocalPet()
                        }
                        .buttonStyle(ClassicButtonStyle(filled: false))

                        Button("Open Codex Pets") {
                            store.revealCodexPetsFolder()
                        }
                        .buttonStyle(ClassicButtonStyle(filled: false))

                        Button("Refresh") {
                            store.refreshAll()
                        }
                        .buttonStyle(ClassicButtonStyle(filled: false))
                    }
                }
            }

            panelSection(title: "Notes") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Codpet opens like a small Mac OS 8.1 desktop.")
                    Text("My Pets shows what is already installed. Codpet shows the bundled cod.pet catalog. Trash keeps pets you removed until you restore them or delete them forever.")
                }
                .font(ClassicMacTheme.font(11))
                .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Close", action: onClose)
                    .buttonStyle(ClassicButtonStyle(filled: false))
                    .keyboardShortcut(.cancelAction)
                    .keyboardShortcut("w", modifiers: .command)
            }
        }
        .padding(20)
        .background(Color.white)
    }

    @ViewBuilder
    private func panelSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(ClassicMacTheme.font(15))

            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .overlay(
                    Rectangle()
                        .stroke(ClassicMacTheme.ink, lineWidth: 1)
                )
        }
    }
}
