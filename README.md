# cua-driver-mcp

把 **Cua Driver**（`cua-driver`）探测、安装并注册为 computer-use MCP server 的 Agent Skill，支持 Windows 与 macOS，覆盖 Claude Code、Codex、Cursor、Qwen 等客户端。

## 它解决什么

让 agent 能真正操作桌面 GUI——点击、输入、截图、读窗口、驱动浏览器。前提是本机装好 `cua-driver` 并把它的 MCP server 注册到对应客户端，而这两步在不同平台、不同客户端上的写法和坑都不一样。这个 Skill 把整条链路固化成可复现的流程。

## 核心约束

安装、注册、自启是三件独立的事，每件都要单独向用户确认：

- 用户没明确要求，不注册开机自启（计划任务 / LaunchAgent）。
- 用户没说注册到哪个客户端，不写任何客户端配置文件。
- 用户只说"看看能不能用"时，装好并 `cua-driver call` 验一次即可，不落常驻配置。

## 流程

1. **探测** — 永远先做。跑 `scripts/detect.ps1`（Windows）或 `scripts/detect.sh`（macOS）拿 JSON，然后 `doctor` / `status` / `manifest` 逐个看。
2. **安装** — 仅在探测不到可用安装时。先落盘再看再执行，不 `irm | iex` 盲跑。
3. **确认** — 一次问清客户端、自启、PATH 三件事。
4. **注册** — `cua-driver mcp-config --client <name>`，或自研 agent 走 `manifest.mcp_invocation`。
5. **验证** — `doctor` 全绿、`list-tools` 含 `get_screen_size` / `get_window_state` / `run_steps`、实调一次、自启状态与用户选择一致。

## 目录

```
SKILL.md                     主流程与硬约束
references/clients.md        各客户端注册写法与坑
references/platforms.md      平台安装、离线补救、卸载
references/troubleshooting.md pipe 连不上、UWP、浏览器 consent、token 失效
scripts/detect.ps1           Windows 探测，输出 JSON
scripts/detect.sh            macOS/Linux 探测，输出 JSON
```

## 安装为 Skill

把整个目录放到客户端的 skills 目录下（目录名保持 `cua-driver-mcp`），或直接让 agent 读取本目录的 `SKILL.md`。

## 许可

本 Skill 是使用指南，不含 Cua Driver 本体。Cua Driver 的许可与分发条款见其官方发布物。
