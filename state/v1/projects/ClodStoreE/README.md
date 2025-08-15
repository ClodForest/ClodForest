# ClodStoreE - Scene-Based Story Management

## Features
- **Scene Management**: Track locations and transitions
- **Character Knowledge**: Characters only know what they witnessed
- **Event System**: Record and track who saw what
- **Persistent State**: SQLite database for story continuity

## Setup in LangFlow

### Flow Structure
```
User Input → [State Check] → [Prompt] → Ollama → [Record Event] → Output
```

### Python Nodes

Each Python node should start with:
```python
import sys
sys.path.append('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects')
from ClodStoreE import get_manager

manager = get_manager()
```

#### Node 1: Initialize (run once)
```python
manager.start_scene("Dragon's Rest Inn", "Crystal City", "A cozy tavern")
manager.add_character("Sage", "The ancient librarian")
output = "Scene initialized"
```

#### Node 2: Get State (before prompt)
```python
state_info = manager.format_state_for_prompt("Sage")
output = state_info
```

#### Node 3: Record Event (after LLM)
```python
state = manager.get_current_state()
witnesses = state['characters']
event_data = {'speaker': 'Sage', 'content': response}
manager.record_event('dialogue', event_data, witnesses)
output = response
```

### Prompt Template
```
{state_info}

User: {user_input}

[Respond as the character, only using information they have witnessed]
Character:
```

## Architecture

```
ClodStoreE/
├── __init__.py        # Package init
├── clodstore.py       # Main StoryStateManager class
├── schema.sql         # Database schema
├── langflow_nodes.py  # Copy-paste templates
└── clodstore.db       # SQLite database (created on first run)
```

## Testing

1. Initialize with Sage in the tavern
2. Have Sage speak about something
3. Add a Traveler character: "A traveler enters"
4. Traveler won't know what Sage said before they arrived
5. Both will know what happens after

## API Reference

```python
manager = StoryStateManager()

# Scene management
manager.start_scene(name, location, description)
manager.get_current_state()

# Character management  
manager.add_character(name, description)
manager.get_character_knowledge(character_name)

# Event tracking
manager.record_event(event_type, event_data, witness_list)

# Formatting
manager.format_state_for_prompt(speaking_character)
```