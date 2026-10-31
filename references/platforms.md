# 平台安装与卸载

## Windows

官方一行（不推荐盲跑）：

```
irm https://cua.ai/driver/install.ps1 | iex
```

推荐做法——先落盘，看过再执行：

```
irm https://cua.ai/driver/install.ps1 -OutFile install-cua.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install-cua.ps1 -NoAutoStart
```

常用参数：

| 参数 | 作用 |
| --- | --- |
| `-NoAutoStart` | 不注册登录自启（优先用这个，除非用户明确要自启） |
| `-AutoStart` | 显式注册自启，会弹一次 UAC |
| `-NoPathUpdate` | 不往 User PATH 追加 bin 目录 |
| `-RequireSignature` | 要求 cosign 验证 Sigstore bundle，需本机有 cosign |

环境变量：`CUA_DRIVER_RS_VERSION`（钉版本）、`CUA_DRIVER_RS_HOME`（包目录）、`CUA_DRIVER_RS_INSTALL_DIR`（PATH 入口目录）、`CUA_DRIVER_RS_KEEP_VERSIONS`（保留几个旧版本，默认 5）。

磁盘布局（不要手工改）：

```
%LOCALAPPDATA%\Programs\Cua\cua-driver\bin      -> junction 到 packages\current
%USERPROFILE%\.cua-driver\packages\current      -> junction 到具体 release
%USERPROFILE%\.cua-driver\packages\releases\<version>-x86_64-pc-windows-msvc\
```

### GitHub 不通时的补救

安装器只有一段下载逻辑：只要目标 release 目录里已经有 `cua-driver.exe`，它就会打印 `already on disk (skipping download)`，把 zip、SHA256SUMS、sigstore 全部跳过。

所以：让用户下好 `cua-driver-rs-<ver>-windows-x86_64.zip`，解压后把里面的内容（`cua-driver.exe`、`cua-cursor-theme.exe`、DLL、LICENSE 等）整体拷到

```
%USERPROFILE%\.cua-driver\packages\releases\<ver>-x86_64-pc-windows-msvc\
```

再跑安装器。`cua-cursor-theme.exe` 不能少，0.12.7+ 缺失会直接报错。

### 自启

`autostart enable / disable / status / kick`。任务名 `cua-driver-serve`，`RunLevel=Highest`，全机共享。`disable` 需要管理员，会弹 UAC；它只删任务，不会停已经在跑的 daemon，需要的话再 `cua-driver stop`。

### 卸载

```
cua-driver autostart disable      # 管理员
cua-driver stop
```

然后删 `%USERPROFILE%\.cua-driver`、`%LOCALAPPDATA%\Programs\Cua`，并从 User PATH 移除 bin 目录。删之前确认用户同意。

## macOS

```
curl -fsSL https://cua.ai/driver/install.sh -o install-cua.sh
bash install-cua.sh
cua-driver permissions grant
```

参数：`--bin-dir <path>`（默认 `~/.local/bin`）、`--no-modify-path`、`--channel stable|nightly`、`--require-signature`。对应环境变量：`CUA_DRIVER_BIN_DIR`、`CUA_DRIVER_NO_MODIFY_PATH`、`CUA_DRIVER_RS_VERSION`、`CUA_DRIVER_RS_HOME`。

权限模型和 Windows 完全不同：

- `cua-driver permissions grant` 会以 app 身份弹出辅助功能与屏幕录制授权，**必须在真实登录的桌面会话里由用户点同意**，不能静默完成。
- `cua-driver permissions status` 只读，无 daemon 时返回 `unknown`，不要把它当成"没授权"。
- `autostart` 子命令当前不适用 macOS（官方标注 Windows-only today），不要自己造 LaunchAgent。
- `mcp --direct` 在 macOS 上意味着由宿主进程承担 TCC 归属；不确定时用默认路径（连 daemon）。

卸载：

```
curl -fsSL https://cua.ai/driver/uninstall.sh | bash
```

## Linux

同一份 `install.sh`，但输入与捕获依赖 X11/Wayland portal，能力差异较大。本 Skill 未覆盖，遇到时先 `cua-driver doctor` 看 `features` 字段再判断。
