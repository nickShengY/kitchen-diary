-- ============================================================
-- KITCHEN DIARY - NEON DATABASE SCHEMA
-- ============================================================
-- Run this SQL in your Neon SQL Editor to set up the database
-- https://console.neon.tech
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- USERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    photo_url TEXT,
    avatar_emoji TEXT DEFAULT '👨‍🍳',
    bio TEXT,
    is_vip BOOLEAN DEFAULT FALSE,
    vip_expires_at TIMESTAMPTZ,
    recipes_count INTEGER DEFAULT 0,
    likes_received INTEGER DEFAULT 0,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    streak_days INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_streak_date DATE,
    total_recipes_cooked INTEGER DEFAULT 0,
    total_cooking_time_minutes INTEGER DEFAULT 0,
    favorite_cuisine TEXT,
    skill_level TEXT DEFAULT 'beginner',
    dietary_preferences TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_display_name ON users(display_name);
CREATE INDEX IF NOT EXISTS idx_users_level ON users(level DESC);
CREATE INDEX IF NOT EXISTS idx_users_xp ON users(xp DESC);

-- ============================================================
-- USER FOLLOWS (followers/following relationships)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_follows (
    id SERIAL PRIMARY KEY,
    follower_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    following_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower ON user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON user_follows(following_id);

-- ============================================================
-- USER SAVED RECIPES
-- ============================================================
CREATE TABLE IF NOT EXISTS user_saved_recipes (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL,
    collection_name TEXT DEFAULT 'Favorites',
    saved_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, recipe_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_user ON user_saved_recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_recipe ON user_saved_recipes(recipe_id);

-- ============================================================
-- USER BADGES & ACHIEVEMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS badges (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    emoji TEXT,
    category TEXT,
    requirement_type TEXT,
    requirement_value INTEGER,
    xp_reward INTEGER DEFAULT 0,
    rarity TEXT DEFAULT 'common'
);

CREATE TABLE IF NOT EXISTS user_badges (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    badge_id TEXT REFERENCES badges(id) ON DELETE CASCADE,
    awarded_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id);

-- Insert default badges
INSERT INTO badges (id, name, description, emoji, category, requirement_type, requirement_value, xp_reward, rarity) VALUES
    ('first_recipe', 'First Recipe', 'Cooked your first recipe', '🍳', 'cooking', 'recipes_cooked', 1, 10, 'common'),
    ('10_recipes', 'Home Cook', 'Cooked 10 recipes', '👨‍🍳', 'cooking', 'recipes_cooked', 10, 50, 'common'),
    ('50_recipes', 'Seasoned Chef', 'Cooked 50 recipes', '⭐', 'cooking', 'recipes_cooked', 50, 100, 'uncommon'),
    ('100_recipes', 'Master Chef', 'Cooked 100 recipes', '👑', 'cooking', 'recipes_cooked', 100, 250, 'rare'),
    ('7_day_streak', 'Week Warrior', '7 day cooking streak', '🔥', 'streaks', 'streak_days', 7, 50, 'common'),
    ('30_day_streak', 'Monthly Master', '30 day cooking streak', '💪', 'streaks', 'streak_days', 30, 200, 'rare'),
    ('first_follower', 'Social Starter', 'Got your first follower', '👋', 'social', 'followers', 1, 10, 'common'),
    ('100_followers', 'Influencer', 'Reached 100 followers', '🌟', 'social', 'followers', 100, 200, 'rare'),
    ('recipe_creator', 'Recipe Creator', 'Created your first recipe', '📝', 'creating', 'recipes_created', 1, 25, 'common'),
    ('world_cuisine', 'World Traveler', 'Cooked 5 different cuisines', '🌍', 'exploration', 'cuisines_tried', 5, 75, 'uncommon')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- USER PREFERENCES
-- ============================================================
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    theme TEXT DEFAULT 'system',
    color_scheme TEXT DEFAULT 'kitchen_classic',
    font_size TEXT DEFAULT 'medium',
    measurement_unit TEXT DEFAULT 'metric',
    default_servings INTEGER DEFAULT 4,
    notifications_enabled BOOLEAN DEFAULT TRUE,
    sound_enabled BOOLEAN DEFAULT TRUE,
    haptics_enabled BOOLEAN DEFAULT TRUE,
    auto_play_videos BOOLEAN DEFAULT TRUE,
    show_nutrition BOOLEAN DEFAULT TRUE,
    dietary_filters TEXT[],
    cuisine_preferences TEXT[],
    skill_level TEXT DEFAULT 'intermediate',
    cooking_goals TEXT[],
    language TEXT DEFAULT 'en',
    preferences JSONB DEFAULT '{}',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- COOKING HISTORY
-- ============================================================
CREATE TABLE IF NOT EXISTS cooking_history (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL,
    recipe_title TEXT,
    cooked_at TIMESTAMPTZ DEFAULT NOW(),
    duration_minutes INTEGER,
    servings_made INTEGER,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    photo_urls TEXT[],
    modifications TEXT,
    would_make_again BOOLEAN
);

CREATE INDEX IF NOT EXISTS idx_history_user ON cooking_history(user_id);
CREATE INDEX IF NOT EXISTS idx_history_recipe ON cooking_history(recipe_id);
CREATE INDEX IF NOT EXISTS idx_history_date ON cooking_history(cooked_at DESC);

-- ============================================================
-- FORUM POSTS
-- ============================================================
CREATE TABLE IF NOT EXISTS forum_posts (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    author_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL,
    author_avatar TEXT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    image_url TEXT,
    image_urls TEXT[],
    tags TEXT[],
    likes INTEGER DEFAULT 0,
    liked_by TEXT[] DEFAULT '{}',
    comments_count INTEGER DEFAULT 0,
    views INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_category ON forum_posts(category);
CREATE INDEX IF NOT EXISTS idx_posts_author ON forum_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON forum_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_likes ON forum_posts(likes DESC);

-- ============================================================
-- FORUM COMMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS forum_comments (
    id SERIAL PRIMARY KEY,
    post_id TEXT REFERENCES forum_posts(id) ON DELETE CASCADE,
    author_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL,
    author_avatar TEXT,
    content TEXT NOT NULL,
    parent_id INTEGER REFERENCES forum_comments(id) ON DELETE CASCADE,
    likes_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_post ON forum_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON forum_comments(parent_id);

-- ============================================================
-- POST LIKES
-- ============================================================
CREATE TABLE IF NOT EXISTS post_likes (
    id SERIAL PRIMARY KEY,
    post_id TEXT REFERENCES forum_posts(id) ON DELETE CASCADE,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_post_likes_post ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user ON post_likes(user_id);

-- ============================================================
-- RECIPES (Optional - use if not using Firestore)
-- ============================================================
CREATE TABLE IF NOT EXISTS recipes (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    author_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    author_name TEXT,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    total_time_minutes INTEGER GENERATED ALWAYS AS (prep_time_minutes + cook_time_minutes) STORED,
    servings INTEGER DEFAULT 4,
    difficulty TEXT DEFAULT 'medium',
    cuisine TEXT,
    meal_type TEXT,
    dietary_tags TEXT[],
    ingredients JSONB NOT NULL DEFAULT '[]',
    steps JSONB NOT NULL DEFAULT '[]',
    nutrition JSONB,
    tips TEXT[],
    source_url TEXT,
    video_url TEXT,
    likes_count INTEGER DEFAULT 0,
    saves_count INTEGER DEFAULT 0,
    cook_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    average_rating DECIMAL(2,1) DEFAULT 0,
    ratings_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    forked_from TEXT REFERENCES recipes(id) ON DELETE SET NULL,
    fork_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_recipes_author ON recipes(author_id);
CREATE INDEX IF NOT EXISTS idx_recipes_cuisine ON recipes(cuisine);
CREATE INDEX IF NOT EXISTS idx_recipes_difficulty ON recipes(difficulty);
CREATE INDEX IF NOT EXISTS idx_recipes_likes ON recipes(likes_count DESC);
CREATE INDEX IF NOT EXISTS idx_recipes_created ON recipes(created_at DESC);

-- ============================================================
-- RECIPE REVIEWS
-- ============================================================
CREATE TABLE IF NOT EXISTS recipe_reviews (
    id SERIAL PRIMARY KEY,
    recipe_id TEXT REFERENCES recipes(id) ON DELETE CASCADE,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title TEXT,
    content TEXT,
    photo_urls TEXT[],
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(recipe_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_recipe ON recipe_reviews(recipe_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON recipe_reviews(user_id);

-- ============================================================
-- SHOPPING LISTS
-- ============================================================
CREATE TABLE IF NOT EXISTS shopping_lists (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    name TEXT DEFAULT 'Shopping List',
    items JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shopping_user ON shopping_lists(user_id);

-- ============================================================
-- MEAL PLANS
-- ============================================================
CREATE TABLE IF NOT EXISTS meal_plans (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    name TEXT DEFAULT 'Weekly Plan',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    meals JSONB NOT NULL DEFAULT '{}',
    is_shared BOOLEAN DEFAULT FALSE,
    shared_with TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meal_plans_user ON meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_dates ON meal_plans(start_date, end_date);

-- ============================================================
-- COLLECTIONS (Recipe folders)
-- ============================================================
CREATE TABLE IF NOT EXISTS collections (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    emoji TEXT DEFAULT '📁',
    is_public BOOLEAN DEFAULT FALSE,
    recipe_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_collections_user ON collections(user_id);

CREATE TABLE IF NOT EXISTS collection_recipes (
    id SERIAL PRIMARY KEY,
    collection_id INTEGER REFERENCES collections(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(collection_id, recipe_id)
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Increment followers count
CREATE OR REPLACE FUNCTION increment_followers(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET followers_count = followers_count + 1 WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Decrement followers count
CREATE OR REPLACE FUNCTION decrement_followers(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Increment following count
CREATE OR REPLACE FUNCTION increment_following(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET following_count = following_count + 1 WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Decrement following count
CREATE OR REPLACE FUNCTION decrement_following(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET following_count = GREATEST(following_count - 1, 0) WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Increment recipes count
CREATE OR REPLACE FUNCTION increment_recipes_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET recipes_count = recipes_count + 1 WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Update recipe average rating
CREATE OR REPLACE FUNCTION update_recipe_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE recipes SET 
        average_rating = (SELECT AVG(rating) FROM recipe_reviews WHERE recipe_id = NEW.recipe_id),
        ratings_count = (SELECT COUNT(*) FROM recipe_reviews WHERE recipe_id = NEW.recipe_id)
    WHERE id = NEW.recipe_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_recipe_rating
AFTER INSERT OR UPDATE ON recipe_reviews
FOR EACH ROW EXECUTE FUNCTION update_recipe_rating();

-- Update post comments count
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE forum_posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE forum_posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_comments_count
AFTER INSERT OR DELETE ON forum_comments
FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Update collection recipe count
CREATE OR REPLACE FUNCTION update_collection_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE collections SET recipe_count = recipe_count + 1 WHERE id = NEW.collection_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE collections SET recipe_count = GREATEST(recipe_count - 1, 0) WHERE id = OLD.collection_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_collection_count
AFTER INSERT OR DELETE ON collection_recipes
FOR EACH ROW EXECUTE FUNCTION update_collection_count();

-- Toggle like on a forum post: updates likes and liked_by array
CREATE OR REPLACE FUNCTION toggle_post_like(post_id TEXT, user_id TEXT, is_liked BOOLEAN)
RETURNS VOID AS $$
BEGIN
    IF is_liked THEN
        -- User is removing their like
        UPDATE forum_posts
        SET likes = GREATEST(likes - 1, 0),
            liked_by = array_remove(COALESCE(liked_by, '{}'), user_id)
        WHERE id = post_id;

        DELETE FROM post_likes
        WHERE post_likes.post_id = post_id
          AND post_likes.user_id = user_id;
    ELSE
        -- User is adding a like
        UPDATE forum_posts
        SET likes = likes + 1,
            liked_by = CASE
                WHEN COALESCE(liked_by, '{}') @> ARRAY[user_id]::TEXT[] THEN liked_by
                ELSE array_append(COALESCE(liked_by, '{}'), user_id)
            END
        WHERE id = post_id;

        INSERT INTO post_likes (post_id, user_id, created_at)
        VALUES (post_id, user_id, NOW())
        ON CONFLICT (post_id, user_id) DO NOTHING;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ROW LEVEL SECURITY (RLS) - Enable for production
-- ============================================================

-- Uncomment these for production with proper JWT auth:
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cooking_history ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Example RLS policies:
-- CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
-- CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
-- CREATE POLICY "Users can view own history" ON cooking_history FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================

-- INSERT INTO users (id, email, display_name, avatar_emoji) VALUES
--     ('test-user-1', 'chef@example.com', 'Test Chef', '👨‍🍳'),
--     ('test-user-2', 'cook@example.com', 'Home Cook', '👩‍🍳');

COMMENT ON TABLE users IS 'User profiles synced from Firebase Auth';
COMMENT ON TABLE user_follows IS 'Follower/following relationships';
COMMENT ON TABLE cooking_history IS 'Log of cooked recipes per user';
COMMENT ON TABLE forum_posts IS 'Community forum posts';
COMMENT ON TABLE recipes IS 'User-created recipes (optional, can use Firestore instead)';
