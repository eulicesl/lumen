# Security Policy

## Supported versions
Lumen is currently an early-stage private product. Security fixes should target the latest active `main` branch unless a release branch is explicitly maintained.

## Reporting a vulnerability
Do not open public issues for security-sensitive findings.

Report privately to the repository owner with:
- summary of the issue
- impact
- reproduction details
- suggested mitigation if known

## Secure engineering rules
- Never commit secrets, tokens, or signing artifacts.
- Treat accidental secret exposure as real exposure and rotate immediately.
- Review privacy permissions text and data handling changes carefully in every PR.
- Prefer least-privilege access for any new integration.
