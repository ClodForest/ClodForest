# ClodStoreE - Scene-Based Story Management

## In LangFlow, your flow structure:

### 1. Initialize Database (run once)
Python node with:
```python
import sqlite3
# Initialize your database
exec(open('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/state_manager.py').read())
result = init_database()
```

### 2. Main Story Flow

**Input Analysis** (Python node):
```python
# Analyze user input for scene changes, character actions, etc.
user_input = message  # from input node
current_scene = get_current_scene_state()

# Detect scene transitions
if "enter" in user_input.lower() or "go to" in user_input.lower():
    # Scene change logic
    pass
    
# Detect character arrivals
if "arrives" in user_input.lower() or "enters" in user_input.lower():
    # Character entry logic
    pass

return current_scene
```

**Event Recording** (Python node after LLM response):
```python
# Record what happened based on LLM output
response = llm_output  # from Ollama

# Parse response for events
# Record who witnessed what
witnesses = current_scene['characters']
record_event('dialogue', {'content': response}, witnesses)

return response
```

### 3. Character-Aware Prompt Template:
```
Current Scene: {scene_name} at {location}
Present Characters: {present_characters}

{character_name}'s Knowledge:
{character_knowledge}

Recent Events in Scene:
{recent_events}

User: {user_input}

[Respond as {character_name}, only using information they would know]
{character_name}:
```

## Test Scenario:

1. Initialize database
2. Start scene: "Dragon's Rest Inn" 
3. Add character: "Sage"
4. User: "A mysterious traveler enters"
5. Add character: "Traveler"
6. Record event: type="arrival", witnessed by Sage
7. Sage speaks (only knows Traveler arrived)
8. Traveler speaks (doesn't know previous events)

## Key Features:
- Characters only know what they witnessed
- Scene transitions are tracked
- Events have witness lists
- Each character has separate knowledge base