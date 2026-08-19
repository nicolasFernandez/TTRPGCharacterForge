# TTRPGCharacterForge

A free, source-available Swift application for non-commercial use, for creating and managing characters compatible with the 2014 fifth edition ruleset for Dungeons & Dragons.

This project is unofficial Fan Content permitted under the [Fan Content Policy](https://company.wizards.com/en/legal/fancontentpolicy). Not approved/endorsed by Wizards. Portions of the materials used are property of Wizards of the Coast. ©Wizards of the Coast LLC.

This project includes material from the [System Reference Document 5.1](https://www.dndbeyond.com/srd#SystemReferenceDocumentv51) by Wizards of the Coast LLC, available [here](https://www.dndbeyond.com/srd#SystemReferenceDocumentv51) and licensed for use under the Creative Commons Attribution 4.0 International License.

## Security

For information about our security policy, including how to report vulnerabilities and our approach to security alerts, please see [SECURITY.md](SECURITY.md).

### Git Hooks for Sensitive Information

This project uses git hooks to automatically sanitize sensitive information before commits:

1. **pre-commit hook**: Automatically replaces the actual bundle identifiers with placeholder values before committing
2. **post-checkout hook**: Restores the actual bundle identifiers after checkout for local development

#### Setup

To use these hooks, make sure they are executable:

```bash
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/post-checkout
```

#### How it works

- When you commit changes, the pre-commit hook will sanitize the project.pbxproj file
- After checkout/pull, the post-checkout hook will restore your actual development identifiers
- This ensures development team and bundle identifiers remain private

## Development

- Follow SOLID and Clean Code principles.
- Apply Design Patterns as needed following [Refactoring Guru](https://refactoring.guru/design-patterns) guidelines.
- Use SwiftUI instead of UIKit.
- The v1 application targets iOS and iPadOS 17 and is distributed as one universal app.
- Domain and SRD rule code must remain independent of SwiftUI/UIKit so later tvOS, visionOS, and watchOS presentation targets can reuse it.
- V1 is local-only and must remain fully usable without a network connection.

## V1 scope

- [ ] Define a guided level-1 character document and validation engine for SRD 5.1.
- [ ] Support standard array, 27-point buy, and rolled 4d6-drop-lowest ability methods.
- [ ] Autosave character drafts and completed characters locally with SwiftData.
- [ ] Load the spell browser from bundled, versioned rule catalogs.
- [ ] Import a local portrait and include portrait metadata in the character document.
- [ ] Export an original printable PDF and transparent circular PNG VTT token.
- [ ] Complete human review of every English and Spanish catalog entry against the bundled SRD source documents.
- [ ] Finish phone and tablet UI automation and PDF snapshot coverage using full Xcode.

## Post-v1 roadmap

- Character advancement through levels 2–20 and multiclassing.
- Optional cloud synchronization and versioned backup import/export.
- Optional user-funded AI portrait providers; v1 contains no AI, API keys, authentication, or network integration.
- Additional TTRPG systems such as Pathfinder, Vampire: The Masquerade, and Call of Cthulhu, subject to their individual licenses.

> **Note:** Adding support for other TTRPG systems (such as Pathfinder, Vampire: The Masquerade, Call of Cthulhu, etc.) may require additional licensing considerations beyond the D&D Fan Content Policy. Please review and comply with the licensing requirements of each game system and publisher before implementing or distributing support for their content.
