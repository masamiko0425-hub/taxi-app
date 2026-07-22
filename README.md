# タクシー配車アプリ MVP - Firestoreデータ設計 & Flutter雛形

## 1. Firestore コレクション設計

### `customers`（顧客）
```
customers/{customerId}
  name: string
  phone: string
  createdAt: timestamp
```

### `drivers`（ドライバー）
```
drivers/{driverId}
  name: string
  vehicleNumber: string          # 例: "札幌500 あ 12-34"
  status: string                 # "off" | "available" | "on_trip"
  currentLat: number
  currentLng: number
  updatedAt: timestamp
```

### `reservations`（予約）★中心となるコレクション
```
reservations/{reservationId}
  customerId: string
  driverId: string | null        # 割当前は null
  pickupDatetime: timestamp      # カレンダーで選んだ日時
  pickupAddress: string
  pickupLat: number
  pickupLng: number
  dropoffAddress: string
  dropoffLat: number
  dropoffLng: number
  status: string                 # "pending" | "assigned" | "tracking" | "in_progress" | "completed" | "cancelled"
  createdAt: timestamp
```

### `reservations/{reservationId}/customer_location`（サブコレクション、乗車直前のみ書き込み）
```
customer_location/current
  lat: number
  lng: number
  updatedAt: timestamp
```

設計のポイント:
- 位置情報は `reservations` 本体ではなく**サブコレクションに分離**。読み書き頻度が全く違うため、コレクションを分けることで料金・パフォーマンス両面で有利。
- 位置情報の書き込みは `status == "tracking"`（乗車予定時刻の前後、目安15分前〜）のときだけ行う設計にし、GPS常時取得を避ける。
- ドライバーの位置も同様に `drivers/{driverId}` に持たせ、稼働中のみ更新。

## 2. 状態遷移（status）

```
pending → assigned → tracking → in_progress → completed
                  ↘ cancelled
```

- `pending`: 予約作成直後、ドライバー未割当
- `assigned`: ドライバー割当済み、まだ追跡開始前
- `tracking`: 乗車予定時刻が近づき、位置情報の共有がON
- `in_progress`: 乗車中
- `completed`: 乗車完了

## 3. セットアップ手順

```bash
flutter create taxi_app  # 既存ならスキップ
cd taxi_app
flutter pub get
```

`pubspec.yaml` に以下を追加済み:
- `cloud_firestore` / `firebase_core` : Firestore連携
- `table_calendar` : カレンダーUI
- `geolocator` : GPS取得
- `google_maps_flutter` : 地図表示

Firebaseプロジェクトを作成し、`flutterfire configure` を実行して `firebase_options.dart` を生成してください。
Google Maps を使う場合は `AndroidManifest.xml` / `AppDelegate.swift` にAPIキーの設定が必要です。

## 4. ファイル構成

```
lib/
  main.dart
  models/
    reservation.dart
  screens/
    booking_screen.dart      # カレンダーで日時予約
    tracking_screen.dart     # 乗車直前のGPS追跡画面
  services/
    reservation_service.dart # Firestore読み書きロジック
```
