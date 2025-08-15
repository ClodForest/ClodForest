"""
LangFlow Python Node Templates
Use these in your Python nodes with proper imports
"""

# ============================================
# Node 1: Initialize (run once to set up)
# ============================================
import sys
sys.path.append('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects')
from ClodStoreE import get_manager

manager = get_manager()
manager.start_scene("Dragon's Rest Inn", "Crystal City", "A cozy tavern with magical ambiance")
manager.add_character("Sage", "The ancient librarian, keeper of forbidden knowledge")

output = "Database initialized with first scene"


# ============================================
# Node 2: Get Current State (before prompt)
# ============================================
import sys
sys.path.append('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects')
from ClodStoreE import get_manager

manager = get_manager()
state_info = manager.format_state_for_prompt("Sage")  # Replace "Sage" with current speaker

output = state_info


# ============================================
# Node 3: Record Event (after LLM response)
# ============================================
import sys
sys.path.append('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects')
from ClodStoreE import get_manager

manager = get_manager()

# Get current state to know who's present
state = manager.get_current_state()
witnesses = state['characters'] if state else []

# Record the dialogue event
# Assuming 'response' contains the LLM output
event_data = {
    'speaker': 'Sage',  # Current speaking character
    'content': response  # This should come from your LLM output
}

manager.record_event('dialogue', event_data, witnesses)

output = response  # Pass through the LLM response


# ============================================
# Node 4: Scene Transition (optional)
# ============================================
import sys
sys.path.append('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects')
from ClodStoreE import get_manager

manager = get_manager()

# Example: detect scene change in user input
if "leave" in user_input.lower() or "go to" in user_input.lower():
    # Parse destination from input
    if "library" in user_input.lower():
        manager.start_scene("Grand Library", "Crystal City", "Endless shelves of ancient tomes")
    elif "street" in user_input.lower():
        manager.start_scene("Crystal Street", "Crystal City", "Glowing crystal buildings line the road")

output = user_input  # Pass through


# ============================================
# Node 5: Add Character (when someone enters)
# ============================================
import sys
sys.path.append('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects')
from ClodStoreE import get_manager

manager = get_manager()

# Example: detect character entrance
if "enters" in user_input.lower() or "arrives" in user_input.lower():
    # Parse character name (this is simplified - you'd want better parsing)
    words = user_input.lower().split()
    if "traveler" in words:
        manager.add_character("Traveler", "A mysterious figure in a worn cloak")
        
        # Record the arrival event
        state = manager.get_current_state()
        witnesses = state['characters'] if state else []
        manager.record_event('arrival', {'character': 'Traveler'}, witnesses)

output = user_input  # Pass through