# Dev B — bàn giao bản greybox

Mở `Assets/_Game/Scenes/Game.unity`, Play, chọn **BẮT ĐẦU**. `Sandbox_B.unity` là scene test riêng. Hai scene dùng `Prefabs/Defense/DefenseRoot.prefab`; không có DebugWaveClock. Mining A01–A13 được ghép từ `origin/a/week2-mining`.

## Chức năng

- B01–B06: vòng Mining/Defense, countdown/cảnh báo, HP base, pháo chuột, pool quái/đạn, spawn hai bên, kho nhận ResourcesDeposited.
- B07–B12: quái bộ/bay/bắn xa; đạn thường/axit/lửa/băng; độc/cháy/làm chậm kèm art FX; chế đạn tại base; shop nâng cấp Mining/Defense; 10 wave; HUD TextMeshPro, slot đạn và tâm ngắm.
- B13–B16: boss wave cuối với lao/bắn/gọi quái; menu, pause, thắng/thua và restart; các node nâng cấp theo cấp/giá; âm thanh tạm và nhạc hai pha. AudioClip thật có thể gán trong DefenseAudioConfig để thay âm tổng hợp.

## Điều khiển và cân bằng

- Chuột trái: bắn khi đứng tại base. Pháo xoay có giới hạn tốc độ và bắn được cả hai phía.
- 1–4: chọn đạn. E: mở/đóng shop tại base trong Mining. Esc: tạm dừng.
- Editor: F1 thêm quặng, F2 bắt đầu wave, F3 hồi base, F4 tới boss. Giữ F5–F10 cho phần Mining.
- Chỉnh toàn bộ HP, damage, tốc độ, status, công thức, nhạc/SFX, giá và wave trong `Assets/_Game/Data/Defense/`.
- Shop phát UpgradePurchased với id có sẵn của Mining; dùng CanUpgrade để chặn mua quá cấp thực tế (config bàn giao hiện là cấp 0–4). Lift mua một lần; blast mua thêm từng quả.

## Dựng lại và kiểm tra

- `Underlab/Defense/Build Sandbox_B`: dựng scene test từ Sandbox_A, không ghi lại scene A.
- `Underlab/Defense/Build Integrated Game`: dựng lại Game từ bản bàn giao A; chỉ chạy khi đang giữ token Game.unity. Lệnh cập nhật Build Settings.
- `Underlab/Defense/Verify Play Mode`: chạy smoke test trên scene vừa dựng; kết quả ở `Logs/DefenseVerification.txt`.
- Batch entry point: `Underlab.Game.EditorTools.DefenseVerification.Batch` (không truyền `-quit`; runner tự thoát sau khi kiểm tra).

Đã kiểm tra với Unity 6000.0.44f1 trên bản sao dự án trong Temp, sử dụng các package đang có. Kết quả: **PASS, 21 assertions** — event gửi quặng, số dư, nâng cấp Mining và giới hạn cấp, recipe lửa, điều kiện ở base, hồi máu, va chạm đạn pháo và đạn quái bắn xa, tái dùng pool, 10 wave/boss, Victory và GameOver. Không có lỗi compile, NullReferenceException hay MissingReferenceException trong lượt chạy này. Test rút ngắn thời gian trên bản sao config trong Play Mode; không thay số liệu asset.

Art vẫn dùng placeholder trong manifest; âm thanh tổng hợp là bản tạm. Cần playtest trực quan, cân bằng run 15–20 phút, duyệt art/style và kiểm tra Windows build trước release. Các lỗi GUID có sẵn trong `Assets/Art/content` không thuộc thay đổi Dev B. Kết nối MCP Editor hiện không xử lý được lệnh menu nên đã dùng Unity batch riêng để xác minh, không coi thông báo recompile từ MCP là bằng chứng duy nhất.

`DefenseVisual` tạo ArtSprite lúc Awake từ art id để prefab không lưu sprite preview do ExecuteAlways tạo ra. Prefab và hai scene bàn giao không chứa reference PNG ở SpriteRenderer. Không sửa code Mining hoặc hợp đồng Core ngoài nội dung nhận từ nhánh A.
