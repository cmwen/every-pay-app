# Copilot Agents Guide — EveryPay

This document describes the AI agents and skills available for developing the **EveryPay** Flutter app (`org.cmwen.everypay`).

## Project Overview

| Field | Value |
|-------|-------|
| **App name** | EveryPay |
| **Package** | `org.cmwen.everypay` |
| **Framework** | Flutter 3.x / Dart ^3.10.1 |
| **Platform** | Android (primary) |
| **State management** | Riverpod (`flutter_riverpod`) |
| **Navigation** | `go_router` |
| **Local DB** | `sqflite` |
| **HTTP** | `http` |
| **Testing** | `flutter_test`, `mocktail` |

---

## Agents

Agents are defined in `.github/agents/` and are invoked with `@agent-name` in Copilot Chat.

### `@product-owner`
Defines features, user stories, and acceptance criteria.

**Use for**: Writing requirements docs, scoping MVPs, defining success metrics.

```
@product-owner Create user stories and acceptance criteria for [FEATURE].
Include MVP scope and save to docs/REQUIREMENTS_[FEATURE].md
```

---

### `@experience-designer`
Designs UX flows, wireframes, and Material Design 3 patterns.

**Use for**: User flows, screen layouts, interaction design.

```
@experience-designer Based on docs/REQUIREMENTS_[FEATURE].md, design the user
flow and wireframes for [FEATURE]. Save to docs/UX_DESIGN_[FEATURE].md
```

---

### `@architect`
Plans architecture, data models, and technical decisions.

**Use for**: Folder structure, repository patterns, state management design.

```
@architect Design the architecture for [FEATURE] including data models,
repositories, providers, and folder structure following project conventions.
Save to docs/ARCHITECTURE_[FEATURE].md
```

---

### `@researcher`
Researches packages, best practices, and compares solutions.

**Use for**: Evaluating pub.dev packages, benchmarking approaches.

```
@researcher What's the best package for [FUNCTIONALITY]?
Compare options and recommend. Save to docs/DEPENDENCIES_[FEATURE].md
```

---

### `@flutter-developer`
Implements features, writes tests, fixes bugs, and runs builds.

**Use for**: All Dart/Flutter implementation work.

```
@flutter-developer Implement [FEATURE] following docs/ARCHITECTURE_[FEATURE].md
- Add models in lib/domain/entities/
- Add repositories in lib/data/repositories/
- Add providers in lib/features/[feature]/providers/
- Add screens in lib/features/[feature]/screens/
- Write widget tests
- Run flutter test and flutter analyze
```

**Handoffs available**:
- *Test Implementation* — hands off to agent to write tests
- *Document Code* — hands off to `@doc-writer`
- *Design Review* — hands off to `@experience-designer`

---

### `@doc-writer`
Creates documentation, guides, and in-code comments.

**Use for**: API docs, user guides, README updates.

```
@doc-writer Document [FEATURE] with usage examples and save to
docs/FEATURE_[NAME]_GUIDE.md
```

---

## Skills

Skills are in `.github/skills/` and are automatically discovered by Copilot.

| Skill | Path | Purpose |
|-------|------|---------|
| `icon-generation` | `.github/skills/icon-generation/` | Generate app icons and launcher assets |
| `android-debug` | `.github/skills/android-debug/` | Debug Android crashes, device issues, performance |
| `build-fix` | `.github/skills/build-fix/` | Fix Gradle errors, dependency conflicts, build failures |
| `ci-debug` | `.github/skills/ci-debug/` | Debug GitHub Actions workflow failures |
| `ollama-integration` | `.github/skills/ollama-integration/` | Integrate local Ollama LLM into the app |

---

## Project Structure

```
lib/
├── main.dart               # Entry point
├── app.dart                # App widget / theme
├── router.dart             # go_router configuration
├── core/
│   ├── constants/          # App-wide constants
│   ├── extensions/         # Dart extension methods
│   ├── services/           # App-level services
│   ├── theme/              # Material 3 theme
│   └── utils/              # Helpers
├── data/
│   ├── database/           # sqflite setup & migrations
│   ├── mappers/            # Entity ↔ model mapping
│   ├── repositories/       # Repository implementations
│   └── templates/          # Seed / template data
├── domain/
│   ├── entities/           # Pure data models
│   ├── enums/              # Shared enumerations
│   └── repositories/       # Repository interfaces
├── features/
│   ├── expense/            # Expense entry & management
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── home/               # Dashboard / overview
│   ├── settings/           # App settings
│   ├── stats/              # Analytics & charts
│   └── sync/               # Data sync
├── services/               # Cross-feature services
└── shared/                 # Shared widgets & utilities
```

---

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build.yml` | Push to `main`/`develop`, PRs | Build APK + AAB, run tests, auto-format |
| `release.yml` | Tag `v*` | Signed release build + GitHub Release |
| `pre-release.yml` | Manual dispatch | Beta/alpha builds |
| `codeql.yml` | Push / schedule | Security analysis |
| `deploy-website.yml` | Push to `main` | Deploy web build |

**Secrets required for signed releases:**

```
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

---

## Common Commands

```bash
flutter pub get           # Install dependencies
flutter test              # Run all tests
flutter analyze           # Lint / static analysis
dart fix --apply          # Auto-fix lint issues
dart format .             # Format code
flutter build apk         # Debug APK
flutter build apk --release  # Release APK
flutter build appbundle   # Play Store bundle
flutter clean             # Clear build cache
```

---

## Multi-Agent Workflow: New Feature

1. **`@product-owner`** — define requirements → `docs/REQUIREMENTS_[FEATURE].md`
2. **`@experience-designer`** — design UX → `docs/UX_DESIGN_[FEATURE].md`
3. **`@researcher`** — evaluate packages → `docs/DEPENDENCIES_[FEATURE].md`
4. **`@architect`** — plan architecture → `docs/ARCHITECTURE_[FEATURE].md`
5. **`@flutter-developer`** — implement, test, analyze
6. **`@doc-writer`** — write documentation

---

## Key Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies and app metadata |
| `lib/main.dart` | Entry point |
| `lib/router.dart` | All app routes |
| `lib/app.dart` | MaterialApp / theme setup |
| `android/app/build.gradle.kts` | Android build config |
| `android/app/src/main/AndroidManifest.xml` | Android manifest |
| `analysis_options.yaml` | Lint rules |
