# 各客户端注册写法

先跑 `<exe> mcp-config --client <name>` 拿官方输出，下面是实测样例与需要留心的地方。

## 注意：反斜杠

`mcp-config` 打印的 JSON 里，`command` 的 Windows 路径是单反斜杠，直接贴进 JSON 文件会解析失败。写文件时用正斜杠或双反斜杠：

```
"command": "C:/Users/me/AppData/Local/Programs/Cua/cua-driver/bin/cua-driver.exe"
```

## Codex

```
codex mcp add cua-driver -- "<exe>" mcp
```

写入 `~/.codex/config.toml`：

```
[mcp_servers.cua-driver]
command = '<exe>'
args = ["mcp"]
```

Codex 在启动时拉起 MCP 子进程，注册后需要新会话才生效。

## Claude Code

```
claude mcp add-json --scope user cua-computer-use '{\"args\":[\"mcp\"],\"command\":\"C:/Users/me/.../cua-driver.exe\"}'
```

## Cursor / 通用 mcpServers

```json
{
  "mcpServers": {
    "cua-driver": {
      "command": "C:/Users/me/AppData/Local/Programs/Cua/cua-driver/bin/cua-driver.exe",
      "args": ["mcp"],
      "type": "stdio"
    }
  }
}
```

## Qwen

```
qwen mcp add cua-driver C:\Users\me\AppData\Local\Programs\Cua\cua-driver\bin\cua-driver.exe mcp
```

## 其他

`antigravity`、`openclaw`、`opencode`、`hermes`、`pi`、`prime-agent`、`droid`、`zcode` 都支持 `<exe> mcp-config --client <name>`；带 `--client` 时默认还会装技能包，不想装加 `--no-skills`。

## 自研 agent

只需要三件事：

1. 拉起子进程：`command = manifest.mcp_invocation.command`，`args = ["mcp"]`
2. 建立 stdio JSON-RPC：一行一个 JSON，响应按 `id` 匹配（可能乱序）
3. 手写客户端时注意：必须持续消费 stderr 否则管道会满；`notifications/initialized` 无 id 不需要等响应；stdout 只允许 JSON-RPC

握手顺序：`initialize` → `notifications/initialized` → `tools/list` → `tools/call`。

`initialize` 返回的 `instructions` 是官方使用手册，应当注入 system prompt；`tools/list` 的 `inputSchema` 直接转成模型侧 function schema。

如果 agent 跑在 WSL、容器或另一台机器，stdio 方案不成立——它连的是本机进程和本机桌面会话。
