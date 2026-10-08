-- ============================================================================
-- StyleSync Local Development Seeding Script
-- Target: Inserts 1000 realistic designer profiles linked to valid AppUser rows
-- Safety: Idempotent (safe to run multiple times), guarded against production
-- ============================================================================

DO $$
BEGIN
    -- ------------------------------------------------------------------------
    -- PRODUCTION SAFETY GUARD
    -- Refuse execution if connected to non-local / production host
    -- ------------------------------------------------------------------------
    IF current_database() NOT IN ('stylesync_db', 'postgres', 'stylesync_test') 
       AND current_database() NOT LIKE '%dev%' 
       AND current_database() NOT LIKE '%local%' THEN
        RAISE EXCEPTION 'CRITICAL: This seeding script is strictly for LOCAL development and testing. Aborting on database "%".', current_database();
    END IF;
    
    RAISE NOTICE 'Starting dev seeding for 1000 designer profiles into %...', current_database();
END $$;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- STEP 1: Insert 1000 Designer Users (if not already present)
-- ----------------------------------------------------------------------------
WITH first_names AS (
    SELECT ARRAY[
        'Kavinda', 'Shenali', 'Ravindu', 'Nisansala', 'Dilshan', 'Chathurika', 
        'Amila', 'Praveen', 'Tharushi', 'Sachin', 'Anuki', 'Dulan', 'Senuri',
        'Hasitha', 'Bimsara', 'Dinithi', 'Chamara', 'Sanduni', 'Oshada', 'Kaveesha',
        'Liam', 'Maya', 'Noah', 'Elena', 'Lucas', 'Chloe', 'Julian', 'Sophia',
        'Adrian', 'Zara', 'Alexander', 'Isabella', 'Gabriel', 'Aria', 'Marcus', 'Nadia'
    ] AS arr
),
last_names AS (
    SELECT ARRAY[
        'Perera', 'Silva', 'Fernando', 'Jayasinghe', 'Wickramasinghe', 'Bandara',
        'Gunaratne', 'Dissanayake', 'Ranasinghe', 'Senanayake', 'Herath', 'Mendis',
        'Karunaratne', 'Peiris', 'Abeygunawardena', 'Samarawickrama', 'Vanderwert',
        'Sterling', 'Chen', 'Vance', 'Dubois', 'Kowalski', 'Moretti', 'Novak'
    ] AS arr
),
generated_users AS (
    SELECT 
        -- Deterministic UUID generated from namespace to guarantee idempotency across multiple runs
        uuid_generate_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid, 'stylesync_dev_designer_' || LPAD(i::text, 4, '0')) AS id,
        fn.arr[1 + ((i * 7 + 3) % array_length(fn.arr, 1))] || ' ' || ln.arr[1 + ((i * 13 + 5) % array_length(ln.arr, 1))] AS name,
        'designer_seed_' || LPAD(i::text, 4, '0') || '@dev.stylesync.local' AS email,
        -- Default dev password hash: Password123!
        '$2a$11$e8/4243jL9z1.k3v9fB3dOBh.lUe6H87R1wRkF/zO2c3V0Xy.1kC2' AS password_hash,
        'Designer' AS role,
        true AS is_active,
        (NOW() - ((i % 365) || ' days')::interval) AS created_at,
        NOW() AS updated_at
    FROM generate_series(1, 1000) AS i
    CROSS JOIN first_names fn
    CROSS JOIN last_names ln
)
INSERT INTO "Users" ("Id", "Name", "Email", "PasswordHash", "Role", "IsActive", "CreatedAt", "UpdatedAt")
SELECT id, name, email, password_hash, role, is_active, created_at, updated_at
FROM generated_users
ON CONFLICT ("Email") DO NOTHING;


-- ----------------------------------------------------------------------------
-- STEP 2: Insert 1000 Matching Designer Profiles
-- ----------------------------------------------------------------------------
WITH studio_suffixes AS (
    SELECT ARRAY[
        'Design Studio', 'Interiors & Living', 'Spatial Concepts', 'Architectural Spaces', 
        'Atelier Interiors', 'Modern Habitat', 'Creative Spaces', 'Design Collective',
        'Living Aesthetics', 'Interiors Co.', 'Design Group', 'Studio Lab'
    ] AS arr
),
style_tags_pool AS (
    SELECT ARRAY[
        'Modern', 'Scandinavian', 'Minimalist', 'Industrial', 'Bohemian', 
        'Contemporary', 'Rustic', 'Art Deco', 'Japandi', 'Traditional', 
        'Mid-Century Modern', 'Coastal', 'Tropical Modern', 'Eclectic'
    ] AS arr
),
service_categories_pool AS (
    SELECT ARRAY[
        'Residential Interior', 'Full Home Renovation', 'Space Planning', 
        'Color Consultation', 'Kitchen & Bath Design', 'Commercial Interior', 
        'Lighting Design', 'Furniture & Decor Styling', '3D Visualisation'
    ] AS arr
),
bios_pool AS (
    SELECT ARRAY[
        'Passionate interior designer specializing in creating clean, functional, and timeless living spaces tailored to your everyday lifestyle.',
        'Over 8 years of experience transforming residential and boutique commercial properties with contemporary aesthetics and natural light.',
        'Focused on sustainable materials, balanced ergonomics, and personalized design solutions that bring warmth and character into modern homes.',
        'Award-winning architectural designer blending tropical modernist influences with minimalist precision and bespoke interior craftsmanship.',
        'Dedicated to budget-conscious yet luxurious interior transformations, offering full-scale 3D modeling and end-to-end execution guidance.'
    ] AS arr
),
generated_profiles AS (
    SELECT 
        u."Id" AS user_id,
        u."Name" || ' ' || sfx.arr[1 + ((i * 11 + 2) % array_length(sfx.arr, 1))] AS display_name,
        bio.arr[1 + ((i * 3 + 1) % array_length(bio.arr, 1))] AS bio,
        
        -- Style tags (2 to 4 varied tags per designer)
        ARRAY[
            styles.arr[1 + ((i * 3 + 1) % array_length(styles.arr, 1))],
            styles.arr[1 + ((i * 5 + 3) % array_length(styles.arr, 1))],
            styles.arr[1 + ((i * 7 + 5) % array_length(styles.arr, 1))]
        ] AS style_tags,
        
        -- Service categories (2 to 3 categories per designer)
        ARRAY[
            services.arr[1 + ((i * 2 + 1) % array_length(services.arr, 1))],
            services.arr[1 + ((i * 4 + 3) % array_length(services.arr, 1))]
        ] AS service_categories,
        
        -- Realistic budget & rate ranges (LKR)
        (75000 + ((i * 17) % 15) * 25000)::numeric(18,2) AS price_range_min,
        (350000 + ((i * 31) % 20) * 100000)::numeric(18,2) AS price_range_max,
        (350 + ((i * 7) % 25) * 50)::numeric(18,2) AS rate_per_sq_ft,
        
        -- Availability: ~85% available, ~15% currently unavailable
        ((i % 7) != 0) AS is_available,
        
        -- Max concurrent projects: between 2 and 6
        (2 + (i % 5))::integer AS max_concurrent_projects,
        
        -- Rating: ~10% have no rating (NULL / 0 completed projects), others range from 3.40 to 5.00
        CASE 
            WHEN i % 10 = 0 THEN NULL
            ELSE (3.40 + ((i * 13) % 161) * 0.01)::numeric(3,2)
        END AS average_rating,
        
        -- ListingStatus: 1 = Published (90%), 0 = Draft (5%), 2 = Suspended (5%)
        CASE 
            WHEN i % 20 = 0 THEN 0  -- Draft
            WHEN i % 20 = 19 THEN 2 -- Suspended
            ELSE 1                  -- Published
        END AS listing_status,
        
        (NOW() - ((i % 300) || ' days')::interval) AS created_at_utc,
        NOW() AS updated_at_utc
    FROM generate_series(1, 1000) AS i
    CROSS JOIN studio_suffixes sfx
    CROSS JOIN style_tags_pool styles
    CROSS JOIN service_categories_pool services
    CROSS JOIN bios_pool bio
    JOIN "Users" u ON u."Email" = 'designer_seed_' || LPAD(i::text, 4, '0') || '@dev.stylesync.local'
)
INSERT INTO "DesignerProfiles" (
    "UserId", "DisplayName", "Bio", "StyleTags", "ServiceCategories", 
    "PriceRangeMin", "PriceRangeMax", "RatePerSqFt", "IsAvailable", 
    "MaxConcurrentProjects", "AverageRating", "ListingStatus", 
    "CreatedAtUtc", "UpdatedAtUtc"
)
SELECT 
    user_id, display_name, bio, style_tags, service_categories,
    price_range_min, price_range_max, rate_per_sq_ft, is_available,
    max_concurrent_projects, average_rating, listing_status,
    created_at_utc, updated_at_utc
FROM generated_profiles
ON CONFLICT ("UserId") DO NOTHING;

-- Output confirmation summary
DO $$
DECLARE
    seeded_count integer;
BEGIN
    SELECT COUNT(*) INTO seeded_count 
    FROM "Users" u 
    JOIN "DesignerProfiles" dp ON dp."UserId" = u."Id"
    WHERE u."Email" LIKE 'designer_seed_%@dev.stylesync.local';
    
    RAISE NOTICE 'SUCCESS: % seeded designer profiles are present in the database.', seeded_count;
END $$;
