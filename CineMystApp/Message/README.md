# Messages Feature - Backend Integration

## Overview
The Messages feature has been updated to connect with Supabase backend instead of using static data. It now supports real-time conversations between users.

## Database Schema

You need to create the following tables in your Supabase database:

### 1. conversations table
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    participant1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    participant2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    last_message_id UUID,
    last_message_content TEXT,
    last_message_time TIMESTAMPTZ,
    unread_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(participant1_id, participant2_id),
    CHECK (participant1_id < participant2_id)
);

-- Indexes for performance
CREATE INDEX idx_conversations_participant1 ON conversations(participant1_id);
CREATE INDEX idx_conversations_participant2 ON conversations(participant2_id);
CREATE INDEX idx_conversations_last_message_time ON conversations(last_message_time DESC);

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own conversations"
    ON conversations FOR SELECT
    USING (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

CREATE POLICY "Users can create conversations"
    ON conversations FOR INSERT
    WITH CHECK (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

CREATE POLICY "Users can update their own conversations"
    ON conversations FOR UPDATE
    USING (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );
```

### 2. messages table
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'audio')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_unread ON messages(conversation_id, is_read) WHERE NOT is_read;

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view messages in their conversations"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations 
            WHERE conversations.id = messages.conversation_id 
            AND (
                conversations.participant1_id = auth.uid() OR 
                conversations.participant2_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can send messages in their conversations"
    ON messages FOR INSERT
    WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM conversations 
            WHERE conversations.id = conversation_id 
            AND (
                conversations.participant1_id = auth.uid() OR 
                conversations.participant2_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can update their own messages"
    ON messages FOR UPDATE
    USING (sender_id = auth.uid());
```

### 3. user_profiles table (if not already exists)
```sql
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    username TEXT UNIQUE,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_user_profiles_username ON user_profiles(username);
CREATE INDEX idx_user_profiles_full_name ON user_profiles(full_name);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public profiles are viewable by everyone"
    ON user_profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can update their own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);
```

## Database Triggers (Optional but Recommended)

### Automatic timestamp updates
```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to conversations
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply to messages
CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply to user_profiles
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Auto-update conversation on new message
```sql
-- Function to update conversation when new message is sent
CREATE OR REPLACE FUNCTION update_conversation_on_new_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET 
        last_message_id = NEW.id,
        last_message_content = NEW.content,
        last_message_time = NEW.created_at,
        unread_count = unread_count + 1,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversation_after_message_insert
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_on_new_message();
```

## Features Implemented

### 1. **MessagesService** (`Message/service/MessagesService.swift`)
- Fetch all conversations for current user
- Create or get existing conversation between users
- Fetch messages for a conversation
- Send new messages
- Mark messages as read
- Search users by name or username

### 2. **Models** (`Message/models/`)
- `Message.swift` - Message data model
- `ConversationModel.swift` - Conversation and UserProfile data models

### 3. **UI Updates** (`Message/MessagesViewController.swift`)
- Loads conversations from backend
- Shows loading indicator while fetching
- Displays empty state when no conversations
- Formats message timestamps intelligently (Today, Yesterday, Day of week, Date)
- Includes basic chat view controller for viewing/sending messages

## How to Use

### Loading Conversations
Conversations are automatically loaded when the MessagesViewController appears:
```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadConversations()
}
```

### Starting a New Conversation
```swift
let otherUserId = UUID(uuidString: "...")!
let conversation = try await MessagesService.shared.getOrCreateConversation(withUserId: otherUserId)
```

### Sending a Message
```swift
let message = try await MessagesService.shared.sendMessage(
    conversationId: conversationId,
    content: "Hello!",
    messageType: .text
)
```

### Marking Messages as Read
```swift
try await MessagesService.shared.markMessagesAsRead(conversationId: conversationId)
```

## Testing the Feature

1. **Ensure Supabase is configured** - The app uses the global `supabase` client from `auth/Supabase.swift`

2. **Create test data** - You can insert test conversations and messages directly in Supabase SQL editor:
```sql
-- Insert test conversation
INSERT INTO conversations (id, participant1_id, participant2_id, last_message_content, last_message_time)
VALUES (
    uuid_generate_v4(),
    'YOUR_USER_ID',
    'ANOTHER_USER_ID',
    'Test message',
    NOW()
);

-- Insert test message
INSERT INTO messages (id, conversation_id, sender_id, content)
VALUES (
    uuid_generate_v4(),
    'CONVERSATION_ID',
    'SENDER_USER_ID',
    'Hello, this is a test message!'
);
```

3. **Run the app** - Navigate to the Messages tab and you should see your conversations

## Next Steps / Enhancements

1. **Real-time updates** - Implement Supabase Realtime subscriptions to get live message updates
2. **Image/Video messages** - Add support for multimedia messages
3. **User search** - Implement the compose button to search and start conversations with users
4. **Message status** - Show delivered/read status indicators
5. **Push notifications** - Send notifications for new messages
6. **Message reactions** - Add emoji reactions to messages
7. **Group chats** - Extend to support group conversations
8. **Message deletion** - Allow users to delete messages
9. **Typing indicators** - Show when the other user is typing
10. **Message search** - Search within conversations

## Troubleshooting

### "User not authenticated" error
- Make sure the user is logged in before accessing MessagesViewController
- Check that `supabase.auth.currentUser` is not nil

### "Failed to load conversations" error
- Verify the database tables exist with correct schema
- Check RLS policies are correctly set up
- Ensure user_profiles table has data for the users

### No conversations showing
- Check that conversations exist for the current user
- Verify the user IDs in the database match the authenticated user
- Check browser console/Xcode logs for error messages

## Database Permissions Checklist

✓ Tables created: `conversations`, `messages`, `user_profiles`  
✓ RLS enabled on all tables  
✓ RLS policies created for SELECT, INSERT, UPDATE  
✓ Indexes created for performance  
✓ Triggers set up for automatic updates (optional)  
✓ Foreign key constraints in place  

## File Structure
```
CineMystApp/Message/
├── MessagesViewController.swift    # Main messages list UI
├── models/
│   ├── Message.swift              # Message data model
│   └── ConversationModel.swift    # Conversation & UserProfile models
└── service/
    └── MessagesService.swift      # Backend API service
```

## Support
For issues or questions about the Messages feature integration, please check:
- Supabase documentation: https://supabase.com/docs
- Supabase Swift client: https://github.com/supabase-community/supabase-swift
