# Support

## Before opening an issue

- Read [README.md](README.md), [README.zh-CN.md](README.zh-CN.md), and the bundled reference guides for the area you are using.
- Run `pwsh -File .\tests\Validate-AzureDevOpsServerSkill.ps1` if you changed the repository locally.
- If you are reporting a live-server problem, capture the server version, auth mode, sanitized command, and expected versus actual behavior.
- Remove secrets, PATs, cookies, internal hostnames, and private collection URLs from any logs you share.

## Use the right channel

- Usage or installation questions: start with the READMEs and the reference docs, then open a GitHub issue if the docs are unclear or incorrect.
- Bug reports: use the `Bug report` template and include a minimal sanitized reproduction.
- Feature requests: use the `Feature request` template and describe the target area, server assumptions, and alternatives considered.
- Security issues: follow [SECURITY.md](SECURITY.md) and use a private reporting path instead of a public issue.

## What to include

- Azure DevOps Server or TFS version, if known
- Auth mode: `default-credentials` or `pat`
- The exact script or workflow step you ran, sanitized
- Whether the failure affects a required, supported, or conditional area
- Dry-run output, stack trace excerpt, or probe result when available

## Support boundaries

- This repository targets Azure DevOps Server and on-prem TFS workflows, not full Azure DevOps Services parity.
- Conditional areas such as `release`, `search`, and `testresults` may need extra topology checks or dedicated hosts before they work in a given deployment.
- Deferred cloud-only domains should fail clearly rather than being approximated.
