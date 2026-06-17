# Contributing to Pill Reminder

Thank you for your interest in contributing! This document outlines how to contribute to the project.

## Code of Conduct

Be respectful, inclusive, and constructive. We welcome contributions from people of all backgrounds and experience levels.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork locally:**
   ```bash
   git clone https://github.com/your-username/pillremindermontypythonstyle.git
   ```
3. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Set up development environment** per [DEVELOPMENT.md](DEVELOPMENT.md)

## Development Workflow

### Before You Start
- Check [open issues](https://github.com/your-username/pillremindermontypythonstyle/issues) to avoid duplicate work
- Create an issue to discuss major features before coding
- Assign yourself to show others you're working on it

### Code Standards

**Swift (iOS/macOS):**
- Follow [Google Swift Style Guide](https://google.github.io/swift-style-guide/)
- Use meaningful variable/function names
- Add MARK comments for file organization:
  ```swift
  // MARK: - Public Methods
  // MARK: - Private Methods
  // MARK: - Helpers
  ```
- Minimum 80% test coverage for new code

**C# (Windows):**
- Follow [C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- PascalCase for classes, methods, properties
- camelCase for local variables

**Python (Linux):**
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints where helpful
- Docstrings for public functions

### Testing

**All new features must include tests:**

```swift
// Example: ReminderTests.swift
import XCTest
@testable import PillReminder

class ReminderTests: XCTestCase {
    func testReminderInitialization() {
        let reminder = Reminder(
            id: UUID(),
            enabled: true,
            time: "09:00",
            maladyType: "Parkinsons"
        )
        XCTAssertTrue(reminder.enabled)
        XCTAssertEqual(reminder.maladyType, "Parkinsons")
    }
}
```

Run tests before submitting:
```bash
xcodebuild test
```

### Pull Request Process

1. **Commit with clear messages:**
   ```bash
   git commit -m "Feature: Brief description of what changed"
   # Bad: "fixed stuff"
   # Good: "Add voice rate control to reminder settings"
   ```

2. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request:**
   - Use descriptive title (matches commit message)
   - In description, explain:
     - What problem does this solve?
     - How does it work?
     - Any breaking changes?
   - Link related issues: "Closes #123"
   - Include screenshots for UI changes

4. **Respond to code review:**
   - Reviewers may suggest changes
   - Make requested changes in new commits (don't force-push)
   - Re-request review when ready

5. **Merge criteria:**
   - ✅ All tests pass
   - ✅ Code review approved
   - ✅ No conflicts with main branch
   - ✅ Documentation updated (if needed)

## What We're Looking For

### Highly Appreciated
- Bug fixes with test cases
- UI/UX improvements
- Documentation improvements
- Accessibility enhancements
- Performance optimizations

### Feature Ideas
See the GitHub Issues for the roadmap. Popular areas:
- Additional voice options
- Dark mode
- Multiple reminder profiles
- Export/import reminders
- Localization (other languages)
- Calendar integration

### Monty Python Content
- New jokes/quotes for voice alerts
- Audio clips (must be original or properly licensed, no copyrighted content)
- Themed graphics

## Reporting Bugs

1. **Check if already reported:** Search [existing issues](https://github.com/your-username/pillremindermontypythonstyle/issues)
2. **Create detailed bug report:**
   ```
   **Environment:**
   - iOS version: 16.0
   - App version: 1.0.0
   - Device: iPhone 14
   
   **Steps to Reproduce:**
   1. Open app
   2. Add a reminder
   3. Set time to 9:00 AM
   4. Close and reopen app
   
   **Expected:** Reminder is still there
   **Actual:** Reminder disappeared
   
   **Screenshot/Log:**
   [Attach if helpful]
   ```

## Documentation

Help improve:
- README.md - Project overview
- ARCHITECTURE.md - System design
- DEVELOPMENT.md - Setup and debugging
- Code comments - Explain "why", not "what"
- Docstrings - Document public APIs

## Licensing

By contributing, you agree your code is licensed under the project's LICENSE (see [LICENSE](../LICENSE)).

## Questions?

- Open an issue with "question:" prefix
- Discuss in GitHub Discussions (if enabled)
- Email project maintainer

---

Thank you for contributing! 🎭🎤
