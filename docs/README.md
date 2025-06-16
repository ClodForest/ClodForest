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
- **Next Focus**: Write operations for complete mind upload/download capability
- **Version Goal**: Approaching 1.0 with round-trip context validation

## Core Features

### Context Inheritance System
- **Modular contexts**: Core → Domain → Project hierarchy
- **Dynamic loading**: Load only what's needed for each session
- **Cultural preservation**: Maintains collaboration patterns and linguistic traditions
- **Session handoffs**: Comprehensive time capsules for continuity

### Leader/Intern Delegation Architecture
ClodForest enables sophisticated delegation patterns where specialized Claude instances handle different aspects of collaboration:

- **Leader Claude**: Strategic thinking, relationship dynamics, design decisions
- **Intern Claude**: Pure technical execution following explicit instructions
- **Quality Focus**: Moves beyond "internet average" to exacting personal standards

*Full details in [General Development Context](state/contexts/domains/general-development.yaml)*

### API Architecture
```
Base URL: https://clodforest.thatsnice.org
Key Endpoints:
  /api/health/               - Service health check
  /api/time/                 - Time synchronization
  /api/repo/                 - Repository browsing
  /api/audit/                - State directory validation
  /api/bustit/{unique}/...   - Cache-busted access
```

### Quality Philosophy

ClodForest embodies specific quality standards that distinguish it from generic AI tools:

- **Function-driven beauty**: Aesthetics serve purpose, not ego
- **Deployment reality checking**: Question every path, user, and dependency
- **Cultural continuity**: Preserve relationship dynamics and linguistic traditions
- **Teaching moment persistence**: Corrections become institutional memory
- **Unix philosophy**: Elegant, composable solutions over complex frameworks

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

### Delegation Pattern
1. **Create Leader chat**: Strategic collaboration and design
2. **Create Intern chat**: Technical execution with explicit standards
3. **Coordinate work**: Leader crafts instructions, Intern implements precisely

## Architecture

### Context Structure
```
ClodForest/state/contexts/
├── core/                    # Foundation contexts
│   ├── robert-identity.yaml
│   ├── collaboration-patterns.yaml
│   ├── communication-style.yaml
│   └── teaching-moments.yaml
├── domains/                 # Domain-specific contexts
│   ├── personal-assistant.yaml
│   ├── general-development.yaml
│   └── clodforest-development.yaml
└── projects/               # Project-specific contexts
    ├── agent-calico/
    ├── local-llm-migration/
    └── clodforest/
```

### Integration Ecosystem
- **ClodHearth**: Local LLM fine-tuning for cost reduction
- **ClodRiver**: Real-time LLM virtual world integration
- **ClodGraph**: (Planned) Graph database for persistent relationships

## Recent Improvements

### Cache Busting (June 2025)
- Implemented `/api/bustit/{unique}/` prefix system
- Enables dynamic content access despite aggressive CDN caching
- Validates with health and time endpoints

### Delegation Architecture (June 2025)
- Leader/Intern pattern successfully tested
- Separates strategic thinking from technical execution
- Maintains quality standards beyond "internet average"

### Bootstrap Refinement
- Extracted CLaSH interface to optional extension
- Prevents safety mechanism triggers
- Stable session loading without interface complexity

### State Validation Tooling
- Audit script validates context inheritance and file formats
- Detects orphaned files and format compliance issues
- Integrated as API endpoint for programmatic access

## Road to 1.0

### Current Limitations
1. **Write Operations**: Cannot save context back to vault (critical blocker)
2. **Round-trip Validation**: Need "mind upload/download" testing
3. **Manual URL Construction**: Claude cannot generate cache-busted URLs
4. **ClaudeLink Protocol**: Multi-instance coordination partially implemented

### 1.0 Success Criteria
- **Complete read/write cycle**: Claude can save and load complete session state
- **Round-trip fidelity**: Loaded contexts maintain full knowledge and personality
- **Delegation scalability**: Multiple specialized instances coordinate seamlessly
- **Cultural preservation**: Relationship dynamics and quality standards persist

## Contributing

ClodForest is actively developed with a focus on:
- Write operation implementation for complete context cycles
- Session continuity optimization and validation
- Multi-instance coordination protocols
- Quality standards that exceed generic AI tool capabilities

## Philosophy

Like Birnam Wood coming to Dunsinane, ClodForest makes the impossible possible. It brings entire forests of context to individual Claude sessions, transforming isolated interactions into continuous, evolving relationships. 

But more than technical capability, ClodForest embodies a quality philosophy: that AI collaboration can exceed "internet average" through systematic standards, cultural continuity, and persistent learning. Each session builds on accumulated wisdom rather than starting from zero.

The prophecy of persistent AI memory is fulfilled not through magic, but through clever engineering, exacting standards, and the recognition that true intelligence requires both technical capability and cultural continuity.

## Contact

For questions, issues, or collaboration opportunities, please open an issue on GitHub or reach out through the project channels.