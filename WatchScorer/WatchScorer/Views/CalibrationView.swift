import SwiftUI

struct CalibrationView: View {
    let calibrationState: CalibrationState
    let startAction: () -> Void
    let finishAction: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("校準手勢")
                .font(.headline)
            Text(instructionText)
                .multilineTextAlignment(.center)
                .font(.footnote)

            if calibrationState == .recording {
                ProgressView()
                Button("完成", action: finishAction)
                    .buttonStyle(.borderedProminent)
            } else {
                Button("開始錄製") {
                    startAction()
                }
                .buttonStyle(.borderedProminent)
            }

            Button("關閉") {
                if calibrationState == .recording {
                    finishAction()
                }
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var instructionText: String {
        switch calibrationState {
        case .idle:
            return "請進行 10 次單 snap 與 10 次雙 snap。錄製期間請保持手腕自然姿勢，完成後按下完成。"
        case .recording:
            return "偵測中… 請依指示完成手勢。"
        case .completed:
            return "已更新個人化參數，可隨時重新校準。"
        }
    }
}

#Preview {
    CalibrationView(calibrationState: .idle,
                    startAction: {},
                    finishAction: {},
                    dismiss: {})
}
