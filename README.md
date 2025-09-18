# SnapScore Watch App

這個專案提供一個獨立的 Apple Watch 計分 App（SwiftUI + watchOS），專為網球或板網球等對戰運動設計。透過腕部 snap/外翻手勢即可完成即時記分，並且支援 HealthKit 背景執行與抬腕 Double Tap 備援。

## 核心功能

- **手勢計分**：利用 Core Motion 50–100 Hz 的 deviceMotion 串流，透過 `GestureEngine` 管線進行前處理、低活動期閘門、峰值偵測與雙次手勢判定。
- **運動背景執行**：以 `HKWorkoutSession` 啟動「Workout processing」背景模式，螢幕熄滅時仍可偵測 IMU。
- **前景備援**：主要加分按鈕標記為 Primary Action，支援 S9 / Ultra 2 的 Double Tap 喚醒後快速加分。
- **觸覺回饋**：`HapticsManager` 依據單/雙手勢播放不同觸覺回應。
- **資料保存**：可選擇寫入 HealthKit Workout，以及在本地容器輸出 CSV 記錄比分。
- **個人化校準**：提供校準流程紀錄 10 組單/雙手勢，自動估算最佳閾值與低活動門檻，並支援左右手獨立參數。

## 模組化架構

| 模組 | 負責項目 |
| --- | --- |
| `MotionStream` | 管理 `CMMotionManager` 串流與取樣率設定。 |
| `GestureEngine` | 低活動期判定、不應期管理、單雙峰判斷與事件輸出。 |
| `ScoringService` | 記分、歷史堆疊與撤銷。 |
| `WorkoutSessionManager` | HealthKit 授權、Workout session 生命週期。 |
| `HapticsManager` | 統一觸覺回饋。 |
| `PersistenceController` | 設定與比分 CSV 持久化。 |
| `AppViewModel` | 串接所有服務，供 SwiftUI 視圖使用。 |

## 主要畫面

- `ScoreboardView`：顯示雙方比分、啟停比賽與主按鈕。
- `SettingsView`：調整靈敏度、慣用手與資料儲存偏好。
- `CalibrationView`：提示並執行手勢校準。

## 建置與執行

1. 於 Xcode 15+ 新建 watchOS App 專案，將 `WatchScorer/WatchScorer` 內的檔案加入 WatchKit Extension 目標。
2. 啟用以下 Capabilities：
   - Background Modes → Workout processing
   - HealthKit（讀寫 Workout）
   - App Group：`group.snapscorer`（或修改 `PersistenceController` 中的識別碼）
3. 在 `Info.plist` 加入 `NSHealthShareUsageDescription` 與 `NSHealthUpdateUsageDescription`。
4. 於實機 Apple Watch（Series 7 以上建議）建置並測試手勢偵測與校準流程。

## 測試建議

- 於模擬器驗證 UI 與設定流程。
- 實機進行：
  - 低活動期 precision ≥ 0.95, recall ≥ 0.90。
  - 每 5 分鐘誤觸 ≤ 1 次。
  - 比賽 1–2 小時電量消耗 < 10%/小時。

## 授權

本專案遵循原始 `LICENSE` 條款。
