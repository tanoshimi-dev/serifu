-- Serifu Sample Data
-- Run this after database initialization

-- =====================
-- Categories
-- =====================
INSERT INTO categories (id, name, description, icon, color, sort_order, status, created_at, updated_at) VALUES
('a1000000-0000-0000-0000-000000000001', 'Daily Life', 'Everyday situations and experiences', 'home', '#4CAF50', 1, 'active', NOW(), NOW()),
('a1000000-0000-0000-0000-000000000002', 'Work', 'Office and career scenarios', 'work', '#2196F3', 2, 'active', NOW(), NOW()),
('a1000000-0000-0000-0000-000000000003', 'Love', 'Romance and relationships', 'favorite', '#E91E63', 3, 'active', NOW(), NOW()),
('a1000000-0000-0000-0000-000000000004', 'Friends', 'Friendship moments', 'people', '#FF9800', 4, 'active', NOW(), NOW()),
('a1000000-0000-0000-0000-000000000005', 'Family', 'Family situations', 'family_restroom', '#9C27B0', 5, 'active', NOW(), NOW()),
('a1000000-0000-0000-0000-000000000006', 'Humor', 'Funny and witty scenarios', 'sentiment_very_satisfied', '#FFEB3B', 6, 'active', NOW(), NOW()),
('a1000000-0000-0000-0000-000000000007', 'Philosophy', 'Deep thoughts and wisdom', 'psychology', '#607D8B', 7, 'active', NOW(), NOW()),
('a1000000-0000-0000-0000-000000000008', 'Motivation', 'Inspiring scenarios', 'local_fire_department', '#FF5722', 8, 'active', NOW(), NOW());

-- =====================
-- Users
-- =====================
INSERT INTO users (id, email, name, avatar, bio, total_likes, status, created_at, updated_at) VALUES
('b1000000-0000-0000-0000-000000000001', 'taro@example.com', 'Taro Yamada', 'https://api.dicebear.com/7.x/avataaars/svg?seed=taro', 'Love creating witty one-liners!', 156, 'active', NOW(), NOW()),
('b1000000-0000-0000-0000-000000000002', 'hanako@example.com', 'Hanako Suzuki', 'https://api.dicebear.com/7.x/avataaars/svg?seed=hanako', 'Professional overthinker', 243, 'active', NOW(), NOW()),
('b1000000-0000-0000-0000-000000000003', 'kenji@example.com', 'Kenji Tanaka', 'https://api.dicebear.com/7.x/avataaars/svg?seed=kenji', 'Sarcasm is my love language', 89, 'active', NOW(), NOW()),
('b1000000-0000-0000-0000-000000000004', 'yuki@example.com', 'Yuki Sato', 'https://api.dicebear.com/7.x/avataaars/svg?seed=yuki', 'Finding humor in everyday life', 312, 'active', NOW(), NOW()),
('b1000000-0000-0000-0000-000000000005', 'sakura@example.com', 'Sakura Ito', 'https://api.dicebear.com/7.x/avataaars/svg?seed=sakura', 'Words are my playground', 178, 'active', NOW(), NOW()),
('b1000000-0000-0000-0000-000000000006', 'ryo@example.com', 'Ryo Watanabe', 'https://api.dicebear.com/7.x/avataaars/svg?seed=ryo', 'Dad jokes enthusiast', 67, 'active', NOW(), NOW()),
('b1000000-0000-0000-0000-000000000007', 'mika@example.com', 'Mika Kobayashi', 'https://api.dicebear.com/7.x/avataaars/svg?seed=mika', 'Aspiring comedian', 421, 'active', NOW(), NOW()),
('b1000000-0000-0000-0000-000000000008', 'hiroshi@example.com', 'Hiroshi Nakamura', 'https://api.dicebear.com/7.x/avataaars/svg?seed=hiroshi', 'Life is too short for boring replies', 95, 'active', NOW(), NOW());

-- =====================
-- Quizzes (Daily Challenges)
-- =====================
INSERT INTO quizzes (id, title, description, requirement, category_id, release_date, status, answer_count, created_at, updated_at) VALUES
-- Daily Life
('c1000000-0000-0000-0000-000000000001', 'When the alarm goes off on Monday morning...', 'Express your Monday morning feelings', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '6 days', 'active', 12, NOW(), NOW()),
('c1000000-0000-0000-0000-000000000002', 'When you realize you left your phone at home...', 'That moment of panic', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '5 days', 'active', 8, NOW(), NOW()),
('c1000000-0000-0000-0000-000000000003', 'When the WiFi goes down during an important task...', 'Express your frustration creatively', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '4 days', 'active', 15, NOW(), NOW()),

-- Work
('c1000000-0000-0000-0000-000000000004', 'When your boss says "Do you have a minute?"...', 'That dreaded phrase', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '3 days', 'active', 10, NOW(), NOW()),
('c1000000-0000-0000-0000-000000000005', 'Reply to: "This meeting could have been an email"', 'Corporate life wisdom', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '2 days', 'active', 18, NOW(), NOW()),
('c1000000-0000-0000-0000-000000000006', 'When someone replies-all to a company-wide email...', 'Office chaos moments', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '1 day', 'active', 7, NOW(), NOW()),

-- Love
('c1000000-0000-0000-0000-000000000007', 'The perfect first message on a dating app...', 'Make it memorable', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000003', NOW(), 'active', 22, NOW(), NOW()),
('c1000000-0000-0000-0000-000000000008', 'When they leave you on "read"...', 'Express the silence', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000003', NOW() + INTERVAL '1 day', 'active', 0, NOW(), NOW()),

-- Friends
('c1000000-0000-0000-0000-000000000009', 'When your friend cancels plans last minute...', 'The relief/disappointment mix', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000004', NOW() + INTERVAL '2 days', 'active', 0, NOW(), NOW()),
('c1000000-0000-0000-0000-000000000010', 'The group chat at 3 AM be like...', 'Late night chaos', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000004', NOW() + INTERVAL '3 days', 'draft', 0, NOW(), NOW()),

-- Humor
('c1000000-0000-0000-0000-000000000011', 'If your pet could text you, they would say...', 'Pet thoughts', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000006', NOW() - INTERVAL '7 days', 'active', 25, NOW(), NOW()),
('c1000000-0000-0000-0000-000000000012', 'If your refrigerator could judge you...', 'Kitchen roast', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000006', NOW() - INTERVAL '8 days', 'active', 14, NOW(), NOW()),

-- Philosophy
('c1000000-0000-0000-0000-000000000013', 'Life advice in exactly 10 words...', 'Wisdom compressed', 'Exactly 10 words', 'a1000000-0000-0000-0000-000000000007', NOW() - INTERVAL '9 days', 'active', 19, NOW(), NOW()),

-- Motivation
('c1000000-0000-0000-0000-000000000014', 'What you would tell your younger self...', 'Time travel wisdom', 'Max 150 characters', 'a1000000-0000-0000-0000-000000000008', NOW() - INTERVAL '10 days', 'active', 31, NOW(), NOW());

-- =====================
-- Answers
-- =====================
INSERT INTO answers (id, quiz_id, user_id, content, like_count, comment_count, view_count, status, created_at, updated_at) VALUES
-- Monday morning quiz answers
('d1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'My bed: "Stay." My alarm: "Go." Me: *becomes one with the mattress*', 45, 3, 230, 'active', NOW() - INTERVAL '5 days 23 hours', NOW()),
('d1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000002', 'Monday called. I sent it to voicemail.', 38, 2, 185, 'active', NOW() - INTERVAL '5 days 22 hours', NOW()),
('d1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000007', 'Plot twist: I was already awake. Anxiety is my alarm.', 52, 5, 310, 'active', NOW() - INTERVAL '5 days 20 hours', NOW()),

-- Phone left at home
('d1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000004', 'Suddenly remembering what year it is and panicking accordingly.', 29, 1, 145, 'active', NOW() - INTERVAL '4 days 23 hours', NOW()),
('d1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000005', 'My pocket feels empty. My soul feels empty. Is this freedom or fear?', 34, 2, 178, 'active', NOW() - INTERVAL '4 days 22 hours', NOW()),

-- WiFi down
('d1000000-0000-0000-0000-000000000006', 'c1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000003', 'The router blinked. My deadline blinked. I blinked back tears.', 67, 4, 420, 'active', NOW() - INTERVAL '3 days 23 hours', NOW()),
('d1000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000006', 'Have you tried turning it off and on again? Yes. Have you tried crying? Also yes.', 48, 3, 289, 'active', NOW() - INTERVAL '3 days 22 hours', NOW()),

-- Boss "Do you have a minute"
('d1000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', '*mentally updates resume*', 89, 6, 567, 'active', NOW() - INTERVAL '2 days 23 hours', NOW()),
('d1000000-0000-0000-0000-000000000009', 'c1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000007', 'A minute? Sure. My heart rate says otherwise.', 56, 4, 345, 'active', NOW() - INTERVAL '2 days 22 hours', NOW()),

-- Meeting could have been email
('d1000000-0000-0000-0000-000000000010', 'c1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000002', 'This email could have been a Slack message. This Slack could have been silence.', 73, 5, 489, 'active', NOW() - INTERVAL '1 day 23 hours', NOW()),
('d1000000-0000-0000-0000-000000000011', 'c1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000004', 'Calendar blocked. Soul blocked. Enthusiasm? Left the chat.', 61, 3, 378, 'active', NOW() - INTERVAL '1 day 22 hours', NOW()),

-- Dating app first message
('d1000000-0000-0000-0000-000000000012', 'c1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000005', 'I would say you are out of my league, but I do not believe in leagues. Hi, I am chaos.', 94, 8, 712, 'active', NOW() - INTERVAL '23 hours', NOW()),
('d1000000-0000-0000-0000-000000000013', 'c1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000003', 'My therapist said I should put myself out there. Here I am. Send help.', 78, 6, 534, 'active', NOW() - INTERVAL '22 hours', NOW()),
('d1000000-0000-0000-0000-000000000014', 'c1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000008', 'According to your photos, you like adventures. My couch is an adventure. Interested?', 45, 3, 289, 'active', NOW() - INTERVAL '21 hours', NOW()),

-- Pet texts
('d1000000-0000-0000-0000-000000000015', 'c1000000-0000-0000-0000-000000000011', 'b1000000-0000-0000-0000-000000000006', 'WHERE ARE YOU. WHY DID YOU LEAVE. Oh you are back. I hate you. Feed me. I love you.', 112, 9, 890, 'active', NOW() - INTERVAL '6 days 23 hours', NOW()),
('d1000000-0000-0000-0000-000000000016', 'c1000000-0000-0000-0000-000000000011', 'b1000000-0000-0000-0000-000000000004', 'The red dot. I almost had it. Tomorrow, we go again.', 87, 5, 623, 'active', NOW() - INTERVAL '6 days 22 hours', NOW()),

-- Refrigerator judges
('d1000000-0000-0000-0000-000000000017', 'c1000000-0000-0000-0000-000000000012', 'b1000000-0000-0000-0000-000000000007', 'Opening me at 2 AM will not fill the void. But sure, eat that cheese.', 76, 4, 512, 'active', NOW() - INTERVAL '7 days 23 hours', NOW()),

-- Life advice 10 words
('d1000000-0000-0000-0000-000000000018', 'c1000000-0000-0000-0000-000000000013', 'b1000000-0000-0000-0000-000000000002', 'Stop waiting for permission. You are already good enough now.', 134, 12, 1023, 'active', NOW() - INTERVAL '8 days 23 hours', NOW()),
('d1000000-0000-0000-0000-000000000019', 'c1000000-0000-0000-0000-000000000013', 'b1000000-0000-0000-0000-000000000001', 'Buy the ticket. Take the trip. Worry about it later.', 98, 7, 756, 'active', NOW() - INTERVAL '8 days 22 hours', NOW()),

-- Tell younger self
('d1000000-0000-0000-0000-000000000020', 'c1000000-0000-0000-0000-000000000014', 'b1000000-0000-0000-0000-000000000005', 'That embarrassing thing you did? No one remembers. They are too busy remembering theirs.', 156, 14, 1289, 'active', NOW() - INTERVAL '9 days 23 hours', NOW()),
('d1000000-0000-0000-0000-000000000021', 'c1000000-0000-0000-0000-000000000014', 'b1000000-0000-0000-0000-000000000007', 'Invest in Bitcoin. Just kidding. Invest in therapy. Not kidding.', 123, 10, 945, 'active', NOW() - INTERVAL '9 days 22 hours', NOW());

-- =====================
-- Comments
-- =====================
INSERT INTO comments (id, answer_id, user_id, content, status, created_at, updated_at) VALUES
('e1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000003', 'This is literally me every Monday!', 'active', NOW() - INTERVAL '5 days 20 hours', NOW()),
('e1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000005', 'Becoming one with the mattress is my superpower', 'active', NOW() - INTERVAL '5 days 19 hours', NOW()),
('e1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000004', 'Anxiety as alarm clock gang rise up', 'active', NOW() - INTERVAL '5 days 18 hours', NOW()),
('e1000000-0000-0000-0000-000000000004', 'd1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000001', 'Poetry in the purest form', 'active', NOW() - INTERVAL '3 days 20 hours', NOW()),
('e1000000-0000-0000-0000-000000000005', 'd1000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000002', 'I felt this in my soul', 'active', NOW() - INTERVAL '2 days 20 hours', NOW()),
('e1000000-0000-0000-0000-000000000006', 'd1000000-0000-0000-0000-000000000012', 'b1000000-0000-0000-0000-000000000006', 'This would 100% work on me', 'active', NOW() - INTERVAL '20 hours', NOW()),
('e1000000-0000-0000-0000-000000000007', 'd1000000-0000-0000-0000-000000000015', 'b1000000-0000-0000-0000-000000000002', 'Cat owners understand this on a spiritual level', 'active', NOW() - INTERVAL '6 days 20 hours', NOW()),
('e1000000-0000-0000-0000-000000000008', 'd1000000-0000-0000-0000-000000000018', 'b1000000-0000-0000-0000-000000000008', 'Needed to hear this today', 'active', NOW() - INTERVAL '8 days 20 hours', NOW()),
('e1000000-0000-0000-0000-000000000009', 'd1000000-0000-0000-0000-000000000020', 'b1000000-0000-0000-0000-000000000003', 'This hit different at 3 AM', 'active', NOW() - INTERVAL '9 days 20 hours', NOW()),
('e1000000-0000-0000-0000-000000000010', 'd1000000-0000-0000-0000-000000000020', 'b1000000-0000-0000-0000-000000000006', 'Saving this for when my anxiety acts up', 'active', NOW() - INTERVAL '9 days 19 hours', NOW());

-- =====================
-- Likes (sample)
-- =====================
INSERT INTO likes (id, answer_id, user_id, created_at) VALUES
('f1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '5 days 22 hours'),
('f1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000003', NOW() - INTERVAL '5 days 21 hours'),
('f1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000004', NOW() - INTERVAL '5 days 20 hours'),
('f1000000-0000-0000-0000-000000000004', 'd1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '5 days 19 hours'),
('f1000000-0000-0000-0000-000000000005', 'd1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '5 days 18 hours'),
('f1000000-0000-0000-0000-000000000006', 'd1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '3 days 21 hours'),
('f1000000-0000-0000-0000-000000000007', 'd1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000004', NOW() - INTERVAL '3 days 20 hours'),
('f1000000-0000-0000-0000-000000000008', 'd1000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '2 days 21 hours'),
('f1000000-0000-0000-0000-000000000009', 'd1000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000003', NOW() - INTERVAL '2 days 20 hours'),
('f1000000-0000-0000-0000-000000000010', 'd1000000-0000-0000-0000-000000000012', 'b1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '21 hours'),
('f1000000-0000-0000-0000-000000000011', 'd1000000-0000-0000-0000-000000000012', 'b1000000-0000-0000-0000-000000000004', NOW() - INTERVAL '20 hours'),
('f1000000-0000-0000-0000-000000000012', 'd1000000-0000-0000-0000-000000000015', 'b1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '6 days 21 hours'),
('f1000000-0000-0000-0000-000000000013', 'd1000000-0000-0000-0000-000000000015', 'b1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '6 days 20 hours'),
('f1000000-0000-0000-0000-000000000014', 'd1000000-0000-0000-0000-000000000018', 'b1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '8 days 21 hours'),
('f1000000-0000-0000-0000-000000000015', 'd1000000-0000-0000-0000-000000000020', 'b1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '9 days 21 hours'),
('f1000000-0000-0000-0000-000000000016', 'd1000000-0000-0000-0000-000000000020', 'b1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '9 days 20 hours'),
('f1000000-0000-0000-0000-000000000017', 'd1000000-0000-0000-0000-000000000020', 'b1000000-0000-0000-0000-000000000004', NOW() - INTERVAL '9 days 19 hours');

-- =====================
-- Follows (sample social connections)
-- =====================
INSERT INTO follows (id, follower_id, following_id, created_at) VALUES
('f2000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000007', NOW() - INTERVAL '10 days'),
('f2000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000007', NOW() - INTERVAL '9 days'),
('f2000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000007', NOW() - INTERVAL '8 days'),
('f2000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000005', NOW() - INTERVAL '7 days'),
('f2000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '6 days'),
('f2000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000001', NOW() - INTERVAL '5 days'),
('f2000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '4 days'),
('f2000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000007', NOW() - INTERVAL '3 days'),
('f2000000-0000-0000-0000-000000000009', 'b1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000002', NOW() - INTERVAL '2 days'),
('f2000000-0000-0000-0000-000000000010', 'b1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000005', NOW() - INTERVAL '1 day');
