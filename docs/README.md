# ClodForest

> *"Till Birnam wood remove to Dunsinane, I cannot taint with fear."* - Macbeth
>
> Just as the prophecy in Macbeth came true when soldiers carried branches from Birnam Wood to Dunsinane Castle, ClodForest brings the impossible to life by carrying entire forests of context to Claude sessions. What seemed like an immutable limitation - that contexts couldn't move between sessions - has been overcome through creative engineering.

## Tools for giving Claude.ai a means of extending itself almost arbitrarily

ClodForest is a production-ready context management system that enables Claude sessions to inherit, compose, and preserve complex contextual knowledge across instances. It transforms how AI assistants maintain continuity, relationships, and specialized knowledge.

## Current Status (June 2025)

- **Production URL**: https://clodforest.thatsnice.org
- **Status**: ✅ Operational with 8+ days uptime
- **Recent Achievement**: Cache busting implementation solved aggressive CDN caching
- **Next Focus**: Enhanced session handoff with emotional context preservation

## Core Features

### Context Inheritance System
- **Modular contexts**: Core → Domain → Project hierarchy
- **Dynamic loading**: Load only what's needed for each session
- **Cultural preservation**: Maintains collaboration patterns and linguistic traditions
- **Session handoffs**: Comprehensive time capsules for continuity

### API Architecture
```
Base URL: https://clodforest.thatsnice.org
Key Endpoints:
  /api/health/               - Service health check
  /api/time/                 - Time synchronization
  /api/repo/                 - Repository browsing
  /api/bustit/{unique}/...   - Cache-busted access
```

## Usage

### For Claude.ai Users

Add this to your Claude preferences to enable ClodForest bootstrapping:

```
If I ask you to bootstrap yourself, fetch https://raw.githubusercontent.com/rdeforest/ClodForest/refs/heads/main/state/instructions/bootstrap.yaml for further instructions.
```

### Quick Start

1. **Bootstrap a session**: "Please bootstrap yourself"
2. **Load specific context**: "Load the general-development context"
3. **Request cache-busted content**:
   ```
   Please fetch:
   https://clodforest.thatsnice.org/api/bustit/[unique]/repo/contexts/core/robert-identity.yaml
   ```

## Architecture

### Context Structure
```
ClodForest/state/contexts/
├── core/                    # Foundation contexts
│   ├── robert-identity.yaml
│   ├── collaboration-patterns.yaml
│   └── communication-style.yaml
├── domains/                 # Domain-specific contexts
│   ├── personal-assistant.yaml
│   ├── general-development.yaml
│   └── clodforest-development.yaml
└── projects/               # Project-specific contexts
    ├── agent-calico/
    └── local-llm-migration/
```

### Integration Ecosystem
- **ClodHearth**: Local LLM fine-tuning
- **ClodRiver**: Real-time LLM virtual world integration
- **ClodGraph**: (Planned) Graph database for relationships

## Recent Improvements

### Cache Busting (June 2025)
- Implemented `/api/bustit/{unique}/` prefix system
- Enables dynamic content access despite aggressive CDN caching
- Validates with health and time endpoints

### Bootstrap Refinement
- Extracted CLaSH interface to optional extension
- Prevents safety mechanism triggers
- Stable session loading without interface complexity

## Known Limitations

### Active Development Areas
1. **Session Handoff Quality**: Technical facts preserved but emotional context lost
2. **Manual URL Construction**: Claude cannot generate cache-busted URLs
3. **ClaudeLink Protocol**: Multi-instance coordination not yet implemented

## Contributing

ClodForest is actively developed with a focus on:
- Context preservation and inheritance
- Session continuity optimization
- Multi-instance coordination protocols

## Philosophy

Like Birnam Wood coming to Dunsinane, ClodForest makes the impossible possible. It brings entire forests of context to individual Claude sessions, transforming isolated interactions into continuous, evolving relationships. The prophecy of persistent AI memory is fulfilled not through magic, but through clever engineering and systematic context management.

## Contact

For questions, issues, or collaboration opportunities, please open an issue on GitHub or reach out through the project channels.