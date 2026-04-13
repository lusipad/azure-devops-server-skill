# Azure DevOps Server Skill

[![Validate](https://github.com/lusipad/azure-devops-server-skill/actions/workflows/validate.yml/badge.svg)](https://github.com/lusipad/azure-devops-server-skill/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

语言: [English](README.md) | [简体中文](README.zh-CN.md)

这是一个面向 Azure DevOps Server 2020/2022，并对较老 TFS 版本提供尽力支持的 Azure DevOps Server PowerShell 工具仓库。仓库内包含可复用的 REST 辅助脚本、可安装的技能包，以及围绕本地化 Azure DevOps 场景整理的参考文档，用来保证调用方式一致、先预览后写入，并清晰声明支持边界。

## 仓库提供的内容

- 位于 `azure-devops-server/` 下的可安装技能包
- 一个适用于 collection、project、team 范围的 Azure DevOps Server REST 包装器
- 一个用于鉴权、API 版本和条件域支持检测的连接自检脚本
- 面向仓库、工作项、构建、发布、Wiki、搜索、测试路由、URL 结构和 API 版本的参考文档
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
| `wiki` | 已支持 |
| `testplan` | 已支持 |
| `test` | 已支持 |
| `release` | 条件支持 |
| `search` | 条件支持 |
| `testresults` | 条件支持 |

目标支持策略：

- 一等支持：Azure DevOps Server 2020 和 2022
- 尽力支持：更老的 TFS / Azure DevOps Server 变体
- 暂缓支持：高级安全、MCP-app 集成以及其他云端专有域
- 必需输入：collection URL，以及 PAT 或 Windows 集成认证之一

## 仓库结构

```text
.
|-- azure-devops-server/
|   |-- SKILL.md
|   |-- agents/openai.yaml
|   |-- references/
|   |-- support-contract.json
|   `-- scripts/
|-- .github/
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
|-- README.zh-CN.md
|-- tests/
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
- `AZURE_DEVOPS_SERVER_SEARCH_BASE_URL`，可选，当搜索服务暴露在独立主机时使用
- `AZURE_DEVOPS_SERVER_TESTRESULTS_BASE_URL`，可选，当测试结果服务暴露在独立主机时使用

也支持以下 pipeline 风格的回退变量：

- `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI`
- `SYSTEM_TEAMPROJECT`

## 快速开始

先运行连接自检：

```powershell
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckSearchArea
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckTestResultsArea
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

其他已支持示例：

```powershell
pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area wiki `
  -Resource wikis

pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area build `
  -Project Fabrikam `
  -Resource definitions

pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 `
  -Project Fabrikam `
  -CheckReleaseArea

$body = @{
  searchText = "active bug"
  '$top' = 25
}

pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method POST `
  -Area search `
  -Project Fabrikam `
  -Resource workitemsearchresults `
  -Body $body `
  -AllowConditionalArea
```

## 安全模型

- 没有显式传入 `-AllowWrite` 时，写操作会被阻止。
- 对变更类命令，应该先用 `-DryRun` 做预览。
- `release` 路由属于条件支持，必须先探测通过后再正式使用。
- `search` 和 `testresults` 仍属于条件支持，因为部分部署会把它们暴露在独立主机或不同服务拓扑上。
- 只有显式白名单中的查询型 `POST` 才会绕过写入闸门。

## 参考文档索引

- [workflow-recipes.md](azure-devops-server/references/workflow-recipes.md)：常见任务模式
- [repo-support.md](azure-devops-server/references/repo-support.md)：仓库、分支与拉取请求
- [work-item-support.md](azure-devops-server/references/work-item-support.md)：工作项、WIQL、查询、评论与 JSON Patch 路由
- [work-support.md](azure-devops-server/references/work-support.md)：团队设置、迭代、待办事项与容量规划
- [build-support.md](azure-devops-server/references/build-support.md)：构建定义、构建记录、日志、产物与排队预览
- [release-support.md](azure-devops-server/references/release-support.md)：发布定义、发布记录、环境、部署与变更预览
- [wiki-support.md](azure-devops-server/references/wiki-support.md)：Wiki 列表与页面读取
- [search-support.md](azure-devops-server/references/search-support.md)：搜索路由与独立主机注意事项
- [test-support.md](azure-devops-server/references/test-support.md)：测试计划、套件、运行与运行结果
- [test-results-support.md](azure-devops-server/references/test-results-support.md)：按构建或工作项关联的测试结果路由
- [url-and-resource-areas.md](azure-devops-server/references/url-and-resource-areas.md)：collection URL 结构、作用域规则与 area 路由注意事项
- [auth-and-configuration.md](azure-devops-server/references/auth-and-configuration.md)：认证模式、环境变量与覆盖优先级
- [api-version-matrix.md](azure-devops-server/references/api-version-matrix.md)：服务器版本与 `api-version` 选择建议

## 开发与验证

本地验证示例：

```powershell
pwsh -File .\tests\Validate-AzureDevOpsServerSkill.ps1
```

可选的非生产 smoke harness：

```powershell
$env:AZURE_DEVOPS_SERVER_SMOKE = "1"
$env:AZURE_DEVOPS_SERVER_COLLECTION_URL = "https://ado-server/tfs/DefaultCollection"
$env:AZURE_DEVOPS_SERVER_AUTH_MODE = "default-credentials"
$env:AZURE_DEVOPS_SERVER_PROJECT = "Fabrikam"

pwsh -File .\tests\Smoke-AzureDevOpsServerSkill.ps1
```

如果没有设置这些显式启用变量，smoke harness 会输出 skip 信息并以成功状态退出。

这些检查也会在 GitHub Actions 的 push 和 pull request 流程中执行。

## 贡献

贡献方式见 [CONTRIBUTING.md](CONTRIBUTING.md)。保持改动小而明确，保留现有支持边界，并在脚本行为变化时同步更新文档。

## 安全

安全策略见 [SECURITY.md](SECURITY.md)。不要在公开 issue 中直接披露仍然有效的漏洞利用细节。

## 许可证

本项目基于 [MIT License](LICENSE) 发布。
