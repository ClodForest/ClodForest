# Decision 001: V2 Directory Structure Design

**Date:** 2025-08-12  
**Status:** Implemented  
**Context:** Migration from v1 flat structure to usage-based organization

## Problem

The v1 state directory had several issues:
- Redundant directories (`contexts/` and `contexts/domains/`)
- Unclear separation of concerns (`requests/` vs `contexts/requests/`)
- No clear patterns for different usage types
- Difficult to find information for specific use cases

## Decision

Implemented a usage-frequency and scope-based directory structure:

```
state/v2/
├── core/                          # Always-available context
│   ├── preferences/               # Collaboration style, quality standards
│   ├── patterns/                  # Proven workflows, anti-patterns to avoid
│   └── bootstrap/                 # Quick-start context for new instances
├── projects/                      # Project-specific knowledge
│   └── [project]/
│       ├── decisions/             # Technical choices made
│       ├── conversations/         # Archived chats
│       └── context/               # Project-specific instructions
├── interactions/                  # Cross-project collaboration insights
│   ├── workflows/                 # Successful collaboration patterns
│   ├── troubleshooting/           # Problem-solution pairs
│   └── experiments/               # Things we're trying
└── archive/                       # Historical reference
    ├── by-date/                   # Chronological browsing
    ├── by-topic/                  # Thematic browsing
    └── synthesis/                 # Combined insights from multiple sources
```

## Rationale

### Key Principles
1. **Usage frequency:** Most-accessed content (core/) at top level
2. **Scope of applicability:** Project-specific vs cross-project content
3. **Searchability:** Multiple organizational schemes (date, topic, project)
4. **Risk reduction:** Gradual migration from v1 to minimize errors

### Specific Benefits
- **Bootstrapping:** Template projects for rapid setup
- **Performance measurement:** Track collaboration effectiveness over time
- **Pattern recognition:** Identify what works across different contexts
- **Institutional memory:** Preserve insights regardless of tool changes

## Implementation Approach

1. ✅ Create v2 directory structure
2. ✅ Start with RTA project to validate structure
3. 🔄 Migrate v1 content gradually, file by file
4. 🔄 Archive [RTA] conversations one at a time
5. ⏳ Develop migration scripts if manual process becomes tedious

## Success Metrics

- Time to bootstrap new projects decreases
- Fewer repeated problem-solving sessions
- Improved context loading for new Claude instances
- Measurable collaboration performance improvements

## Next Steps

1. Create first conversation archive from this chat
2. Extract and organize collaboration patterns from v1/core/
3. Build project template structure
4. Develop metrics for measuring collaboration effectiveness

---

*This decision establishes the foundation for systematic knowledge management and continuous improvement of human-AI collaboration patterns.*
