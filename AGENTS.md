# AGENTS.md — quy ước cho AI coding agent (Codex, Claude Code…) trong dự án UNDERLAB

Game 2D mining + tower-defense (đào quặng dưới lòng đất, về base phòng thủ wave quái). Unity **6000.0.44f1**, URP 2D, Input System mới, C#.
Tài liệu: `Docs/01_ROADMAP.md` (task ID), `Docs/02_ASSET_PIPELINE.md` (asset), `Docs/05_GIT_WORKFLOW.md` (ownership).

## Cấu trúc
```
Assets/_Game/
  Scripts/Core/      GameTypes.cs (enum chung), GameEvents.cs (event bus)  ← HỢP ĐỒNG CHUNG
  Scripts/Art/       ArtDatabase, ArtSprite                                ← pipeline asset
  Scripts/Mining/ Player/ UI/Mining/                                       ← Dev A
  Scripts/Defense/ Enemies/ Game/ UI/                                      ← Dev B
  Editor/ArtTools/        tool import/placeholder/database
  Art/<category>/<id>.png, Art/asset_manifest.csv, Art/_GeneratedTiles/
  Data/              ScriptableObject cấu hình (Mining/, Defense/)
  Prefabs/  Scenes/
Assets/Art/content/  dump tham khảo (Godot) — KHÔNG sửa, KHÔNG reference từ code
```

## Quy tắc bắt buộc
1. **Namespace** `Underlab.<Module>` (Underlab.Core, Underlab.Mining, Underlab.Defense, Underlab.UI…).
2. **Hình ảnh chỉ qua art id**: `ArtSprite.Play("id")`, `ArtSprite.SetFrame(n)`, `ArtDatabase.GetSprite("id")`. Id phải có trong `asset_manifest.csv`. Không `[SerializeField] Sprite` cho asset thuộc manifest, không tạo Animator Controller chỉ để đổi frame. Tile: dùng asset trong `Assets/_Game/Art/_GeneratedTiles/<id>.asset`.
3. **Cần asset mới** → thêm 1 dòng vào `asset_manifest.csv` (giữ đúng 12 cột, notes không dấu phẩy) rồi báo người dùng chạy `Underlab/Art/Generate Missing Placeholders`.
4. **Giao tiếp giữa module chỉ qua `Underlab.Core.GameEvents`**. Không `FindObjectOfType` sang module của dev khác. Subscribe trong `OnEnable`, unsubscribe trong `OnDisable`.
5. **Không sửa `Scripts/Core/`** trừ khi người dùng yêu cầu rõ (đó là hợp đồng giữa 2 dev).
6. Chỉ sửa file trong folder của dev đang yêu cầu (xem bảng ownership trong `Docs/05_GIT_WORKFLOW.md`).
7. **Số liệu cân bằng** (máu, tốc độ, giá, wave…) để trong ScriptableObject ở `Assets/_Game/Data`, không hard-code.
8. Input: dùng **Input System** (`Assets/InputSystem_Actions.inputactions`), không dùng `Input.GetKey` cũ.
9. Quy ước thế giới: **1 unit = 1 ô đất = 128 px art**. Trục Y dương = lên. Mặt đất y = 0, đào xuống y âm.
10. Phím debug chỉ trong `#if UNITY_EDITOR` (F1 +quặng, F2 bắt đầu wave, F3 hồi base, F4 tới boss).
11. Prefab thay vì sửa scene `Game.unity`. Không đổi tên/di chuyển file có `.meta` bằng shell — làm trong Unity hoặc đổi cả `.meta`.
12. Code ngắn gọn, comment tiếng Việt cho logic khó. Không thêm package mới khi chưa hỏi.

## Kiểm tra trước khi xong
- Không lỗi compile (Unity console).
- Không tạo reference trực tiếp tới PNG trong `Assets/_Game/Art`.
- Tên event/enum khớp `GameEvents.cs` / `GameTypes.cs`.
