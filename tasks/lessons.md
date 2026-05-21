# Lessons

## Version Bump Precision

- Failure mode: Interpreted "increment minor version number" as a semantic-version minor bump from `0.2.0` to `0.3.0` when the intended release bump was patch-level `0.2.1`.
- Detection signal: User correction clarified "increment patch level, so 0.2.1."
- Prevention rule: When a requested version bump conflicts with an explicitly supplied target version, use the explicit target version. For ambiguous release bumps, confirm the exact target before editing release metadata.
