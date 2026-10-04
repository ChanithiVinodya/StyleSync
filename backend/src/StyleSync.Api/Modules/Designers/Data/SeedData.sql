-- =========================================================================
-- StyleSync Component 1: Designer Portfolios & Listings Seed Script
-- =========================================================================

-- 1. Insert Sample AppUsers (Role 1 = Designer)
INSERT INTO "Users" ("Id", "Email", "FullName", "PasswordHash", "Role", "IsActive", "CreatedAtUtc", "UpdatedAtUtc")
VALUES 
  (101, 'kasun.j@stylesync.lk', 'Kasun Jayawardena', 'AQAAAAEAACcQAAAAEHashedKasunPasswordPlaceholder123==', 1, true, NOW(), NULL),
  (102, 'amara.p@stylesync.lk', 'Amara Perera', 'AQAAAAEAACcQAAAAEHashedAmaraPasswordPlaceholder123==', 1, true, NOW(), NULL),
  (103, 'rohan.f@stylesync.lk', 'Rohan Fernando', 'AQAAAAEAACcQAAAAEHashedRohanPasswordPlaceholder123==', 1, true, NOW(), NULL),
  (104, 'dilani.s@stylesync.lk', 'Dilani Senanayake', 'AQAAAAEAACcQAAAAEHashedDilaniPasswordPlaceholder123==', 1, true, NOW(), NULL),
  (105, 'tharindu.w@stylesync.lk', 'Tharindu Wickramasinghe', 'AQAAAAEAACcQAAAAEHashedTharinduPasswordPlaceholder123==', 1, true, NOW(), NULL),
  (106, 'nadeesha.a@stylesync.lk', 'Nadeesha Alwis', 'AQAAAAEAACcQAAAAEHashedNadeeshaPasswordPlaceholder123==', 1, true, NOW(), NULL),
  (107, 'sachintha.b@stylesync.lk', 'Sachintha Bandara', 'AQAAAAEAACcQAAAAEHashedSachinthaPasswordPlaceholder123==', 1, true, NOW(), NULL)
ON CONFLICT ("Email") DO NOTHING;

-- 2. Insert Designer Profiles
-- ListingStatus: 0 = Draft, 1 = Published, 2 = Suspended, 3 = Archived
INSERT INTO "DesignerProfiles" 
("Id", "UserId", "DisplayName", "Bio", "StyleTags", "ServiceCategories", "PriceRangeMin", "PriceRangeMax", "RatePerSqFt", "IsAvailable", "MaxConcurrentProjects", "AverageRating", "ListingStatus", "CreatedAtUtc", "UpdatedAtUtc")
VALUES
  (1, 101, 'Jayawardena Architecture & Interiors', 'Award-winning interior studio specializing in tropical modernism, seamless indoor-outdoor flow, and sustainable natural materials.', ARRAY['Tropical Modernism', 'Minimalist', 'Sustainable', 'Contemporary'], ARRAY['Full Home Interior', 'Living Room', 'Renovation'], 150000.00, 600000.00, 450.00, true, 3, 4.85, 1, NOW(), NULL),
  (2, 102, 'Studio Amara Design', 'Curating cozy, vibrant, Scandinavian and bohemian residential living spaces with artisanal bespoke furniture and curated color palettes.', ARRAY['Boho Chic', 'Scandinavian', 'Contemporary'], ARRAY['Apartment Interior', 'Bedroom Design', 'Color Consultation'], 100000.00, 350000.00, 320.00, true, 2, 4.90, 1, NOW(), NULL),
  (3, 103, 'Urban Loft Atelier', 'Raw textures, exposed brick, dark metal accents, and modern luxury tailored for trendy urban apartments and collaborative workspaces.', ARRAY['Industrial', 'Modern Contemporary', 'Rustic'], ARRAY['Commercial & Office', 'Full Home Interior', 'Kitchen & Dining'], 300000.00, 1200000.00, 650.00, true, 4, 4.75, 1, NOW(), NULL),
  (4, 104, 'Artisan Living Spaces', 'Blending coastal breezy aesthetics with authentic Sri Lankan heritage woodwork, batiks, and open veranda concepts.', ARRAY['Coastal', 'Traditional Sri Lankan', 'Tropical Modernism'], ARRAY['Villa & Boutique Hotel', 'Living Room', 'Outdoor & Patio'], 250000.00, 850000.00, 520.00, true, 3, 4.95, 1, NOW(), NULL),
  (5, 105, 'Wickrama Spatial Concepts', 'Disciplined Japandi and Zen minimalism focusing on light, balance, clean lines, and clutter-free compact urban living.', ARRAY['Minimalist', 'Japandi', 'Zen'], ARRAY['Studio Apartment', 'Bathroom Renovation', 'Full Home Interior'], 80000.00, 280000.00, 280.00, false, 3, 4.60, 2, NOW(), NULL),
  (6, 106, 'Luxe Heritage Interiors', 'High-end bespoke luxury interior styling for luxury penthouses, presidential suites, and prestigious heritage estates.', ARRAY['Classic Luxury', 'Art Deco', 'Colonial Revival'], ARRAY['Penthouse', 'Master Suite', 'Dining & Entertainment'], 500000.00, 2500000.00, 950.00, true, 2, 5.00, 1, NOW(), NULL),
  (7, 107, 'Greenline Eco Spaces', 'Pioneering biophilic design incorporating vertical green walls, natural cross-ventilation, and carbon-neutral recycled materials.', ARRAY['Biophilic', 'Eco-friendly', 'Modern Farmhouse'], ARRAY['Eco-Home', 'Balcony & Terrace', 'Living Room'], 120000.00, 400000.00, 360.00, true, 3, NULL, 0, NOW(), NULL)
ON CONFLICT ("Id") DO NOTHING;

-- 3. Insert Portfolio Items
INSERT INTO "PortfolioItems" 
("Id", "DesignerProfileId", "Title", "Description", "ImageUrl", "BudgetRangeLabel", "ClientInitials", "CompletionStatusBadge", "CreatedAtUtc", "UpdatedAtUtc")
VALUES
  -- Designer 1
  (1, 1, 'Bawa-Inspired Courtyard Residence', 'A 3,200 sq.ft villa in Pelawatte incorporating exposed brick, timber columns, and an open central reflection pool.', 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80', 'LKR 450k-550k', 'K.M.', 1, NOW(), NULL),
  (2, 1, 'Minimalist Open-Concept Living Room', 'Natural teak cabinetry paired with polished cement floors and diffused daylighting fixtures.', 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1200&q=80', 'LKR 200k-300k', 'S.D.', 1, NOW(), NULL),
  (3, 1, 'Modern Sustainable Kitchen Renovation', 'Zero-VOC finishes, recycled quartz countertops, and smart energy-efficient ambient lighting.', 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=1200&q=80', 'LKR 350k-450k', 'T.W.', 1, NOW(), NULL),
  
  -- Designer 2 (At Capacity)
  (4, 2, 'Warm Bohemian Haven', 'Earthy terracotta tones, macramé accents, cane furniture, and layered woven rugs in Havelock City.', 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1200&q=80', 'LKR 150k-250k', 'A.R.', 1, NOW(), NULL),
  (5, 2, 'Nordic Sunlit Bedroom Suite', 'Light oak bedframe, linen drapery, and minimalist pendant lamps creating an airy oasis.', 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80', 'LKR 120k-200k', 'N.H.', 1, NOW(), NULL),
  (6, 2, 'Eclectic Studio Apartment Makeover', 'Space-saving multi-functional partition walls with curated brass lighting and vibrant gallery wall.', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80', 'LKR 180k-280k', 'C.P.', 1, NOW(), NULL),

  -- Designer 3
  (7, 3, 'Industrial Loft Living & Bar', 'Double-height ceiling penthouse featuring black steel trusses, matte charcoal joinery, and reclaimed timber bar counter.', 'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80', 'LKR 750k-1M', 'R.J.', 1, NOW(), NULL),
  (8, 3, 'Monochrome Tech Studio Headquarters', 'Acoustic slat wall panels, ergonomic workstation pods, and industrial track lighting.', 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80', 'LKR 900k-1.2M', 'D.K.', 1, NOW(), NULL),
  (9, 3, 'Raw Concrete & Leather Dining Lounge', 'Custom concrete dining table paired with distress leather chairs and Edison bulb chandelier.', 'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1200&q=80', 'LKR 400k-600k', 'V.S.', 1, NOW(), NULL),

  -- Designer 4 (At Capacity)
  (10, 4, 'Galle Fort Coastal Retreat', 'Restoration of a Dutch colonial townhouse with whitewashed walls, antique satinwood doors, and rattan loungers.', 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80', 'LKR 600k-850k', 'H.L.', 1, NOW(), NULL),
  (11, 4, 'Tropical Veranda & Pool Pavilion', 'Weather-resistant teak daybeds, terracotta planters, and outdoor mood lighting.', 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80', 'LKR 350k-500k', 'P.G.', 1, NOW(), NULL),
  (12, 4, 'Southern Breeze Master Suite', 'Four-poster king bed draped in handloom linen, brass ceiling fan, and louvered folding shutters.', 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=1200&q=80', 'LKR 300k-450k', 'M.F.', 1, NOW(), NULL),

  -- Designer 5
  (13, 5, 'Japandi Serenity Studio', 'Low-profile ash wood platform furniture, shoji screens, and muted beige textured micro-cement.', 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=1200&q=80', 'LKR 150k-250k', 'J.N.', 1, NOW(), NULL),
  (14, 5, 'Minimalist Zen Powder Room', 'Floating stone basin, concealed perimeter LED strip, and matte gunmetal faucets.', 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?auto=format&fit=crop&w=1200&q=80', 'LKR 80k-140k', 'B.W.', 1, NOW(), NULL),

  -- Designer 6
  (15, 6, 'Grand Marble & Velvet Penthouse Salon', 'Calacatta gold marble wall cladding, emerald velvet bespoke sofa, and 24k gold leaf ceiling molding.', 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80', 'LKR 1.5M-2.5M', 'E.B.', 1, NOW(), NULL),
  (16, 6, 'Art Deco Formal Dining Suite', 'Smoked glass 12-seater dining table, fluted walnut panels, and crystal chandelier.', 'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1200&q=80', 'LKR 1M-1.8M', 'O.S.', 1, NOW(), NULL),
  (17, 6, 'Presidential Master Dressing Room', 'Integrated backlit glass wardrobes, central island with velvet watch trays, and full-length vanity mirror.', 'https://images.unsplash.com/photo-1558997519-83ea9252edf8?auto=format&fit=crop&w=1200&q=80', 'LKR 800k-1.2M', 'A.K.', 1, NOW(), NULL),

  -- Designer 7
  (18, 7, 'Biophilic Eco Living Room & Indoor Garden', 'Integrated self-watering green wall, reclaimed rubberwood coffee table, and VOC-free lime plaster.', 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80', 'LKR 200k-350k', 'L.T.', 0, NOW(), NULL),
  (19, 7, 'Zero-Waste Urban Balcony Garden', 'Modular bamboo planters, terracotta irrigation ollas, and solar string lighting.', 'https://images.unsplash.com/photo-1534349762230-e0cadf78f5da?auto=format&fit=crop&w=1200&q=80', 'LKR 120k-200k', 'R.M.', 0, NOW(), NULL)
ON CONFLICT ("Id") DO NOTHING;

-- 4. Insert Placeholder Contracts (for testing ActiveProjectCount capacity guard)
-- ContractStatus: 0 = Active, 1 = Completed, 2 = Cancelled
INSERT INTO "Contracts" ("Id", "DesignerId", "Status")
VALUES
  -- Designer 1 (1 Active, 1 Completed -> 1 of 3)
  (1, 1, 0),
  (2, 1, 1),
  -- Designer 2 (2 Active -> 2 of 2: AT CAPACITY)
  (3, 2, 0),
  (4, 2, 0),
  (5, 2, 1),
  -- Designer 3 (2 Active, 1 Cancelled -> 2 of 4)
  (6, 3, 0),
  (7, 3, 0),
  (8, 3, 2),
  -- Designer 4 (3 Active -> 3 of 3: AT CAPACITY)
  (9, 4, 0),
  (10, 4, 0),
  (11, 4, 0),
  -- Designer 6 (1 Active -> 1 of 2)
  (12, 6, 0)
ON CONFLICT ("Id") DO NOTHING;
