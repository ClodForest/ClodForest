"""
Simple ClodStoreE integration for LangFlow
Copy this into Python nodes
"""

import sqlite3
import json

DB_PATH = "/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/clodstore.db"

# For initialization node (run once):
def initialize():
    exec(open('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/state_manager.py').read())
    init_database()
    # Start first scene
    start_new_scene("Dragon's Rest Inn", "Crystal City", "A cozy tavern with magical ambiance")
    add_character_to_scene("Sage", "The ancient librarian")
    return "Database initialized with first scene"

# For state check node (before prompt):
def check_state(user_input):
    exec(open('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/state_manager.py').read())
    
    # Get current state
    scene = get_current_scene_state()
    
    # Get knowledge for speaking character (assume Sage for now)
    knowledge = get_character_knowledge("Sage")
    
    # Format for prompt
    state_info = f"""
    Scene: {scene['scene']} at {scene['location']}
    Present: {', '.join(scene['characters'])}
    Recent events: {len(knowledge)} known events
    """
    
    return state_info

# For event recording node (after LLM):
def record_dialogue(llm_response, speaking_character="Sage"):
    exec(open('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/state_manager.py').read())
    
    # Get who's present to witness this
    scene = get_current_scene_state()
    witnesses = scene['characters']
    
    # Record the dialogue event
    event_data = {
        'speaker': speaking_character,
        'content': llm_response
    }
    
    record_event('dialogue', event_data, witnesses)
    
    return llm_response