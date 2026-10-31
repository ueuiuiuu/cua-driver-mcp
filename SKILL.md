---
name: cua-driver-mcp
description: Install, detect, and register Cua Driver (cua-driver) as a computer-use MCP server on Windows or macOS, asking the user before registering MCP or enabling autostart.
metadata:
  short-description: Connect Cua Driver as a computer-use MCP server
---

# Cua Driver MCP 接入

## 何时用

用户要你操作桌面 GUI（点击、输入、截图、读窗口、驱动浏览器），或提到 cua-driver / cua.ai / computer use，或要求把某个驱动注册成 MCP。

## 三个不可合并的决定

安装、注册、自启是三件事，每件单独确认：

- 用户没明确要求，就不要注册开机自启（计划任务 / LaunchAgent）。
- 用户没说注册到哪个客户端，就不要写任何客户端配置文件。
- 用户只说"看看能不能用"时，装好 + 用 `cua-driver call` 验一次即可，不落常驻配置。

## 一、探测（永远先做）

禁止假设平台、路径、是否已安装。先跑 `scripts/detect.ps1` 或 `scripts/detect.sh` 拿 JSON，或手工：

Windows:

```
(Get-Command cua-driver -ErrorAction SilentlyContinue).Source
Test-Path "$env:LOCALAPPDATA\Programs\Cua\cua-driver\bin\cua-driver.exe"
Test-Path "$env:USERPROFILE\.cua-driver\packages\current\cua-driver.exe"
```

macOS:

```
command -v cua-driver
test -x "$HOME/.local/bin/cua-driver" && echo "$HOME/.local/bin/cua-driver"
```

找到二进制后依次执行，并把结果摆给用户：

```
<exe> doctor        # install dir / home dir / 会话 / UIA / 捕获能力
<exe> status        # daemon 是否在跑、socket 或 pipe
<exe> manifest      # 版本 + mcp_invocation（注册用的 command/args 从这里取）
```

Windows 追加 `<exe> autostart status`。

四种局面：

- 用户给的是 zip 或解压出来的目录 → 在里面找 `cua-driver.exe` 作为候选，不要因为"有目录"就判定已安装
- 没找到 → 走安装
- 找到且 `doctor` 全绿 → 复用，不要装第二份；用户给了路径就以他的为准
- 找到但 `doctor` 有 fail 或版本明显过旧 → 报告差异，问是否 `update --apply`，不要擅自升级

## 二、安装（仅在没有可用安装时）

绝不 `irm | iex` 盲跑：先落盘，看过再执行。

Windows:

```
irm https://cua.ai/driver/install.ps1 -OutFile install-cua.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install-cua.ps1 -NoAutoStart
```

macOS:

```
curl -fsSL https://cua.ai/driver/install.sh -o install-cua.sh
bash install-cua.sh
cua-driver permissions grant
```

装完必须 `doctor` 通过才继续。macOS 的 `permissions grant` 会申请辅助功能与屏幕录制，必须在真实桌面会话里点同意，不能静默完成。

`-NoAutoStart`、`--bin-dir`、`CUA_DRIVER_RS_HOME` 等参数与离线补救见 `references/platforms.md`。

## 三、问用户（一次问清）

1. 要注册到哪个客户端？（codex / claude / cursor / 自研）自研需要知道它怎么拉起子进程。
2. Windows 上要不要开机自启？说清代价：自启 = 计划任务以最高权限常驻，能驱动 UWP/商店应用（计算器、设置、照片）；不自启 = 每次由客户端拉起，权限随调用方，UWP 应用的 UIA 树可能被截断。
3. 是否允许改 PATH？只给绝对路径可以完全跳过。

如果探测到**已经存在**自启任务，单独问一句：保留还是移除。不要默认删——那可能是用户或别的工具装的。

macOS 的 `autostart` 子命令当前不适用（官方标注 Windows-only），不要自行创建 LaunchAgent。

## 四、注册

```
<exe> mcp-config --client <name>     # 打印对应客户端的注册命令/配置
<exe> mcp-config                      # 通用 mcpServers JSON
```

支持的 client：claude、codex、cursor、antigravity、openclaw、opencode、hermes、pi、prime-agent、qwen、droid、zcode。逐家写法与坑见 `references/clients.md`。

Codex 直接：`codex mcp add cua-driver -- "<exe>" mcp`

自研 agent：从 `manifest.mcp_invocation` 取 command/args，stdio JSON-RPC，顺序 `initialize` → `notifications/initialized` → `tools/list` → `tools/call`。stdout 只能有 JSON-RPC，日志走 stderr。

## 五、验证（不许跳过）

- `<exe> doctor` 全绿
- `<exe> list-tools` 非空，且含 `get_screen_size`、`get_window_state`、`run_steps`
- 实调一次：`<exe> call get_screen_size`（需要 daemon 在跑），或走 MCP 客户端 handshake
- **自启状态必须和用户的选择一致**：要了自启就 `registered (running)`，没要就 `not-registered`。这条要主动核对并告知，不要沿用上一轮的结论

## 六、把使用规范交给调用方

`initialize` 响应里的 `instructions` 是官方使用手册，原样喂给模型。更细的手册按需 `resources/read skill://cua-driver/SKILL.md`，以及同目录的 `WINDOWS.md`、`BROWSER.md`、`WORKFLOW.md`。

## 硬约束

- 未经用户要求，不要 `autostart enable`、不要改 PATH、不要删除任何已有任务或配置
- 不要移动或删除用户已有的安装目录
- 网络受限时不要硬试：把 URL 和目标落盘路径交给用户，等他下好再继续
- `autostart disable` 只删任务、不停已经在跑的进程，执行后要说明并给出 `cua-driver stop`
- 卸载、降级、回滚前先确认

## 排障

见 `references/troubleshooting.md`：pipe 连不上、Medium IL 与 UWP、浏览器 consent、输入被丢弃、snapshot token 失效。


