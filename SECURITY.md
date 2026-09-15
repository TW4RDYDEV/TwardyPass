# Security policy

## Supported version

Security fixes currently target the **1.1.x** release line. Support scope may change with future releases.

## Reporting a vulnerability

Contact **TW4RDYDEV / Filip Twardowski** through the project owner's GitHub profile
or use GitHub's private vulnerability-reporting feature if the owner has enabled it.
Do not assume a private reporting channel is configured.

Do not post exploit details or sensitive information in public issues before the
owner has had an opportunity to investigate. Include affected version, reproduction
steps with obvious dummy data, expected behavior and the observed impact. Coordinate
disclosure timing with the owner; no response-time guarantee is implied.

**Never submit real passwords, personal context, credentials, hash values, private
keys or unredacted screenshots.** Use clearly marked dummy inputs only.

## Privacy principles

- Local password analysis; no persistent password history or application logging of inputs.
- Manual-only, padded HTTPS HIBP range requests with only five hash-prefix characters.
- No telemetry, activation service, hardware fingerprinting or accounts.
- Reports explicitly allowlist safe fields and exclude plaintext, personal context and hashes.
- Clear sensitive session data and matching clipboard content via Ctrl+Shift+X or the UI.
- Ignore stale breach responses after input edits, clearing or offline mode.

Python and Qt cannot promise forensic erasure of all historical memory copies.
Operating-system swap and clipboard history are outside application control.
Third-party dependencies have their own security policies and licenses.
