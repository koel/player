@preconcurrency import Shared
import SwiftUI

/// The equalizer, crossfade and loudness, opened from Now Playing and the profile menu.
struct PlaybackSettingsSheet: View {
    private let settings: PlaybackSettingsStore

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.brandColor) private var brandColor
    @State private var equalizer: Live<EqualizerPreset>
    @State private var customPresets: Live<[EqualizerPreset]>
    @State private var canSavePresets: Live<KotlinBoolean>
    @State private var crossfadeDuration: Live<KotlinInt>
    @State private var normalizeVolume: Live<KotlinBoolean>
    @State private var isSavingPreset = false
    @State private var presetToRemove: EqualizerPreset?
    @State private var detent = PresentationDetent.large

    init(settings: PlaybackSettingsStore) {
        self.settings = settings
        _equalizer = State(initialValue: Live(settings.equalizer))
        _customPresets = State(initialValue: Live(settings.customPresets))
        _canSavePresets = State(initialValue: Live(settings.canSavePresets))
        _crossfadeDuration = State(initialValue: Live(settings.crossfadeDuration))
        _normalizeVolume = State(initialValue: Live(settings.normalizeVolume))
    }

    var body: some View {
        let preset = equalizer.value

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SectionHeader.sectionGap) {
                    VStack(alignment: .leading, spacing: SectionHeader.contentGap) {
                        SectionHeader(title: "Equalizer")
                        VStack(spacing: 12) {
                            equalizerHeader(preset)
                            EqualizerPanel(preset: preset) { settings.setEqualizer(preset: $0) }
                                .animation(.easeOut(duration: 0.3), value: matchingPreset(preset)?.id)
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: SectionHeader.contentGap) {
                        SectionHeader(title: "Crossfade")
                        crossfadeSlider.padding(.horizontal)
                    }

                    if app.core.session.isKoelPlus {
                        VStack(alignment: .leading, spacing: SectionHeader.contentGap) {
                            SectionHeader(title: "Volume")
                            Toggle("Play songs at about the same volume", isOn: Binding {
                                normalizeVolume.value.boolValue
                            } set: { enabled in
                                settings.setNormalizeVolume(enabled: enabled)
                            })
                            .tint(brandColor)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Playback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
            .sheet(isPresented: $isSavingPreset) {
                PresetNameSheet(settings: settings)
            }
            .destructiveConfirmation(
                "Remove this preset?",
                item: $presetToRemove,
                actionLabel: "Remove Preset",
                message: { "“\($0.name ?? "")” will be removed from your saved presets." },
                action: remove
            )
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationBackground(Color(uiColor: .systemBackground))
    }

    private func equalizerHeader(_ preset: EqualizerPreset) -> some View {
        let matching = matchingPreset(preset)

        return HStack(spacing: 8) {
            presetPicker(preset, matching: matching)
            if matching == nil && canSavePresets.value.boolValue {
                Button("Save as…") { isSavingPreset = true }
            }
            if let saved = customPresets.value.first(where: { $0.id == matching?.id }) {
                Button("Remove") { presetToRemove = saved }
            }
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }

    private func presetPicker(_ preset: EqualizerPreset, matching: EqualizerPreset?) -> some View {
        Menu {
            Picker("Preset", selection: presetSelection(preset)) {
                if customPresets.value.isEmpty {
                    presetOptions(Equalizer.shared.builtInPresets)
                } else {
                    Section("Built-in") { presetOptions(Equalizer.shared.builtInPresets) }
                    Section("Custom") { presetOptions(customPresets.value) }
                }
            }
        } label: {
            HStack {
                Text("Preset")
                Spacer()
                Text(matching?.name ?? "Custom")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(.black.opacity(0.2), in: .rect(cornerRadius: EqualizerPanel.cornerRadius))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .id(matching?.id)
        .accessibilityLabel("Preset")
        .accessibilityValue(matching?.name ?? "Custom")
    }

    private func presetOptions(_ presets: [EqualizerPreset]) -> some View {
        ForEach(presets, id: \.id) { preset in
            Text(preset.name ?? "").tag(preset.id)
        }
    }

    private var crossfadeSlider: some View {
        let seconds = crossfadeDuration.value.intValue
        let maximum = Double(PlaybackSettingsStore.companion.MAX_CROSSFADE_SECONDS)

        return HStack {
            KoelSlider(
                value: Binding {
                    Double(seconds)
                } set: { newValue in
                    settings.setCrossfadeDuration(seconds: Int32(newValue.rounded()))
                },
                range: 0...maximum
            )
            .accessibilityLabel("Crossfade")
            .accessibilityValue(seconds == 0 ? "Off" : "\(seconds) seconds")

            Text(seconds == 0 ? "Off" : "\(seconds) s")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 36, alignment: .trailing)
                .accessibilityHidden(true)
        }
    }

    private func matchingPreset(_ preset: EqualizerPreset) -> EqualizerPreset? {
        Equalizer.shared.presetMatching(setting: preset, saved: customPresets.value)
    }

    private func presetSelection(_ preset: EqualizerPreset) -> Binding<String?> {
        Binding {
            matchingPreset(preset)?.id
        } set: { id in
            let all = Equalizer.shared.builtInPresets + customPresets.value
            guard let chosen = all.first(where: { $0.id == id }) else { return }
            settings.setEqualizer(preset: chosen)
        }
    }

    private func remove(_ preset: EqualizerPreset) {
        Task {
            do {
                try await settings.removePreset(preset: preset)
            } catch {
                app.toasts.showError(message: "Could not remove preset.")
            }
        }
    }
}

private struct PresetNameSheet: View {
    let settings: PlaybackSettingsStore

    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        FormSheet(
            title: "Save Preset",
            submitLabel: "Save",
            canSubmit: !name.trimmingCharacters(in: .whitespaces).isEmpty,
            failureMessage: { _ in "Could not save preset." },
            submit: { _ = try await settings.savePreset(name: name) }
        ) {
            TextField("Preset Name", text: $name)
                .focused($isNameFocused)
        }
        .onAppear { isNameFocused = true }
    }
}
