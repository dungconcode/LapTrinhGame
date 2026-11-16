# UNDERLAB — Roadmap 4 tuần (16/11 → 13/12/2026)

> Đọc kèm: [02_ASSET_PIPELINE.md](02_ASSET_PIPELINE.md) (hệ thống asset), [05_GIT_WORKFLOW.md](05_GIT_WORKFLOW.md) (cách merge).
> Tick `[x]` khi xong. Mỗi task có **ID** để ghi vào tên nhánh / commit (vd `a/A03-dig`, `feat(A03): ...`).

## ⚡ CẬP NHẬT 16/11 tối — trạng thái & chia việc mới

**Đã xong (trên `main`):** toàn bộ Dev A (A01–A13) + Dev B (B01–B16) bản greybox. `Game.unity` chơi được trọn 1 run: đào → về base → shop (E) → pháo (chuột trái) → 10 wave + boss → thắng/thua.

**Chia việc mới:**

| Ai | Làm gì |
|---|---|
| **Dev chính (code)** — 1 người + Claude | TOÀN BỘ code còn lại (bảng R dưới). Giữ luôn `Game.unity`, không cần "token". |
| **Bạn gen asset** | Chỉ gen ảnh bằng ChatGPT Plus theo [06_ASSET_LIST_CHATGPT.md](06_ASSET_LIST_CHATGPT.md) (76 asset có prompt dán sẵn), bỏ ảnh thô vào Drive `04_AI_Candidates/<id>/`. Không cần Unity/git. |
| **Claude** | Icon + khung UI (`icon_*`, `ui_*`) bằng SVG; xử lý ảnh từ Drive bằng `ai_sheet.py` rồi đưa vào game. |
| **Nhóm art** | Như cũ: vẽ final, ưu tiên cái chưa `ai-approved`. |

**Việc còn lại (R = remaining):**

- [ ] **R01** Dựng lại `Game.unity` có vứt quặng (Q/G) — `Underlab/Defense/Build Integrated Game`
- [ ] **R02** Playtest trọn 1 run, ghi lỗi/cảm giác → sửa
- [ ] **R03** Cân bằng: giá upgrade, 10 wave, thời gian đào; mục tiêu run 15–20 phút (`Data/Defense`, `Data/Mining`)
- [ ] **R04** Icon + UI SVG (Claude) — thay khối màu
- [ ] **R05** Đưa asset ChatGPT vào game theo đợt (P0 → P1 → P2)
- [ ] **R06** A15 âm thanh + juice phần đào; sửa cảnh báo font `LegacyRuntime` ở HUD TMP
- [ ] **R07** Main menu / màn thắng-thua dùng art thật
- [ ] **R08** Build Windows, chơi trên máy khác, quay video demo (hạn 11/12)
- [ ] **R09** (Could) A14 Teleporter

**Hạn asset:** P0 (28 cái) **20/11** · P1 (38) 27/11 · P2 (10) 4/12 · **art freeze 9/12**.

> Các mục cũ bên dưới giữ lại để tham khảo; phần chia "Dev A / Dev B" giờ là của 1 người code.

## 0. Nguyên tắc

1. **Code không chờ art.** Ngày 1 chạy `Underlab/Art/Generate Missing Placeholders` → có đủ ~110 asset khối màu đúng kích thước. Art về thì chép đè, code không đổi.
2. **2 dev chia theo "nửa game":** Dev A = dưới lòng đất (Mining), Dev B = trên mặt đất (Defense + vòng chơi + UI chung). Gặp nhau qua `GameEvents` + `GameTypes` (folder `Scripts/Core`).
3. **Mỗi tuần có 1 bản chơi được** (milestone) trên `main`. Chủ nhật = ngày merge + chơi thử + quyết art.
4. **Số liệu cân bằng để trong ScriptableObject** (`Assets/_Game/Data`), không hard-code → chỉnh balance không đụng code của nhau.

| Vai | Ai | Phụ trách | AI asset |
|---|---|---|---|
| **Dev A – Mining** | (bạn chọn) | Player, terrain, đào, quặng, trọng tải, về base, Lift/Teleport/Blast, HUD đào | Gemini (tile, quặng, bg, fx) + Claude (SVG UI/icon) |
| **Dev B – Defense** | (bạn chọn) | Game loop/phase, base HP, pháo, đạn, quái, wave, boss, upgrade/kinh tế, menu/HUD phòng thủ | ChatGPT Plus (nhân vật, quái, boss, base, pháo) |
| **Art team** | nhóm art | Vẽ final theo thứ tự ưu tiên P0→P2, bỏ qua item đã `ai-approved` | — |

> Gợi ý: ai dùng Codex + ChatGPT Plus nên làm **Dev B** (nhiều asset nhân vật/quái cần ChatGPT nhất).

---

## 1. Cắt scope (MoSCoW)

| Must (phải có để nộp) | Should | Could | Won't (bỏ) |
|---|---|---|---|
| Đào 3 tầng cứng, 4 quặng, trọng tải làm chậm, về base gửi kho, đồng hồ wave + cảnh báo, base HP, pháo xoay tay, 3 loại quái, wave tăng dần, 4 loại đạn (thường/axit/lửa/băng), nâng cấp cơ bản, boss cuối, thắng/thua, main menu | Lift, Blast Mining, cây upgrade UI đẹp, base hư hại theo HP, âm thanh | Teleporter, base upgrade visual, nhiều map seed | Đổi hành tinh, save giữa run, multiplayer |

**Win:** sống qua **wave 10** (wave 10 = boss). **Lose:** base HP = 0.

---

## 2. Tuần 0 — Ngày 1 (16–17/11): Khởi động chung ✅ làm cùng nhau ~2 tiếng

- [ ] **C00** Commit sạch repo: commit các `.meta` đang untracked + `ProjectSettings` (xem 05_GIT_WORKFLOW §1). Cả 2 pull về.
- [ ] **C01** Mở Unity → `Underlab/Art/Generate Missing Placeholders` → commit PNG placeholder + `ArtDatabase.asset` + `_GeneratedTiles`.
- [ ] **C02** Thống nhất `Scripts/Core/GameTypes.cs` + `GameEvents.cs` (đã có bản nháp — đọc, sửa nếu thiếu event, merge).
- [ ] **C03** Tạo scene: `Scenes/Game.unity` (scene chính), `Scenes/Sandbox_A.unity`, `Scenes/Sandbox_B.unity`. Camera: Orthographic, size ~8, 1 unit = 1 tile.
- [ ] **C04** Tạo Google Drive theo cấu trúc trong [03_ART_TEAM_GUIDE.md](03_ART_TEAM_GUIDE.md) + gửi guide cho nhóm art.
- [ ] **C05** **Style lock**: gen 4–6 ảnh "style frame" bằng AI (prompt trong 04_AI_PROMPTS §1) → cả nhóm (dev + art) chọn 1 → lưu `00_StyleGuide/style_key.png` + bảng màu. **Mọi asset sau đều theo ảnh này.**

---

## 3. Tuần 1 (16–22/11): Greybox — vòng lặp đào → phòng thủ chạy được

**Milestone M1 (CN 22/11):** Đào xuống, nhặt quặng, chậm khi nặng, về base → kho tăng; đồng hồ hết → 1 wave quái cận chiến đi tới base, bắn bằng pháo, base mất máu, thua khi HP=0. Toàn placeholder là OK.

### Dev A
- [ ] **A01** `PlayerController`: đi trái/phải, nhảy/leo (Input System), Rigidbody2D, flip sprite. Dùng `ArtSprite` (`char_player_idle/walk`).
- [ ] **A02** `TerrainGenerator`: Tilemap lưới W×H (vd 40×120), 3 dải độ sâu → `tile_dirt_1/2/3`, rải quặng theo xác suất từng tầng (config `TerrainConfig` SO). Hàng 0 = `tile_surface`.
- [ ] **A03** `Drill`: giữ hướng → gây "damage" vào ô; HP ô theo độ cứng; overlay `tile_crack` (SetFrame 0–3); vỡ → xoá tile, spawn `fx_block_break`, nếu là quặng spawn `item_ore_*`.
- [ ] **A04** `Carrier`/Inventory: nhặt quặng, tổng trọng lượng → giảm speed (`speed = base * curve(weight/max)`), phát `ResourcePickedUp`, `CarryWeightChanged`.
- [ ] **A05** Vùng base (trigger): vào → gửi hết quặng → phát `ResourcesDeposited` từng loại, `PlayerAtBaseChanged`.
- [ ] **A06** Camera follow (Cinemachine hoặc script đơn giản), giới hạn biên map.

### Dev B
- [ ] **B01** `GameManager` state machine: Mining (đếm ngược) → Defense → (hết quái) → Mining…; phát `PhaseChanged`, `WaveCountdown`, `WaveWarning` (còn 10s), `WaveStarted/Cleared`. Config `WaveConfig` SO.
- [ ] **B02** `Base`: HP, nhận damage, phát `BaseHpChanged`, HP=0 → GameOver.
- [ ] **B03** `Turret`: xoay nòng theo chuột/phím (tốc độ xoay giới hạn), bắn `proj_normal`, cooldown. Sprite `bld_turret_body` + `bld_turret_barrel` (pivot đuôi nòng sẵn).
- [ ] **B04** `Enemy` base class + `EnemyMelee`: đi tới base, đánh, nhận damage, chết. Object pool cho quái + đạn.
- [ ] **B05** `WaveSpawner`: spawn theo `WaveConfig` (số lượng, loại, delay), 2 bên màn hình.
- [ ] **B06** `ResourceBank`: nghe `ResourcesDeposited` → cộng kho → phát `BankChanged`. HUD tạm (TextMeshPro) hiện kho + HP + đồng hồ.

### AI asset tuần 1 (song song, mỗi người ~1h/ngày)
- [ ] **AI-1** (B/ChatGPT) `char_player_*` P0, `bld_base_normal`, `bld_turret_body/barrel`, `enemy_melee_walk/attack`.
- [ ] **AI-2** (A/Gemini) `tile_surface`, `tile_dirt_1/2/3`, `tile_ore_*` ×4, `item_ore_*` ×4, `bg_underground_far`, `bg_surface_sky`.

---

## 4. Tuần 2 (23–29/11): Hệ thống đầy đủ — vertical slice

**Milestone M2 (CN 29/11):** Đủ 3 loại quái, 4 loại đạn có hiệu ứng, nâng cấp mua được bằng quặng, đào sâu có cân nhắc thời gian, HUD 2 pha. Asset P0 đã là bản AI.

### Dev A
- [ ] **A07** Độ cứng theo tầng + nâng cấp drill (damage/tốc độ) đọc từ upgrade (nghe `UpgradePurchased`).
- [ ] **A08** Nâng cấp tốc độ di chuyển + sức mang. Anim `char_player_carry` khi > 60% tải.
- [ ] **A09** HUD đào: thanh trọng tải (`ui_bar_frame/fill`), độ sâu (`ui_depth_meter`), mini cảnh báo wave (nghe `WaveCountdown`).
- [ ] **A10** Cảnh báo wave cho người đang đào: âm thanh + rung màn hình nhẹ + viền đỏ khi < 10s.
- [ ] **A11** Chuyển cảnh mặt đất ↔ lòng đất (parallax `bg_*` 2 lớp, đổi nhạc).

### Dev B
- [ ] **B07** `EnemyFlying` (bay thẳng/lượn tới base) + `EnemyRanged` (đứng xa bắn `proj_enemy`).
- [ ] **B08** Đạn đặc biệt + status effect: Axit (độc DoT, `fx_status_poison`), Lửa (x2 dmg + cháy, tốn 2 Mg/viên), Băng (chậm di chuyển + tốc đánh). Chọn đạn bằng phím 1–4 / UI `ui_ammo_slot`.
- [ ] **B09** Chế tạo đạn: đổi quặng → đạn (S → Axit, 2Mg → Lửa, KCl → Băng) — UI ở base.
- [ ] **B10** `UpgradeDef` SO + shop: drill, move, carry, turret dmg, turret rotate, base HP, repair. Phát `UpgradePurchased`.
- [ ] **B11** Độ khó tăng dần: `WaveConfig` 10 wave (số lượng / HP / tốc độ / phối hợp 3 loại).
- [ ] **B12** HUD phòng thủ: HP base, đồng hồ `ui_wave_timer`, slot đạn, tâm ngắm `ui_crosshair`.

### AI asset tuần 2
- [ ] **AI-3** (B) `enemy_flying_*`, `enemy_ranged_*`, `proj_*`, `bld_base_damaged`, `ui_logo`.
- [ ] **AI-4** (A) toàn bộ `icon_*` + `ui_*` P0 bằng Claude SVG; `fx_*` P1 (hoặc làm bằng Particle System).
- [ ] **ART-SYNC 1 (CN 29/11)**: duyệt AI → đánh `ai-approved` cái nào đẹp → nhóm art bỏ qua cái đó.

---

## 5. Tuần 3 (30/11–6/12): Nội dung + Boss + Polish vòng 1 — FEATURE LOCK 6/12

**Milestone M3 (CN 6/12):** Chơi trọn 1 run 10 wave có boss, thắng/thua, main menu, âm thanh. Sau 6/12 **không thêm tính năng**, chỉ sửa lỗi + thay art + cân bằng.

### Dev A
- [ ] **A12** **Lift** (Should): đặt điểm lift, quặng gửi lên tự động / người đi lên nhanh.
- [ ] **A13** **Blast Mining** (Should): mua `item_blast_charge`, đặt nổ phá vùng 3×3, `fx_blast`.
- [ ] **A14** Teleporter (Could) — chỉ làm nếu A12–A13 xong trước thứ 4.
- [ ] **A15** Âm thanh đào/nhặt/bước chân; juice: squash-stretch nhân vật, rung khi vỡ block.

### Dev B
- [ ] **B13** **Boss** wave 10: 2–3 pattern (lao, bắn `boss_projectile`, gọi quái), thanh máu boss, chết → Victory.
- [ ] **B14** Main menu, Pause, màn Victory / Game Over (restart).
- [ ] **B15** Cây upgrade UI (`ui_upgrade_node`), tooltip giá.
- [ ] **B16** Âm thanh bắn/nổ/quái/cảnh báo; nhạc 2 pha.

### Chung
- [ ] **C06** Playtest nội bộ 2 lần (thứ 4 + CN), ghi bug vào Issue GitHub.
- [ ] **AI-5** Boss (B), bg P1 (A), các asset còn `placeholder`.
- [ ] **ART-SYNC 2 (thứ 4 2/12) + 3 (CN 6/12)**.

---

## 6. Tuần 4 (7–13/12): Thay art final, cân bằng, build

**Milestone M4 – RELEASE (thứ 6 11/12)**, 12–13/12 dự phòng.

- [ ] **C07** **Art freeze thứ 4 9/12**: art final nào về trước hạn thì thay, sau hạn giữ bản AI.
- [ ] **C08** Cân bằng: thời gian 1 run ~15–20 phút, wave 1 dễ, boss khó vừa. Chỉnh trong SO.
- [ ] **C09** Sửa bug từ playtest, kiểm tra 1920×1080 + 1366×768.
- [ ] **C10** Build Windows, chơi thử bản build trên máy khác, quay video demo.
- [ ] **C11** Slide/báo cáo (dùng lại GDD + ảnh chụp game).

---

## 7. Phụ thuộc giữa 2 dev (để không ai phải chờ)

| Cần | Ai cần | Thay thế tạm khi chưa có |
|---|---|---|
| `ResourcesDeposited` từ A05 | B06 | B gọi `GameEvents.RaiseResourcesDeposited` bằng phím debug |
| `PhaseChanged`/`WaveCountdown` từ B01 | A09, A10 | A tự phát event bằng phím debug trong Sandbox_A |
| `UpgradePurchased` từ B10 | A07, A08 | A đọc giá trị trực tiếp từ SO trong Inspector |
| Art bất kỳ | mọi người | Placeholder khối màu (đã có) |

**Quy ước phím debug** (chỉ trong Editor, `#if UNITY_EDITOR`): F1 = +10 mỗi quặng, F2 = bắt đầu wave ngay, F3 = base hồi đầy, F4 = skip tới wave boss.

---

## 8. Ghi chú nội dung (hoá học trong GDD)

GDD cần sửa 2 chỗ trước khi đưa vào UI/báo cáo:
- Axit: phương trình rút gọn cân bằng đúng là **2S + 3O₂ + 2H₂O → 2H₂SO₄** (bản cũ thiếu hệ số).
- Băng: **hoà tan KCl vào nước là quá trình thu nhiệt** (không phải phản ứng hoá học) → ghi là "KCl hoà tan thu nhiệt".
- Lửa: 2Mg + O₂ → 2MgO (toả nhiệt) — đúng.
