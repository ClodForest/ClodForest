"""
ClodStoreE State Manager
For use in LangFlow Python nodes
"""

import sqlite3
import json
from datetime import datetime

def init_database(db_path="/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/clodstore.db"):
    """Initialize the database with schema"""
    conn = sqlite3.connect(db_path)
    
    # Read and execute schema
    with open('/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/schema.sql', 'r') as f:
        conn.executescript(f.read())
    
    conn.commit()
    conn.close()
    return "Database initialized"

def start_new_scene(scene_name, location, description="", db_path="/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/clodstore.db"):
    """Start a new scene, ending the previous one"""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # End current scene
    c.execute("UPDATE scenes SET is_current = FALSE, ended_at = CURRENT_TIMESTAMP WHERE is_current = TRUE")
    
    # Start new scene
    c.execute("INSERT INTO scenes (scene_name, location, description) VALUES (?, ?, ?)",
              (scene_name, location, description))
    
    scene_id = c.lastrowid
    conn.commit()
    conn.close()
    
    return f"Started scene '{scene_name}' at {location} (ID: {scene_id})"

def add_character_to_scene(character_name, description="", db_path="/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/clodstore.db"):
    """Add a character to the current scene"""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # Get or create character
    c.execute("SELECT id FROM characters WHERE name = ?", (character_name,))
    result = c.fetchone()
    
    if result:
        character_id = result[0]
    else:
        c.execute("INSERT INTO characters (name, description) VALUES (?, ?)",
                  (character_name, description))
        character_id = c.lastrowid
    
    # Get current scene
    c.execute("SELECT id FROM scenes WHERE is_current = TRUE")
    scene_id = c.fetchone()[0]
    
    # Add to scene
    c.execute("INSERT INTO scene_participants (scene_id, character_id) VALUES (?, ?)",
              (scene_id, character_id))
    
    conn.commit()
    conn.close()
    
    return f"Added {character_name} to current scene"

def record_event(event_type, event_details, witnesses, db_path="/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/clodstore.db"):
    """Record an event and who witnessed it"""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # Get current scene
    c.execute("SELECT id FROM scenes WHERE is_current = TRUE")
    scene_id = c.fetchone()[0]
    
    # Record event
    c.execute("INSERT INTO events (scene_id, event_type, event_data) VALUES (?, ?, ?)",
              (scene_id, event_type, json.dumps(event_details)))
    event_id = c.lastrowid
    
    # Record witnesses
    for witness_name in witnesses:
        c.execute("SELECT id FROM characters WHERE name = ?", (witness_name,))
        char_id = c.fetchone()
        if char_id:
            c.execute("INSERT INTO event_witnesses (event_id, character_id) VALUES (?, ?)",
                      (event_id, char_id[0]))
    
    conn.commit()
    conn.close()
    
    return f"Recorded {event_type} event witnessed by {', '.join(witnesses)}"

def get_character_knowledge(character_name, db_path="/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/clodstore.db"):
    """Get everything a character knows"""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # Get character's witnessed events
    c.execute("""
        SELECT e.event_type, e.event_data, s.scene_name, e.occurred_at
        FROM characters c
        JOIN event_witnesses ew ON c.id = ew.character_id
        JOIN events e ON ew.event_id = e.id
        JOIN scenes s ON e.scene_id = s.id
        WHERE c.name = ?
        ORDER BY e.occurred_at DESC
    """, (character_name,))
    
    events = []
    for row in c.fetchall():
        events.append({
            'type': row[0],
            'data': json.loads(row[1]),
            'scene': row[2],
            'when': row[3]
        })
    
    conn.close()
    return events

def get_current_scene_state(db_path="/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE/clodstore.db"):
    """Get current scene and who's present"""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    c.execute("""
        SELECT s.scene_name, s.location, s.description,
               GROUP_CONCAT(c.name) as present_characters
        FROM scenes s
        LEFT JOIN scene_participants sp ON s.id = sp.scene_id AND sp.left_at IS NULL
        LEFT JOIN characters c ON sp.character_id = c.id
        WHERE s.is_current = TRUE
        GROUP BY s.id
    """)
    
    result = c.fetchone()
    conn.close()
    
    if result:
        return {
            'scene': result[0],
            'location': result[1],
            'description': result[2],
            'characters': result[3].split(',') if result[3] else []
        }
    return None