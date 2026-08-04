# Security Policy

ResQ is designed around one promise: **zero network requests after the model download.** Preserving this guarantee is a security matter.

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | ✅ |
| Older releases | ❌ |

## Reporting a Vulnerability

If you find a security issue — anything that could break the offline guarantee, leak data, or compromise the on-device processing model — **do not open a public issue.**

Please report it privately instead:

- Open a GitHub security advisory: https://github.com/THEJOHNCALEB/resq/security/advisories/new
- Or email the maintainers directly (see repository profile).

Please include:

1. A description of the issue and its impact
2. Steps to reproduce
3. Affected versions
4. Any suggested fix, if you have one

You'll receive a response within 5 business days. We'll work with you to confirm the issue, coordinate a fix, and give credit where appropriate.

## Security Considerations for Contributors

- **Never commit secrets.** `config.json` (Hugging Face token), model files (`*.litertlm`), and captured media (`*.m4a`) are gitignored. Do not force-add them.
- **No runtime network calls.** Adding any HTTP/HTTPS call (including font or analytics fetches) breaks the app's core privacy claim. The `PrivacyMonitor` will flag it — keep the counter at zero.
- **No user data in the repo.** Real medical profiles, emergency sessions, or facility data must never be committed. Only synthetic sample data is allowed.
