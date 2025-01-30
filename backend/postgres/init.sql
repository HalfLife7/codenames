-- Enable UUID extension for unique game identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enum types for team and role
CREATE TYPE team_type AS ENUM ('red', 'blue');
CREATE TYPE role_type AS ENUM ('spymaster', 'operative');
CREATE TYPE card_type AS ENUM ('red', 'blue', 'neutral', 'assassin');
CREATE TYPE game_status AS ENUM ('waiting', 'in_progress', 'completed');

-- Remove the word_set enum since we'll use a table
DROP TYPE IF EXISTS word_set;

-- Create the tables
CREATE TABLE word_sets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    is_official BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE words (
    id SERIAL PRIMARY KEY,
    word_set_id INTEGER REFERENCES word_sets(id),
    word VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create a view for word count per set
CREATE VIEW word_set_counts AS
SELECT 
    word_set_id,
    COUNT(*) as word_count
FROM words
GROUP BY word_set_id;

-- Games table
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status game_status DEFAULT 'waiting',
    word_set_id INTEGER REFERENCES word_sets(id),
    first_team team_type DEFAULT 'red',
    current_team team_type DEFAULT 'red',
    winner team_type,
    red_cards_remaining INTEGER GENERATED ALWAYS AS (
        CASE WHEN first_team = 'red' THEN 9 ELSE 8 END
    ) STORED,
    blue_cards_remaining INTEGER GENERATED ALWAYS AS (
        CASE WHEN first_team = 'blue' THEN 9 ELSE 8 END
    ) STORED,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Players table
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    team team_type NOT NULL,
    role role_type NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(game_id, name),
    CONSTRAINT max_players_per_game CHECK (
        (SELECT COUNT(*) FROM players p2 WHERE p2.game_id = game_id) <= 8
    )
);

-- Game cards table (represents cards in a specific game)
CREATE TABLE game_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    word_id INTEGER REFERENCES words(id),
    card_type card_type NOT NULL,
    is_revealed BOOLEAN DEFAULT FALSE,
    position INTEGER NOT NULL, -- 0-24 for the 5x5 grid
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(game_id, position)
);

-- Game turns table (to track game history)
CREATE TABLE game_turns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    spymaster_id UUID REFERENCES players(id),
    clue_word VARCHAR(255),
    clue_number INTEGER,
    unlimited_guesses BOOLEAN DEFAULT FALSE,
    turn_number INTEGER NOT NULL,
    max_guesses INTEGER GENERATED ALWAYS AS (
        CASE WHEN unlimited_guesses THEN NULL ELSE clue_number + 1 END
    ) STORED,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- New table for tracking individual guesses within a turn
CREATE TABLE turn_guesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    turn_id UUID REFERENCES game_turns(id) ON DELETE CASCADE,
    guesser_id UUID REFERENCES players(id),
    card_id UUID REFERENCES game_cards(id),
    guess_order INTEGER NOT NULL,  -- Order of guesses within the turn
    ended_turn BOOLEAN DEFAULT FALSE,  -- True if this guess ended the turn (wrong team/assassin/bystander or last guess)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add spectators table
CREATE TABLE spectators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(game_id, name),
    CONSTRAINT max_spectators_per_game CHECK (
        (SELECT COUNT(*) FROM spectators s2 WHERE s2.game_id = game_id) <= 20
    )
);

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updating timestamps
CREATE TRIGGER update_games_updated_at
    BEFORE UPDATE ON games
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_players_updated_at
    BEFORE UPDATE ON players
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_game_cards_updated_at
    BEFORE UPDATE ON game_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert initial word sets
INSERT INTO word_sets (name, description) VALUES 
    ('original', 'Original Codenames word set');

-- Insert some sample words
INSERT INTO words (word, word_set_id) VALUES 
    ('AFRICA', 1), ('AGENT', 1), ('AIR', 1), ('ALIEN', 1), ('ALPS', 1),
    ('AMAZON', 1), ('AMBULANCE', 1), ('AMERICA', 1), ('ANGEL', 1), ('ANTARCTICA', 1),
    ('APPLE', 1), ('ARM', 1), ('ATLANTIS', 1), ('AUSTRALIA', 1), ('AZTEC', 1),
    ('BACK', 1), ('BALL', 1), ('BAND', 1), ('BANK', 1), ('BAR', 1),
    ('BARK', 1), ('BAT', 1), ('BATTERY', 1), ('BEACH', 1), ('BEAR', 1),
    ('BEAT', 1), ('BED', 1), ('BEIJING', 1), ('BELL', 1), ('BELT', 1),
    ('BERLIN', 1), ('BERMUDA', 1), ('BERRY', 1), ('BILL', 1), ('BLOCK', 1),
    ('BOARD', 1), ('BOLT', 1), ('BOMB', 1), ('BOND', 1), ('BOOM', 1),
    ('BOOT', 1), ('BOTTLE', 1), ('BOW', 1), ('BOX', 1), ('BRIDGE', 1),
    ('BRUSH', 1), ('BUCK', 1), ('BUFFALO', 1), ('BUG', 1), ('BUGLE', 1),
    ('BUTTON', 1), ('CALF', 1), ('CANADA', 1), ('CAP', 1), ('CAPITAL', 1),
    ('CAR', 1), ('CARD', 1), ('CARROT', 1), ('CASINO', 1), ('CAST', 1),
    ('CAT', 1), ('CELL', 1), ('CENTAUR', 1), ('CENTER', 1), ('CHAIR', 1),
    ('CHANGE', 1), ('CHARGE', 1), ('CHECK', 1), ('CHEST', 1), ('CHICK', 1),
    ('CHINA', 1), ('CHOCOLATE', 1), ('CHURCH', 1), ('CIRCLE', 1), ('CLIFF', 1),
    ('CLOAK', 1), ('CLUB', 1), ('CODE', 1), ('COLD', 1), ('COMIC', 1),
    ('COMPOUND', 1), ('CONCERT', 1), ('CONDUCTOR', 1), ('CONTRACT', 1), ('COOK', 1),
    ('COPPER', 1), ('COTTON', 1), ('COURT', 1), ('COVER', 1), ('CRANE', 1),
    ('CRASH', 1), ('CRICKET', 1), ('CROSS', 1), ('CROWN', 1), ('CYCLE', 1),
    ('CZECH', 1), ('DANCE', 1), ('DATE', 1), ('DAY', 1), ('DEATH', 1),
    ('DECK', 1), ('DEGREE', 1), ('DIAMOND', 1), ('DICE', 1), ('DINOSAUR', 1),
    ('DISEASE', 1), ('DOCTOR', 1), ('DOG', 1), ('DRAFT', 1), ('DRAGON', 1),
    ('DRESS', 1), ('DRILL', 1), ('DROP', 1), ('DUCK', 1), ('DWARF', 1),
    ('EAGLE', 1), ('EGYPT', 1), ('EMBASSY', 1), ('ENGINE', 1), ('ENGLAND', 1),
    ('EUROPE', 1), ('EYE', 1), ('FACE', 1), ('FAIR', 1), ('FALL', 1),
    ('FAN', 1), ('FENCE', 1), ('FIELD', 1), ('FIGHTER', 1), ('FIGURE', 1),
    ('FILE', 1), ('FILM', 1), ('FIRE', 1), ('FISH', 1), ('FLUTE', 1),
    ('FLY', 1), ('FOOT', 1), ('FORCE', 1), ('FOREST', 1), ('FORK', 1),
    ('FRANCE', 1), ('GAME', 1), ('GAS', 1), ('GENIUS', 1), ('GERMANY', 1),
    ('GHOST', 1), ('GIANT', 1), ('GLASS', 1), ('GLOVE', 1), ('GOLD', 1),
    ('GRACE', 1), ('GRASS', 1), ('GREECE', 1), ('GREEN', 1), ('GROUND', 1),
    ('HAM', 1), ('HAND', 1), ('HAWK', 1), ('HEAD', 1), ('HEART', 1),
    ('HELICOPTER', 1), ('HIMALAYAS', 1), ('HOLE', 1), ('HOLLYWOOD', 1), ('HONEY', 1),
    ('HOOD', 1), ('HOOK', 1), ('HORN', 1), ('HORSE', 1), ('HORSESHOE', 1),
    ('HOSPITAL', 1), ('HOTEL', 1), ('ICE', 1), ('ICE CREAM', 1), ('INDIA', 1),
    ('IRON', 1), ('IVORY', 1), ('JACK', 1), ('JAM', 1), ('JET', 1),
    ('JUPITER', 1), ('KANGAROO', 1), ('KETCHUP', 1), ('KEY', 1), ('KID', 1),
    ('KING', 1), ('KIWI', 1), ('KNIFE', 1), ('KNIGHT', 1), ('LAB', 1),
    ('LAP', 1), ('LASER', 1), ('LAWYER', 1), ('LEAD', 1), ('LEMON', 1),
    ('LEPRECHAUN', 1), ('LIFE', 1), ('LIGHT', 1), ('LIMOUSINE', 1), ('LINE', 1),
    ('LINK', 1), ('LION', 1), ('LITTER', 1), ('LOCH NESS', 1), ('LOCK', 1),
    ('LOG', 1), ('LONDON', 1), ('LUCK', 1), ('MAIL', 1), ('MAMMOTH', 1),
    ('MAPLE', 1), ('MARBLE', 1), ('MARCH', 1), ('MASS', 1), ('MATCH', 1),
    ('MERCURY', 1), ('MEXICO', 1), ('MICROSCOPE', 1), ('MILLIONAIRE', 1), ('MINE', 1),
    ('MINT', 1), ('MISSILE', 1), ('MODEL', 1), ('MOLE', 1), ('MOON', 1),
    ('MOSCOW', 1), ('MOUNT', 1), ('MOUSE', 1), ('MOUTH', 1), ('MUG', 1),
    ('NAIL', 1), ('NEEDLE', 1), ('NET', 1), ('NEW YORK', 1), ('NIGHT', 1),
    ('NINJA', 1), ('NOTE', 1), ('NOVEL', 1), ('NURSE', 1), ('NUT', 1),
    ('OCTOPUS', 1), ('OIL', 1), ('OLIVE', 1), ('OLYMPUS', 1), ('OPERA', 1),
    ('ORANGE', 1), ('ORGAN', 1), ('PALM', 1), ('PAN', 1), ('PANTS', 1),
    ('PAPER', 1), ('PARACHUTE', 1), ('PARK', 1), ('PART', 1), ('PASS', 1),
    ('PASTE', 1), ('PENGUIN', 1), ('PHOENIX', 1), ('PIANO', 1), ('PIE', 1),
    ('PILOT', 1), ('PIN', 1), ('PIPE', 1), ('PIRATE', 1), ('PISTOL', 1),
    ('PIT', 1), ('PITCH', 1), ('PLANE', 1), ('PLASTIC', 1), ('PLATE', 1),
    ('PLATYPUS', 1), ('PLAY', 1), ('PLOT', 1), ('POINT', 1), ('POISON', 1),
    ('POLE', 1), ('POLICE', 1), ('POOL', 1), ('PORT', 1), ('POST', 1),
    ('POUND', 1), ('PRESS', 1), ('PRINCESS', 1), ('PUMPKIN', 1), ('PUPIL', 1),
    ('PYRAMID', 1), ('QUEEN', 1), ('RABBIT', 1), ('RACKET', 1), ('RAY', 1),
    ('REVOLUTION', 1), ('RING', 1), ('ROBIN', 1), ('ROBOT', 1), ('ROCK', 1),
    ('ROME', 1), ('ROOT', 1), ('ROSE', 1), ('ROULETTE', 1), ('ROUND', 1),
    ('ROW', 1), ('RULER', 1), ('SATELLITE', 1), ('SATURN', 1), ('SCALE', 1),
    ('SCHOOL', 1), ('SCIENTIST', 1), ('SCORPION', 1), ('SCREEN', 1), ('SCUBA DIVER', 1),
    ('SEAL', 1), ('SERVER', 1), ('SHADOW', 1), ('SHAKESPEARE', 1), ('SHARK', 1),
    ('SHIP', 1), ('SHOE', 1), ('SHOP', 1), ('SHOT', 1), ('SINK', 1),
    ('SKYSCRAPER', 1), ('SLIP', 1), ('SLUG', 1), ('SMUGGLER', 1), ('SNOW', 1),
    ('SNOWMAN', 1), ('SOCK', 1), ('SOLDIER', 1), ('SOUL', 1), ('SOUND', 1),
    ('SPACE', 1), ('SPELL', 1), ('SPIDER', 1), ('SPIKE', 1), ('SPINE', 1),
    ('SPOT', 1), ('SPRING', 1), ('SPY', 1), ('SQUARE', 1), ('STADIUM', 1),
    ('STAFF', 1), ('STAR', 1), ('STATE', 1), ('STICK', 1), ('STOCK', 1),
    ('STRAW', 1), ('STREAM', 1), ('STRIKE', 1), ('STRING', 1), ('SUB', 1),
    ('SUIT', 1), ('SUPERHERO', 1), ('SWING', 1), ('SWITCH', 1), ('TABLE', 1),
    ('TABLET', 1), ('TAG', 1), ('TAIL', 1), ('TAP', 1), ('TEACHER', 1),
    ('TELESCOPE', 1), ('TEMPLE', 1), ('THEATER', 1), ('THIEF', 1), ('THUMB', 1),
    ('TICK', 1), ('TIE', 1), ('TIME', 1), ('TOKYO', 1), ('TOOTH', 1),
    ('TORCH', 1), ('TOWER', 1), ('TRACK', 1), ('TRAIN', 1), ('TRIANGLE', 1),
    ('TRIP', 1), ('TRUNK', 1), ('TUBE', 1), ('TURKEY', 1), ('UNDERTAKER', 1),
    ('UNICORN', 1), ('VACUUM', 1), ('VAN', 1), ('VET', 1), ('WAKE', 1),
    ('WALL', 1), ('WAR', 1), ('WASHER', 1), ('WASHINGTON', 1), ('WATCH', 1),
    ('WATER', 1), ('WAVE', 1), ('WEB', 1), ('WELL', 1), ('WHALE', 1),
    ('WHIP', 1), ('WIND', 1), ('WITCH', 1), ('WORM', 1), ('YARD', 1); 