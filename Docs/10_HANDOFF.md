# BÀN GIAO — 23/11/2026

> Người code chính tạm dừng; bạn tiếp quản **toàn bộ code**. Đọc file này trước, rồi [09_EXPANSION_PLAN.md](09_EXPANSION_PLAN.md) (thiết kế chi tiết) và [../AGENTS.md](../AGENTS.md) (quy ước — Codex tự đọc).
> **Hạn: art freeze 9/12 · nộp bản build 11/12.**

---

## 1. Trạng thái hiện tại (`main` @ `4ff7b922`)

| Hệ thống | Trạng thái | Code chính |
|---|---|---|
| Đào: player, jetpack, khoan, quặng, túi + vứt quặng (Q/G), về base, thang máy, bom, nâng cấp, HUD, cảnh báo wave, âm thanh + juice | ✅ chơi được | `Scripts/Mining`, `Scripts/Player`, `Scripts/UI/Mining` |
| Phòng thủ: vòng chơi, pháo, 4 loại đạn, quái thường/bay/bắn xa/boss, 10 wave, shop, menu/tạm dừng/thắng/thua (uGUI) | ✅ chơi được | `Scripts/Defense`, `Scripts/Game`, `Scripts/UI/DefenseHud.cs` |
| **Phòng thí nghiệm** (phím **T** ở base): Lửa (2Mg + O₂), Băng (KCl bão hoà, khuấy), Axit (tiếp xúc 3 bước). Đạn đặc biệt **chỉ** có từ đây | ✅ code xong, test chấm điểm PASS 17/17, **chưa ai thao tác tay thử** | `Scripts/Lab` |
| Art: 108/109 asset là hình AI (+32 icon/UI SVG) | ✅ (6 ảnh cần gen lại — [08_AI_ASSET_REVIEW.md](08_AI_ASSET_REVIEW.md)) | `Assets/_Game/Art`, `Tools/` |
| Cân bằng 10 wave + kinh tế | ✅ theo mô hình, chưa playtest kỹ | [07_BALANCE.md](07_BALANCE.md) |
| **Quái 4 phía** | 🟡 **ĐANG DỞ** — mới có dữ liệu (xem §3.1) | `WaveConfig.cs`, `DefenseConfig.cs` |
| Build Windows | ✅ chạy được (bản build cũ, chưa có art/lab mới) | menu `Underlab/Build/Windows` |

---

## 2. Bắt đầu

1. `git pull` nhánh `main`. Mở Unity **6000.0.44f1**. Scene chính: `Assets/_Game/Scenes/Game.unity` → Play → **BẮT ĐẦU**.
2. Nên tạo nhánh mới cho mỗi việc (`c/<việc>`), xong thì merge vào `main`. Nhánh `a/week2-mining` hiện = `main`, không cần dùng nữa.
3. **Quan trọng:** Unity đang tắt *Run In Background* ⇒ **game đứng yên khi cửa sổ Unity không được chọn** ⇒ các test Play Mode chạy qua MCP/AI sẽ treo nếu bạn không click vào Unity. Chạy test thì click vào cửa sổ Unity trước.

### Phím (trong Editor)
| Phím | Tác dụng |
|---|---|
| A/D, Space, W/S | Đi, bay, khoan |
| Q / G | Chọn loại quặng / vứt quặng *(chỉ ở Sandbox_A — xem §3.5)* |
| E (ở base) | Shop · **T** (ở base, pha đào): phòng thí nghiệm |
| Chuột trái gần pháo | Vào pháo · 1–4 đổi đạn · Q ra |
| F1 +10 mỗi quặng · F2 wave ngay · F3 hồi base · F4 tới boss | debug phòng thủ |
| F5–F8 nâng cấp đào · F9 mở thang máy · F10 +1 bom | debug đào |

### Menu Unity `Underlab/…`
| Menu | Dùng khi |
|---|---|
| `Art/Generate Missing Placeholders` · `Rebuild Art Database + Report` · `Reimport All Art` | Thêm/sửa dòng manifest, hình lỗi kích thước |
| `Lab/Test Fire Scoring` · `Lab/Test Ice + Acid Scoring` | Sửa chấm điểm thí nghiệm (chạy ở edit mode) |
| `Lab/Open Lab (Play Mode)` | Mở nhanh phòng thí nghiệm khi đang Play |
| `Mining/Test Ore Pickup (Play Mode)` | Sửa phần nhặt quặng |
| `Defense/Verify Play Mode` | **Test tổng phần phòng thủ** (33+ kiểm tra) — chạy sau mỗi thay đổi lớn, kết quả `Logs/DefenseVerification.txt` |
| `Build/Windows` | Build `Builds/Windows/Underlab.exe`, báo cáo `Logs/BuildReport.txt` |
| `Setup/Import TMP Essential Resources` | Máy mới clone thấy chữ TMP lỗi |

### Tool Python (`Tools/`)
| Lệnh | Việc |
|---|---|
| `python Tools/import_ai_batch.py <04_AI_Candidates> --ids <id...> [--preview <thư mục>]` | Đưa ảnh AI vào game (xoá nền, tách frame, căn chân, cập nhật manifest) |
| `python Tools/ui_svg/make_ui_svg.py [--sheet]` | Vẽ lại icon/UI SVG |
| `python Tools/balance_model.py [--apply]` | Mô phỏng cân bằng / ghi số wave + giá vào asset |
| `python Tools/make_asset_list.py` | Sinh lại `Docs/06_ASSET_LIST_CHATGPT.md` từ manifest |

---

## 3. KẾ HOẠCH SẮP TỚI (theo ưu tiên)

### 3.1 🔴 Quái từ 4 phía + loại quái mới — **đang dở, làm tiếp đầu tiên**
Thiết kế: [09_EXPANSION_PLAN.md](09_EXPANSION_PLAN.md) mục B.

**Đã có (commit `532c7d48`):**
- `EnemyKind` thêm: `Armored, Lava, Swarm, Diver, Pod, Burrower, Hatchling` (thêm ở cuối, không đổi giá trị cũ).
- `DefenseConfig.EnemyStats` thêm `visualScale`, `ammoTaken[4]` (hệ số nhận sát thương theo đạn Thường/Axit/Lửa/Băng; <1 kháng, >1 yếu, **<0 hồi máu**), `immuneBurn`, `tint`, `art`. Chỉ số mặc định cho quái mới nằm trong `DefenseConfig.Defaults()`.
- `WaveConfig.Wave` thêm số lượng `armored, lava, swarm, divers, pods, burrowers` + `Total`.

**Cần làm:**
1. **`Enemy.cs`**
   - Đầu `Initialize`: `transform.localScale = stats.visualScale`; màu gốc = `stats.tint` (đoạn đổi màu theo trạng thái độc/cháy/băng phải trả về `tint` thay vì `Color.white`).
   - **Hình dự phòng**: tiền tố art = `stats.art` nếu `ArtDatabase.Get(art + "_walk")` (hoặc `_fly`) có; không thì dùng tạm hình cũ: Armored/Lava/Burrower/Hatchling → `enemy_melee`, Swarm/Diver → `enemy_flying`, Pod → `boss_projectile`. Nhờ vậy khi có hình thật chỉ cần thêm vào manifest là tự dùng.
   - `Hit()`: nếu có `ammo` thì `damage *= stats.ammoTaken[ammoIndex]`; âm ⇒ hồi máu (không vượt `Maximum`); `immuneBurn` ⇒ bỏ qua cháy. Hiện chữ nhỏ "KHÁNG!" / "YẾU ĐIỂM!" bằng `FloatingText.Spawn` (giới hạn 1 lần/0.5 s).
   - Quái bay: thay chỗ `Kind == EnemyKind.Flying` bằng `IsFlyer` (Flying, Swarm, Diver, Pod).
   - Hành vi mới:
     - **Diver**: lượn ngang ở độ cao ~7 trên base 2 s → lao thẳng xuống base tốc độ ×4 → chạm base gây `damage` rồi tự nổ (`Die()`).
     - **Pod**: rơi thẳng có gia tốc từ y≈14; bị bắn chết khi đang rơi thì thôi; chạm đất (y ≤ 0.2) ⇒ `pool.Spawn(Hatchling ×3)` quanh chỗ rơi + `ArtFx.Spawn("fx_explosion")`, rồi tắt. **Spawn con trước khi tắt kén** để `GameManager` không tưởng đã hết quái.
     - **Burrower**: sinh ở y = −1.5, **không bị bắn trúng** khi còn dưới đất; cảnh báo 1.5 s (`ArtFx.Spawn("fx_block_break")` lặp lại + `CameraFollow.Shake`), rồi trồi lên y = 0 trong 0.5 s, sau đó đi như quái cận chiến.
   - Thêm `public Vector3 HitCenter` (quái bay: tâm; quái đất: +1 ô) và `public float HitRadiusMul` (boss 3, swarm 0.6, armored 1.2) ⇒ sửa `Projectile.cs` dùng 2 cái này thay cho đoạn so `EnemyKind.Flying/Boss`.
2. **`WaveSpawner.cs`** — dựng danh sách lượt sinh từ tất cả số lượng, **xáo trộn có seed theo số wave** (ổn định giữa các lần chơi), rồi sinh lần lượt cách nhau `spawnDelay`:
   - Đi bộ (melee/ranged/armored/lava): trái/phải xen kẽ như cũ.
   - Swarm: **nhóm 4 con** cùng lúc, từ 1 bên hoặc từ trên trời.
   - Diver: trên trời, x ngẫu nhiên −8…8, y ≈ 12.
   - Pod: trên trời phía trên base, x −8…8, y ≈ 14.
   - Burrower: dưới đất, x = ±(3…7).
3. **HUD (`DefenseHud.cs`)**
   - **Xem trước wave** (chỉ trong pha đào, giữa trên màn hình): "WAVE 5 SẮP TỚI — Hai bên: 8 bọ · 2 bọ giáp │ Trên trời: 3 bay · 2 kén │ Dưới đất: 2 đào hầm", kèm gợi ý khắc chế khi có (bọ giáp → axit, dung nham → băng). Dữ liệu: `game.config.waves[game.Wave]` khi `game.Phase == Mining`.
   - **Mũi tên mép màn hình** cho quái ngoài tầm nhìn: pool ~12 `Image` (`ui_ammo_slot` tô đỏ + chữ "!"), vị trí = toạ độ quái chiếu ra màn hình rồi kẹp vào mép. Lưu ý font: Roboto **không** có ◄ ▲ ▼ ► ⇒ ₂ (mũi tên → có nhờ font dự phòng LiberationSans).
4. **Cân bằng**: thêm quái mới vào `Tools/balance_model.py` (bảng `ENEMY`, tuple wave, hàm `apply` ghi thêm 6 trường), chia quái mới vào wave 3–10, chạy `--apply`. Gợi ý: bọ giáp từ wave 3, đàn bay từ wave 3, kén từ wave 4, bổ nhào từ wave 5, đào hầm từ wave 6, dung nham từ wave 6.
5. **Test**: chạy `Defense/Verify Play Mode` (click vào Unity), rồi chơi tay 1 run.
6. **Art** (gửi người gen ảnh): thêm dòng manifest cho `enemy_armored_*`, `enemy_lava_*`, `enemy_swarm_fly/death`, `enemy_diver_fly/death`, `enemy_pod` (tĩnh), `enemy_burrower_*`, `enemy_hatchling_walk/death` (cột giống `enemy_melee_*`) → `python Tools/make_asset_list.py` để sinh prompt → gen → `import_ai_batch.py`.

### 3.2 🟠 Playtest + chỉnh phòng thí nghiệm
- Chơi đủ 3 thí nghiệm. Chỉnh trong `Assets/_Game/Data/Lab/LabConfig.asset`: sai số `tolerance` (đang 5%), cỡ thìa `scoopGrams`, độ trễ cân `scaleLag`, van `maxFlow / overPressureOpen`, rót `maxPour`, khuấy `stirGood / stirSpill`, lò `heaterTimeConstant / contactExoHeat`, thời gian giữ nhiệt `contactHoldSeconds`.
- Nếu quá khó: tăng `tolerance` lên 0.08 trước khi đụng thứ khác.
- Sửa chấm điểm thì chạy lại `Lab/Test …`.

### 3.3 🟠 Điện phân nước (thay bình O₂ tự nạp)
Hiện `LabStation` tự nạp O₂ `+1.2 L/s` (tạm). Kế hoạch: thêm quặng **băng H₂O** (ResourceType mới ⇒ sửa `GameTypes.cs`, `ResourceBank` mảng 4 → 5+, HUD 2 bên, `TerrainConfig.ores`) + trang thí nghiệm **Điện phân** 2H₂O → 2H₂ + O₂ (thu đúng tỉ lệ thể tích 2:1) để nạp bình O₂. Đây là việc lớn (đụng hợp đồng Core) — làm sau 3.1.

### 3.4 🟡 Art còn thiếu
- 6 ảnh gen lại (`char_player_carry`, `tile_ore_mg`, `tile_ore_kcl`, `bg_surface_far`, `bg_surface_mid`, `bg_underground_mid`) — chi tiết [08_AI_ASSET_REVIEW.md](08_AI_ASSET_REVIEW.md). Có ảnh mới: bỏ vào `04_AI_Candidates/<id>/chon.png` → `import_ai_batch.py --ids …` (bg mặt đất: xoá dòng `crop_bottom` trong `OVERRIDES`).
- Art quái mới (§3.1 bước 6).

### 3.5 🟡 Việc nhỏ
- **Vứt quặng trong `Game.unity`**: thêm component `OreDropper` vào `Player` và kéo nó vào ô `dropper` của `MiningHud` trên `[Mining Systems]` (Sandbox_A đã có).
- Đổi `Project Settings → Player → Product Name` thành **Underlab**, Company Name tuỳ.
- HUD phòng thủ từng báo NullReference ở `RefreshBase` 1 lần (không tái hiện); đã thêm kiểm tra tự lấy lại `ResourceBank` và in lỗi rõ — nếu thấy log `[DefenseHud]` thì báo.

### 3.6 🟢 Trước khi nộp (từ 7/12)
- **9/12 art freeze**: không nhận hình mới.
- Build Windows → chơi trên máy khác (copy cả thư mục `Builds/Windows`) → quay video demo.
- Báo cáo/slide: dùng GDD + [09_EXPANSION_PLAN.md](09_EXPANSION_PLAN.md) (phần hoá học) + ảnh chụp game.

### (Nếu dư thời gian) Tầng 2 trong kế hoạch
Chỉ số riêng từng loại đạn + cây nâng cấp đạn (C1/C2), pháo quá nhiệt (C3), bình O₂ của thợ mỏ (A4), biến cố wave (mưa axit, bão từ).

---

## 4. Lưu ý dễ vấp
- **Không commit** `Assets/TextMesh Pro/Resources/Fonts & Materials/LiberationSans SDF - Fallback.asset` khi nó tự thay đổi (TMP ghi thêm ký tự lúc chạy) → `git checkout -- <file>`.
- `Assets/Art/content` (bộ tham khảo) — không sửa; Unity hay tự đổi 1 vài `.meta` ở đó → bỏ qua.
- Hình chỉ dùng qua **art id** (`ArtSprite.Play`, `ArtDatabase.GetSprite`, `ArtFx.Spawn`) — không kéo PNG vào prefab.
- Đạn: code **xoay theo hướng bay** ⇒ hình đạn phải chĩa **PHẢI**.
- Chữ TMP dùng `GameFonts.MainTMP`; chỉ số dưới viết `<sub>2</sub>` (font không có ₂).
- Quái mới spawn từ kén/boss phải được tạo **trước** khi quái cha tắt, nếu không wave kết thúc sớm.
- Sửa `Scripts/Core` (GameTypes/GameEvents) ⇒ kiểm tra cả phần đào lẫn phòng thủ.
