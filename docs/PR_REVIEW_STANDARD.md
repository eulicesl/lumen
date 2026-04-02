# PR Review Standard

Every Lumen PR should be reviewed like a product PR, not a casual code dump.

## Reviewer checklist
- Scope is tight and understandable
- Validation is explicit, not implied
- UI changes include screenshots or video
- UI changes include a note of what was visually checked on the branch under review
- Risk is called out honestly
- Follow-up work is separated from must-fix work
- Apple/platform correctness has been considered
- No unresolved critical comments remain before merge

## Apple-level review prompts
- Does this use APIs valid for the deployment target?
- Are new platform features gated correctly?
- Does SwiftUI behave correctly across likely device/runtime variants?
- Are permission prompts and privacy descriptions accurate?
- Are widget/extension/app target relationships still sane?

## Merge bar
A PR is ready only when:
- CI is green
- required review is present
- discussion is resolved
- release risk is acceptable
