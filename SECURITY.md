# Security Policy

## Supported Versions

Security fixes are applied on a best-effort basis to the default branch.

| Version | Supported |
| --- | --- |
| `main` | Yes |
| Older commits or forks | No |

## Reporting a Vulnerability

Do not post exploit details in public issues.

Preferred path:

1. Use GitHub's private vulnerability reporting for this repository if it is enabled.
2. If private reporting is unavailable, contact the repository owner through GitHub and share only minimal reproduction details until a private channel is established.

Please include:

- Affected file or command path
- Target area such as `git`, `wit`, `work`, or `release`
- Whether the issue affects read routes, write safety, auth handling, or data exposure
- Reproduction steps
- Expected and actual behavior
- Any proof-of-concept payloads, sanitized as needed

## Security Boundaries

This repository already enforces a few safety boundaries that should not be bypassed casually:

- Live writes require explicit `-AllowWrite`
- Mutations are designed for `-DryRun` preview-first workflows
- Conditional `release` support requires an explicit probe
- Deferred areas should fail clearly instead of silently guessing

Security changes should preserve or strengthen those boundaries.
