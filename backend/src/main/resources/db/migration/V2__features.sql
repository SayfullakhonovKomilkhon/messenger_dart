-- V2: Extended features (voice, reply, forward, pin, edit, delete, block, settings)

-- Users: bio and settings
ALTER TABLE users ADD COLUMN bio TEXT;
ALTER TABLE users ADD COLUMN settings JSONB DEFAULT '{}';

-- Blocked users
CREATE TABLE blocked_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX idx_blocked_blocker ON blocked_users(blocker_id);
CREATE INDEX idx_blocked_blocked ON blocked_users(blocked_id);

-- Messages: voice, reply, forward, pin, edit, delete
ALTER TABLE messages ADD COLUMN is_voice_message BOOLEAN DEFAULT FALSE;
ALTER TABLE messages ADD COLUMN voice_duration INT;
ALTER TABLE messages ADD COLUMN voice_waveform TEXT;
ALTER TABLE messages ADD COLUMN reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL;
ALTER TABLE messages ADD COLUMN forwarded_from_id UUID REFERENCES messages(id) ON DELETE SET NULL;
ALTER TABLE messages ADD COLUMN is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE messages ADD COLUMN is_edited BOOLEAN DEFAULT FALSE;
ALTER TABLE messages ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE messages ADD COLUMN edited_at TIMESTAMP;

CREATE INDEX idx_messages_reply ON messages(reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX idx_messages_pinned ON messages(conversation_id) WHERE is_pinned = TRUE;

-- Conversation participants: pin, mute, notifications
ALTER TABLE conversation_participants ADD COLUMN is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE conversation_participants ADD COLUMN is_muted BOOLEAN DEFAULT FALSE;
ALTER TABLE conversation_participants ADD COLUMN is_notifications_enabled BOOLEAN DEFAULT TRUE;
