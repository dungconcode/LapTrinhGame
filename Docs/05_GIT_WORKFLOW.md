# Git workflow cho 2 dev Unity — ít conflict nhất có thể

Repo: `github.com/dungconcode/LapTrinhGame` · Unity **6000.0.44f1** (cả 2 phải dùng ĐÚNG bản này).

## 1. Dọn repo lần đầu (task C00 — 1 người làm, người kia chờ rồi pull)

✅ Đã làm: commit `chore(C00)` đẩy lên `main` gồm `Assets/_Game` (pipeline + placeholder), `Docs`, `Tools`, `AGENTS.md`, `CLAUDE.md`, `.gitattributes`.

Folder `Assets/Art/content` (bộ asset tham khảo) do bạn kia quản lý — **không commit `.meta` của nó từ máy khác**, để nguyên như trên remote.

Người còn lại: `git pull`, mở Unity, kiểm tra không lỗi console.

**Luôn commit file `.meta` đi kèm file của nó.** Thiếu `.meta` = máy người kia mất tham chiếu (prefab bị Missing).

## 2. Nhánh

```
main                 luôn chơi được (build không lỗi)
 ├─ a/A03-drill      nhánh ngắn của Dev A, 1 task = 1 nhánh
 ├─ b/B04-enemy      nhánh ngắn của Dev B
 └─ art/2411         nhánh thay art theo đợt (ai đang rảnh làm)
```
- Nhánh sống **tối đa 1–2 ngày**. Xong task → Pull Request vào `main` → người kia lướt qua → merge.
- **Mỗi sáng:** `git pull origin main` vào nhánh mình (hoặc `git merge main`) để không bị lệch xa.
- Nhánh cũ `Dung_Dev` có thể giữ, nhưng đừng để nó lệch `main` quá 2 ngày.

Commit message: `feat(A03): drill damages tiles` · `fix(B05): ...` · `art(enemy_melee_walk): ai v2` · `chore: ...`

## 3. Ai sở hữu gì (không sửa đồ của người kia khi chưa nhắn)

| Đường dẫn | Chủ |
|---|---|
| `Assets/_Game/Scripts/Core/` | **Chung** — sửa = nhắn trước, PR riêng thật nhỏ |
| `Assets/_Game/Scripts/Mining/`, `Player/`, `UI/Mining/` | Dev A |
| `Assets/_Game/Scripts/Defense/`, `Enemies/`, `Game/`, `UI/` (trừ Mining) | Dev B |
| `Assets/_Game/Prefabs/Mining/` · `Prefabs/Defense/` | A · B |
| `Assets/_Game/Data/Mining/` · `Data/Defense/` | A · B |
| `Assets/_Game/Art/**` + `asset_manifest.csv` | Ai cũng được, **nhưng 1 dòng CSV 1 lúc** — commit art riêng, không trộn với code |
| `Scenes/Sandbox_A.unity` · `Sandbox_B.unity` | A · B (tha hồ nghịch) |
| `Scenes/Game.unity` | **"Cầm token"**: ai cần sửa thì nhắn Discord "tao cầm Game.unity", xong push rồi nhả |

## 4. Tránh conflict scene/prefab

- **Mọi thứ là prefab.** Scene `Game.unity` chỉ chứa vài prefab gốc: `[Systems]`, `[World]`, `[Base]`, `[UI]`, `Main Camera`. Sửa logic = sửa prefab, không sửa scene.
- Test trong Sandbox của mình; chỉ đưa vào `Game.unity` khi đã chạy.
- Cấu hình (giá upgrade, wave, độ cứng…) = ScriptableObject riêng từng file → 2 người sửa 2 file khác nhau.
- Không tự format lại / đổi tên file của người kia.

## 5. Bật Unity Smart Merge (mỗi máy chạy 1 lần)

`.gitattributes` đã khai báo scene/prefab/asset dùng merge driver `unityyamlmerge`. Mỗi người chạy (sửa đường dẫn nếu cài Unity chỗ khác):

```bash
git config merge.unityyamlmerge.name "Unity SmartMerge"
```

```bash
git config merge.unityyamlmerge.driver "'C:/Program Files/Unity/Hub/Editor/6000.0.44f1/Editor/Data/Tools/UnityYAMLMerge.exe' merge -p %O %B %A %A"
```

Chưa chạy lệnh này thì git vẫn merge bình thường (chỉ kém thông minh hơn với scene/prefab).

Nếu vẫn conflict ở `.unity`/`.prefab`: **đừng sửa tay**. Chọn bản 1 bên (`git checkout --theirs file` hoặc `--ours`), rồi làm lại thay đổi nhỏ của bên kia trong Unity.

## 6. Ảnh & file nặng

- Repo **chỉ chứa PNG đang dùng**. PSD, bản thô AI, các phương án → Google Drive.
- Không cần Git LFS cho quy mô này (PNG game < 100 MB tổng). Nếu 1 file > 50 MB → đừng commit.

## 7. Nhịp làm việc

| Khi nào | Làm gì |
|---|---|
| Mỗi sáng | pull `main`, đọc Discord, nhận task trong ROADMAP |
| Mỗi tối | push nhánh (kể cả chưa xong), ghi 1 dòng tiến độ |
| Thứ 4 | merge giữa tuần + ART-SYNC |
| Chủ nhật | merge hết vào `main`, chơi thử milestone, ART-SYNC, chia task tuần sau |
