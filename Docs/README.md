# UNDERLAB — Tài liệu dự án

| File | Cho ai | Nội dung |
|---|---|---|
| [01_ROADMAP.md](01_ROADMAP.md) | 2 dev | 4 tuần, milestone, task ID chia Dev A / Dev B, phụ thuộc, scope |
| [02_ASSET_PIPELINE.md](02_ASSET_PIPELINE.md) | 2 dev | Hệ thống asset 3 tầng (placeholder → AI → final), manifest, cách code dùng, cách thay art |
| [03_ART_TEAM_GUIDE.md](03_ART_TEAM_GUIDE.md) | **nhóm art** | Thông số vẽ, đặt tên, cấu trúc Drive, lịch art mới, checklist |
| [04_AI_PROMPTS.md](04_AI_PROMPTS.md) | 2 dev | Chia việc ChatGPT/Gemini/Claude, style block, prompt từng loại asset |
| [05_GIT_WORKFLOW.md](05_GIT_WORKFLOW.md) | 2 dev | Nhánh, ownership folder, tránh conflict scene, Smart Merge |
| [07_BALANCE.md](07_BALANCE.md) | dev | Số cân bằng hiện tại, lý do, cách chỉnh lại sau playtest (`Tools/balance_model.py`) |
| [06_ASSET_LIST_CHATGPT.md](06_ASSET_LIST_CHATGPT.md) | **người gen asset** | 76 asset cần gen bằng ChatGPT, prompt dán sẵn, thứ tự ưu tiên, cách nộp lên Drive. Sinh lại: `python Tools/make_asset_list.py` |
| [../AGENTS.md](../AGENTS.md) / [../CLAUDE.md](../CLAUDE.md) | Codex / Claude Code | Quy ước code để AI agent tuân theo |
| [../Assets/_Game/Art/asset_manifest.csv](../Assets/_Game/Art/asset_manifest.csv) | tất cả | Danh sách ~110 asset + trạng thái (import vào Google Sheets để share nhóm art) |
| [../Tools/ai_sheet.py](../Tools/ai_sheet.py) | 2 dev | Ảnh AI → PNG chuẩn (xoá nền, cắt grid, căn pivot) |

## Bắt đầu ngay (ngày 1)
1. Đọc ROADMAP §2 (Tuần 0) — làm cùng nhau C00–C05.
2. Unity → menu **Underlab ▸ Art ▸ Generate Missing Placeholders**.
3. Mỗi người tạo nhánh task đầu tiên (`a/A01-player`, `b/B01-gamemanager`) và code bằng placeholder.
4. Song song, gen asset P0 theo `04_AI_PROMPTS.md`.
