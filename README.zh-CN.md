# Azure DevOps Server Skill

[![Validate](https://github.com/lusipad/azure-devops-server-skill/actions/workflows/validate.yml/badge.svg)](https://github.com/lusipad/azure-devops-server-skill/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

语言: [English](README.md) | [简体中文](README.zh-CN.md)

这是一个面向 Azure DevOps Server 2020/2022，并对较老 TFS 版本提供尽力支持的 Azure DevOps Server PowerShell 工具仓库。仓库内包含可复用的 REST 辅助脚本、可安装的技能包，以及围绕本地化 Azure DevOps 场景整理的参考文档，用来保证调用方式一致、先预览后写入，并清晰声明支持边界。

## 仓库提供的内容

- 位于 `azure-devops-server/` 下的可安装技能包
- 一个适用于 collection、project、team 范围的 Azure DevOps Server REST 包装器
- 一个用于鉴权、API 版本和条件性 release 支持检测的连接自检脚本
- 面向仓库、工作项、work/team 路由、URL 结构和 API 版本的参考文档
- 用于技能注册的 agent 元数据

## 支持范围

这个仓库有意比 Azure DevOps Services 工具链更窄，只覆盖 Azure DevOps Server / TFS 的明确能力范围。

| 区域 | 支持状态 |
| --- | --- |
| `core` / projects | 必需支持 |
| `git` | 必需支持 |
| `wit` | 必需支持 |
| `build` | 必需支持 |
| `work` | 必需支持 |
| `release` | 条件支持 |
| `wiki`、`search`、`test`、`testresults` | 暂缓支持 |

目标支持策略：

- 一等支持：Azure DevOps Server 2020 和 2022
- 尽力支持：更老的 TFS / Azure DevOps Server 变体
- 必需输入：collection URL，以及 PAT 或 Windows 集成认证之一

## 仓库结构

```text
.
|-- azure-devops-server/
|   |-- SKILL.md
|   |-- agents/openai.yaml
|   |-- references/
|   `-- scripts/
|-- .github/
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
|-- README.zh-CN.md
`-- SECURITY.md
```

## 环境要求

- PowerShell 7+
- 能访问目标 Azure DevOps Server collection 的网络环境
- 以下认证方式之一：
  - 通过 `default-credentials` 使用 Windows 集成认证
  - 通过 `pat` 使用个人访问令牌
- 一个本地 skills 目录，用于将内置技能包安装到代理环境中

## 认证方式

这个工具同时支持 Windows 集成认证和 PAT 认证。

- `default-credentials`
  在已经具备目标 Azure DevOps Server 访问权限的 Windows 主机上优先推荐。脚本会直接使用当前 Windows 身份；如果没有显式设置 `AZURE_DEVOPS_SERVER_AUTH_MODE`，默认也会走这个模式。
- `pat`
  当集成认证不可用，或者自动化场景需要显式令牌时使用。

Windows 集成认证示例：

```powershell
$env:AZURE_DEVOPS_SERVER_COLLECTION_URL = "https://ado-server/tfs/DefaultCollection"
$env:AZURE_DEVOPS_SERVER_AUTH_MODE = "default-credentials"

pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1
```

PAT 示例：

```powershell
$env:AZURE_DEVOPS_SERVER_COLLECTION_URL = "https://ado-server/tfs/DefaultCollection"
$env:AZURE_DEVOPS_SERVER_AUTH_MODE = "pat"
$env:AZURE_DEVOPS_SERVER_PAT = "<token>"

pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1
```

更完整的认证说明见 [auth-and-configuration.md](azure-devops-server/references/auth-and-configuration.md)。

## 安装

克隆仓库后，将 `azure-devops-server/` 目录复制到你的本地 skills 目录中。

Windows 示例：

```powershell
git clone https://github.com/lusipad/azure-devops-server-skill.git
Copy-Item -Recurse -Force `
  .\azure-devops-server-skill\azure-devops-server `
  "$env:USERPROFILE\.codex\skills\azure-devops-server"
```

如果你的环境使用的是其他 skills 目录，改成对应路径即可。仓库根目录主要用于 GitHub 托管，真正的技能包是内层的 `azure-devops-server/` 目录。

## 配置

优先使用以下环境变量：

- `AZURE_DEVOPS_SERVER_COLLECTION_URL`
- `AZURE_DEVOPS_SERVER_AUTH_MODE`，取值为 `pat` 或 `default-credentials`，默认是 `default-credentials`
- `AZURE_DEVOPS_SERVER_PAT`，当认证模式为 `pat` 时必需
- `AZURE_DEVOPS_SERVER_PROJECT`，可选，默认项目
- `AZURE_DEVOPS_SERVER_TEAM`，可选，默认团队
- `AZURE_DEVOPS_SERVER_API_VERSION`，可选，显式覆盖 API 版本
- `AZURE_DEVOPS_SERVER_SERVER_VERSION`，可选，服务器提示值：`2022`、`2020`、`2019`、`2018`、`2017`、`2015` 或 `legacy`

也支持以下 pipeline 风格的回退变量：

- `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI`
- `SYSTEM_TEAMPROJECT`

## 快速开始

先运行连接自检：

```powershell
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea -DryRun
```

再通过通用包装脚本读取支持区域的数据：

```powershell
pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Resource projects `
  -Query @{ '$top' = 25 }

pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area git `
  -Project Fabrikam `
  -Resource repositories
```

## 安全模型

- 没有显式传入 `-AllowWrite` 时，写操作会被阻止。
- 对变更类命令，应该先用 `-DryRun` 做预览。
- `release` 路由属于条件支持，必须先探测通过后再正式使用。
- 暂缓支持的区域会明确失败，不会伪装成 Azure DevOps Services 兼容。
- 某些 `POST` 会被视为安全只读调用，例如 WIQL 查询。

## 开发与验证

本地验证示例：

```powershell
$files = @(
  "azure-devops-server/scripts/AzureDevOpsServer.psm1",
  "azure-devops-server/scripts/Invoke-AzureDevOpsServerApi.ps1",
  "azure-devops-server/scripts/Test-AzureDevOpsServerConnection.ps1"
)

foreach ($file in $files) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $file), [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "Parse errors in $file"
  }
}

Import-Module .\azure-devops-server\scripts\AzureDevOpsServer.psm1 -Force
Get-AzureDevOpsServerSupportMatrix
```

这些检查也会在 GitHub Actions 的 push 和 pull request 流程中执行。

## 贡献

贡献方式见 [CONTRIBUTING.md](CONTRIBUTING.md)。保持改动小而明确，保留现有支持边界，并在脚本行为变化时同步更新文档。

## 安全

安全策略见 [SECURITY.md](SECURITY.md)。不要在公开 issue 中直接披露仍然有效的漏洞利用细节。

## 许可证

本项目基于 [MIT License](LICENSE) 发布。
