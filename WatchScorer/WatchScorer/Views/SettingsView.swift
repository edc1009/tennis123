import SwiftUI

struct SettingsView: View {
    @State private var settings: AppSettings
    let applyAction: (AppSettings) -> Void
    let dismiss: () -> Void

    init(settings: AppSettings,
         applyAction: @escaping (AppSettings) -> Void,
         dismiss: @escaping () -> Void) {
        _settings = State(initialValue: settings)
        self.applyAction = applyAction
        self.dismiss = dismiss
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("靈敏度") {
                    Slider(value: $settings.gesture.singleSnapThreshold,
                           in: 3 ... 9,
                           step: 0.1) {
                        Text("主手勢閾值")
                    } minimumValueLabel: {
                        Text("低")
                    } maximumValueLabel: {
                        Text("高")
                    }

                    Slider(value: $settings.gesture.lowActivityVariance,
                           in: 0.01 ... 1.5,
                           step: 0.01) {
                        Text("低活動門檻")
                    } minimumValueLabel: {
                        Text("敏感")
                    } maximumValueLabel: {
                        Text("嚴格")
                    }
                }

                Section("手別") {
                    Picker("慣用手", selection: $settings.profile.dominantWrist) {
                        ForEach(DominantWrist.allCases, id: \.self) { wrist in
                            Text(wrist.label).tag(wrist)
                        }
                    }
                }

                Section("資料") {
                    Toggle("儲存至 HealthKit", isOn: $settings.profile.storeToHealthKit)
                    Toggle("記錄 CSV", isOn: $settings.profile.persistLocally)
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉", action: dismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("套用") {
                        applyAction(settings)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(settings: .default,
                 applyAction: { _ in },
                 dismiss: {})
}
