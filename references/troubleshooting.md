# 排障

## daemon 没在跑 / pipe 连不上

`<exe> status` 报 not running。两种合法形态：

- 按需：什么都不用做，客户端拉起 `cua-driver mcp` 时运行时在进程内部，客户端断开即结束
- 常驻：`Start-Process "<exe>" -ArgumentList "serve" -WindowStyle Hidden`（Windows）或 `<exe> serve`，之后所有客户端共用 `\\.\pipe\cua-driver`；关掉用 `<exe> stop`

`cua-driver call` 需要的是常驻 daemon，没有就报错，别误判成安装失败。

## UWP / 商店应用的 UIA 树只有一个元素

调用方是 Medium IL。需要 High IL 的常驻 daemon：Windows 上用 `RunLevel=Highest` 的计划任务（`autostart enable`）或从管理员 shell 起 `serve`。计算器、设置、照片这类 AppContainer 应用在 Medium IL 下跨容器 UIA RPC 会被截断。

传统 Win32、Chrome/Edge、Office、资源管理器不受影响。

## browser_consent_required

接管用户已登录的浏览器配置需要授权：`cua-driver serve --grant existing-profile`，或由嵌入宿主授权。拿不到就退回 UIA 原生驱动（`get_window_state` + PostMessage 点击），功能可用但输入可能回退前台。

## browser_binding_stale

Chrome 换窗口会换进程，旧 `pid`/`window_id` 失效。重新 `list_windows` → `get_browser_state` 拿新的 `target_id`/`tab_id`。别复用上一轮的绑定。

## 输入没生效 / 提示 delivery_mode:foreground

Chromium 渲染进程会丢弃 PostMessage 投递的字符与回车，驱动自动回退 SendInput，这会短暂抢占前台焦点。批量操作时要么接受，要么改走浏览器工具（CDP），要么事先告知用户。

## element token 失效（went stale）

窗口重绘后 `snapshot_id:N` 会失效。驱动通常会自动按 role+name 重定位（返回里带 `refound`），失败就重新 `get_window_state` 取新快照。不要跨快照复用 token。

## 计划任务删不掉：Access is denied

`cua-driver-serve` 是 `RunLevel=Highest`，删除/注册都需要管理员。用提权 shell 执行 `autostart disable`，会弹一次 UAC。

## 安装器卡在下载 .sigstore.json

网络问题，GitHub 直连不稳定。走 `references/platforms.md` 的离线补救：预置 release 目录后重跑，安装器会跳过整个下载与校验分支。

## macOS 权限反复弹

`permissions grant` 必须以 app 身份触发，管道里跑 `permissions status` 只会返回 `unknown`。让用户在真实桌面会话点同意，别反复重试命令。

## doctor 显示没有交互桌面

进程跑在服务、Session 0 或非交互会话里，拿不到桌面和 UIA。必须在用户登录的交互会话中运行。
