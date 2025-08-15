-- ClodStoreE Database Schema
-- Scene tracking with partial information support

-- Current scene state
CREATE TABLE scenes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scene_name TEXT NOT NULL,
    location TEXT NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    description TEXT
);

-- Characters and their knowledge
CREATE TABLE characters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Track who is in which scene
CREATE TABLE scene_participants (
    scene_id INTEGER,
    character_id INTEGER,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP,
    FOREIGN KEY (scene_id) REFERENCES scenes(id),
    FOREIGN KEY (character_id) REFERENCES characters(id)
);

-- Events that happen (who knows what)
CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scene_id INTEGER,
    event_type TEXT, -- 'dialogue', 'action', 'arrival', 'departure', 'discovery'
    event_data JSON,  -- flexible storage for event details
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scene_id) REFERENCES scenes(id)
);

-- Track who witnessed each event
CREATE TABLE event_witnesses (
    event_id INTEGER,
    character_id INTEGER,
    FOREIGN KEY (event_id) REFERENCES events(id),
    FOREIGN KEY (character_id) REFERENCES characters(id),
    PRIMARY KEY (event_id, character_id)
);

-- Character knowledge (facts they know)
CREATE TABLE character_knowledge (
    character_id INTEGER,
    fact_type TEXT, -- 'location', 'character', 'item', 'secret', 'relationship'
    fact_key TEXT,
    fact_value TEXT,
    learned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_event_id INTEGER,
    FOREIGN KEY (character_id) REFERENCES characters(id),
    FOREIGN KEY (source_event_id) REFERENCES events(id),
    PRIMARY KEY (character_id, fact_type, fact_key)
);

-- Views for easy querying
CREATE VIEW current_scene AS
SELECT s.*, GROUP_CONCAT(c.name) as present_characters
FROM scenes s
LEFT JOIN scene_participants sp ON s.id = sp.scene_id AND sp.left_at IS NULL
LEFT JOIN characters c ON sp.character_id = c.id
WHERE s.is_current = TRUE
GROUP BY s.id;

CREATE VIEW character_scene_knowledge AS
SELECT 
    c.name as character_name,
    e.event_type,
    e.event_data,
    e.occurred_at,
    s.scene_name
FROM characters c
JOIN event_witnesses ew ON c.id = ew.character_id
JOIN events e ON ew.event_id = e.id
JOIN scenes s ON e.scene_id = s.id
ORDER BY e.occurred_at DESC;