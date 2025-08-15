"""
ClodStoreE State Manager - Proper module structure
"""

import sqlite3
import json
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional, Any

class StoryStateManager:
    def __init__(self, db_path: str = None):
        if db_path is None:
            base_path = Path("/Users/robert/git/github/ClodForest/ClodForest/state/v1/projects/ClodStoreE")
            self.db_path = str(base_path / "clodstore.db")
        else:
            self.db_path = db_path
        
        self.init_database()
    
    def init_database(self):
        """Initialize database with schema if needed"""
        conn = sqlite3.connect(self.db_path)
        
        # Check if tables exist
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='scenes'")
        if not cursor.fetchone():
            # Load and execute schema
            schema_path = Path(__file__).parent / "schema.sql"
            with open(schema_path, 'r') as f:
                conn.executescript(f.read())
        
        conn.commit()
        conn.close()
    
    def start_scene(self, scene_name: str, location: str, description: str = "") -> int:
        """Start a new scene, ending the previous one"""
        with sqlite3.connect(self.db_path) as conn:
            c = conn.cursor()
            
            # End current scene
            c.execute("UPDATE scenes SET is_current = FALSE, ended_at = CURRENT_TIMESTAMP WHERE is_current = TRUE")
            
            # Start new scene
            c.execute("INSERT INTO scenes (scene_name, location, description) VALUES (?, ?, ?)",
                      (scene_name, location, description))
            
            return c.lastrowid
    
    def add_character(self, character_name: str, description: str = "") -> Dict[str, Any]:
        """Add a character to the current scene"""
        with sqlite3.connect(self.db_path) as conn:
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
            scene_result = c.fetchone()
            
            if not scene_result:
                raise ValueError("No active scene. Start a scene first.")
            
            scene_id = scene_result[0]
            
            # Add to scene
            c.execute("INSERT OR IGNORE INTO scene_participants (scene_id, character_id) VALUES (?, ?)",
                      (scene_id, character_id))
            
            return {"character_id": character_id, "scene_id": scene_id}
    
    def record_event(self, event_type: str, event_details: Dict, witnesses: List[str]) -> int:
        """Record an event and who witnessed it"""
        with sqlite3.connect(self.db_path) as conn:
            c = conn.cursor()
            
            # Get current scene
            c.execute("SELECT id FROM scenes WHERE is_current = TRUE")
            scene_result = c.fetchone()
            
            if not scene_result:
                raise ValueError("No active scene")
            
            scene_id = scene_result[0]
            
            # Record event
            c.execute("INSERT INTO events (scene_id, event_type, event_data) VALUES (?, ?, ?)",
                      (scene_id, event_type, json.dumps(event_details)))
            event_id = c.lastrowid
            
            # Record witnesses
            for witness_name in witnesses:
                c.execute("SELECT id FROM characters WHERE name = ?", (witness_name,))
                char_result = c.fetchone()
                if char_result:
                    c.execute("INSERT INTO event_witnesses (event_id, character_id) VALUES (?, ?)",
                              (event_id, char_result[0]))
            
            return event_id
    
    def get_character_knowledge(self, character_name: str) -> List[Dict]:
        """Get everything a character has witnessed"""
        with sqlite3.connect(self.db_path) as conn:
            c = conn.cursor()
            
            c.execute("""
                SELECT e.event_type, e.event_data, s.scene_name, e.occurred_at
                FROM characters c
                JOIN event_witnesses ew ON c.id = ew.character_id
                JOIN events e ON ew.event_id = e.id
                JOIN scenes s ON e.scene_id = s.id
                WHERE c.name = ?
                ORDER BY e.occurred_at DESC
                LIMIT 20
            """, (character_name,))
            
            events = []
            for row in c.fetchall():
                events.append({
                    'type': row[0],
                    'data': json.loads(row[1]),
                    'scene': row[2],
                    'when': row[3]
                })
            
            return events
    
    def get_current_state(self) -> Dict:
        """Get current scene state and present characters"""
        with sqlite3.connect(self.db_path) as conn:
            c = conn.cursor()
            
            c.execute("""
                SELECT s.id, s.scene_name, s.location, s.description,
                       GROUP_CONCAT(c.name) as present_characters
                FROM scenes s
                LEFT JOIN scene_participants sp ON s.id = sp.scene_id AND sp.left_at IS NULL
                LEFT JOIN characters c ON sp.character_id = c.id
                WHERE s.is_current = TRUE
                GROUP BY s.id
            """)
            
            result = c.fetchone()
            
            if result:
                return {
                    'scene_id': result[0],
                    'scene': result[1],
                    'location': result[2],
                    'description': result[3],
                    'characters': result[4].split(',') if result[4] else []
                }
            return None
    
    def format_state_for_prompt(self, speaking_character: str = None) -> str:
        """Format current state for LLM prompt"""
        state = self.get_current_state()
        
        if not state:
            return "No active scene."
        
        prompt_parts = [
            f"Scene: {state['scene']} at {state['location']}",
            f"Present: {', '.join(state['characters'])}"
        ]
        
        if speaking_character:
            knowledge = self.get_character_knowledge(speaking_character)
            if knowledge:
                recent = knowledge[:5]
                prompt_parts.append(f"\n{speaking_character} knows about:")
                for event in recent:
                    prompt_parts.append(f"- {event['type']}: {event['data'].get('content', event['data'])[:100]}")
        
        return "\n".join(prompt_parts)

# Singleton instance for LangFlow
_manager = None

def get_manager():
    """Get or create the singleton manager instance"""
    global _manager
    if _manager is None:
        _manager = StoryStateManager()
    return _manager