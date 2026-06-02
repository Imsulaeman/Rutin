# Log

---

## 2026-06-02

- Fixed Gradle daemon OOM crash: reduced JVM heap from `-Xmx4g` to `-Xmx2g`, trimmed Metaspace to 512m and CodeCache to 128m in `android/gradle.properties`. Machine has 5GB RAM; 4GB JVM left no headroom.
- Ran full app review pass: `/impeccable`, `/gpt-taste`, `/emil-design-eng` + Senior Developer security + code audit. Output: `report.md`.
- Added P1–P4 action items to `TODO.md` (From Review Report section).
- Added 3 AGENTS.md specs for P1 tasks: custom fonts (Bricolage Grotesque + DM Sans), permission dialog rewrite (step-by-step bottom sheet), Hive encryption (medicines + medicine_logs + tb_profiles).
