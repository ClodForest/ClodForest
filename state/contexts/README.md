# Context Management System

Modular context loading for Claude sessions. Reference directories to load relevant context sets.

## Directory Structure

### `defaults/`
Core user preferences and collaboration patterns. Always load these.
- `user-preferences.md` - Robert's technical background, communication style, workflow preferences

### `ClodForest/`
ClaudeLink/ClodForest project-specific contexts and development progression.
- `claudelink-dev-003-to-004.md` - Development session context
- `claudelink-dev-004-to-005.md` - Development session context

### `projects/`
Non-coding project contexts (nina-claire, pothead-guru, termcap, triage, etc.)
- Mixed project files moved from old `state/context/` directory

### `coding/`
Coding project contexts and technical implementations.
- `chat-copier.js` - Code-related project context

### `sessions/`
Session-specific contexts for particular conversations or work sessions.
- `spirograph.md` - Parametric function playground session context

### `culture/`
Cultural and linguistic patterns developed through collaboration.
- `CL-dev-*.md` - Cultural evolution documentation

## Usage Patterns

**Load defaults for any session:**
```
@state/contexts/defaults/
```

**Load ClodForest project context:**
```
@state/contexts/defaults/
@state/contexts/ClodForest/
```

**Load coding project context:**
```
@state/contexts/defaults/
@state/contexts/coding/
```

**Load specific session context:**
```
@state/contexts/defaults/
@state/contexts/sessions/spirograph.md
```

**Load everything (comprehensive context):**
```
@state/contexts/
```

## Context Consolidation

As is tradition, this modular approach enables:
- Selective context loading by project
- Reduced token usage for focused sessions  
- Easier maintenance of context categories
- Future expansion without reorganization
