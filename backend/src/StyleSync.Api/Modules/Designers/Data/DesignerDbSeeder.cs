using Microsoft.EntityFrameworkCore;
using StyleSync.Api.Common.Identity;
using StyleSync.Api.Common.Persistence;
using StyleSync.Api.Modules.Designers.Models;

namespace StyleSync.Api.Modules.Designers.Data;

public static class DesignerDbSeeder
{
    public static async Task SeedAsync(AppDbContext context)
    {
        if (await context.DesignerProfiles.AnyAsync())
        {
            return; // DB already seeded
        }

        // 1. Create Sample Users (Role: Designer)
        var users = new List<AppUser>
        {
            new()
            {
                Email = "kasun.j@stylesync.lk",
                FullName = "Kasun Jayawardena",
                PasswordHash = "AQAAAAEAACcQAAAAEHashedKasunPasswordPlaceholder123==",
                Role = UserRole.Designer,
                IsActive = true
            },
            new()
            {
                Email = "amara.p@stylesync.lk",
                FullName = "Amara Perera",
                PasswordHash = "AQAAAAEAACcQAAAAEHashedAmaraPasswordPlaceholder123==",
                Role = UserRole.Designer,
                IsActive = true
            },
            new()
            {
                Email = "rohan.f@stylesync.lk",
                FullName = "Rohan Fernando",
                PasswordHash = "AQAAAAEAACcQAAAAEHashedRohanPasswordPlaceholder123==",
                Role = UserRole.Designer,
                IsActive = true
            },
            new()
            {
                Email = "dilani.s@stylesync.lk",
                FullName = "Dilani Senanayake",
                PasswordHash = "AQAAAAEAACcQAAAAEHashedDilaniPasswordPlaceholder123==",
                Role = UserRole.Designer,
                IsActive = true
            },
            new()
            {
                Email = "tharindu.w@stylesync.lk",
                FullName = "Tharindu Wickramasinghe",
                PasswordHash = "AQAAAAEAACcQAAAAEHashedTharinduPasswordPlaceholder123==",
                Role = UserRole.Designer,
                IsActive = true
            },
            new()
            {
                Email = "nadeesha.a@stylesync.lk",
                FullName = "Nadeesha Alwis",
                PasswordHash = "AQAAAAEAACcQAAAAEHashedNadeeshaPasswordPlaceholder123==",
                Role = UserRole.Designer,
                IsActive = true
            },
            new()
            {
                Email = "sachintha.b@stylesync.lk",
                FullName = "Sachintha Bandara",
                PasswordHash = "AQAAAAEAACcQAAAAEHashedSachinthaPasswordPlaceholder123==",
                Role = UserRole.Designer,
                IsActive = true
            }
        };

        await context.Users.AddRangeAsync(users);
        await context.SaveChangesAsync();

        // 2. Create Designer Profiles
        var profile1 = new DesignerProfile
        {
            UserId = users[0].Id,
            DisplayName = "Jayawardena Architecture & Interiors",
            Bio = "Award-winning interior studio specializing in tropical modernism, seamless indoor-outdoor flow, and sustainable natural materials.",
            StyleTags = new() { "Tropical Modernism", "Minimalist", "Sustainable", "Contemporary" },
            ServiceCategories = new() { "Full Home Interior", "Living Room", "Renovation" },
            PriceRangeMin = 150000m,
            PriceRangeMax = 600000m,
            RatePerSqFt = 450.00m,
            IsAvailable = true,
            MaxConcurrentProjects = 3,
            AverageRating = 4.85m,
            ListingStatus = ListingStatus.Published
        };

        var profile2 = new DesignerProfile
        {
            UserId = users[1].Id,
            DisplayName = "Studio Amara Design",
            Bio = "Curating cozy, vibrant, Scandinavian and bohemian residential living spaces with artisanal bespoke furniture and curated color palettes.",
            StyleTags = new() { "Boho Chic", "Scandinavian", "Contemporary" },
            ServiceCategories = new() { "Apartment Interior", "Bedroom Design", "Color Consultation" },
            PriceRangeMin = 100000m,
            PriceRangeMax = 350000m,
            RatePerSqFt = 320.00m,
            IsAvailable = true,
            MaxConcurrentProjects = 2, // AT CAPACITY (2 active contracts)
            AverageRating = 4.90m,
            ListingStatus = ListingStatus.Published
        };

        var profile3 = new DesignerProfile
        {
            UserId = users[2].Id,
            DisplayName = "Urban Loft Atelier",
            Bio = "Raw textures, exposed brick, dark metal accents, and modern luxury tailored for trendy urban apartments and collaborative workspaces.",
            StyleTags = new() { "Industrial", "Modern Contemporary", "Rustic" },
            ServiceCategories = new() { "Commercial & Office", "Full Home Interior", "Kitchen & Dining" },
            PriceRangeMin = 300000m,
            PriceRangeMax = 1200000m,
            RatePerSqFt = 650.00m,
            IsAvailable = true,
            MaxConcurrentProjects = 4,
            AverageRating = 4.75m,
            ListingStatus = ListingStatus.Published
        };

        var profile4 = new DesignerProfile
        {
            UserId = users[3].Id,
            DisplayName = "Artisan Living Spaces",
            Bio = "Blending coastal breezy aesthetics with authentic Sri Lankan heritage woodwork, batiks, and open veranda concepts.",
            StyleTags = new() { "Coastal", "Traditional Sri Lankan", "Tropical Modernism" },
            ServiceCategories = new() { "Villa & Boutique Hotel", "Living Room", "Outdoor & Patio" },
            PriceRangeMin = 250000m,
            PriceRangeMax = 850000m,
            RatePerSqFt = 520.00m,
            IsAvailable = true,
            MaxConcurrentProjects = 3, // AT CAPACITY (3 active contracts)
            AverageRating = 4.95m,
            ListingStatus = ListingStatus.Published
        };

        var profile5 = new DesignerProfile
        {
            UserId = users[4].Id,
            DisplayName = "Wickrama Spatial Concepts",
            Bio = "Disciplined Japandi and Zen minimalism focusing on light, balance, clean lines, and clutter-free compact urban living.",
            StyleTags = new() { "Minimalist", "Japandi", "Zen" },
            ServiceCategories = new() { "Studio Apartment", "Bathroom Renovation", "Full Home Interior" },
            PriceRangeMin = 80000m,
            PriceRangeMax = 280000m,
            RatePerSqFt = 280.00m,
            IsAvailable = false,
            MaxConcurrentProjects = 3,
            AverageRating = 4.60m,
            ListingStatus = ListingStatus.Suspended
        };

        var profile6 = new DesignerProfile
        {
            UserId = users[5].Id,
            DisplayName = "Luxe Heritage Interiors",
            Bio = "High-end bespoke luxury interior styling for luxury penthouses, presidential suites, and prestigious heritage estates.",
            StyleTags = new() { "Classic Luxury", "Art Deco", "Colonial Revival" },
            ServiceCategories = new() { "Penthouse", "Master Suite", "Dining & Entertainment" },
            PriceRangeMin = 500000m,
            PriceRangeMax = 2500000m,
            RatePerSqFt = 950.00m,
            IsAvailable = true,
            MaxConcurrentProjects = 2,
            AverageRating = 5.00m,
            ListingStatus = ListingStatus.Published
        };

        var profile7 = new DesignerProfile
        {
            UserId = users[6].Id,
            DisplayName = "Greenline Eco Spaces",
            Bio = "Pioneering biophilic design incorporating vertical green walls, natural cross-ventilation, and carbon-neutral recycled materials.",
            StyleTags = new() { "Biophilic", "Eco-friendly", "Modern Farmhouse" },
            ServiceCategories = new() { "Eco-Home", "Balcony & Terrace", "Living Room" },
            PriceRangeMin = 120000m,
            PriceRangeMax = 400000m,
            RatePerSqFt = 360.00m,
            IsAvailable = true,
            MaxConcurrentProjects = 3,
            AverageRating = null, // New listing
            ListingStatus = ListingStatus.Draft
        };

        var profiles = new List<DesignerProfile> { profile1, profile2, profile3, profile4, profile5, profile6, profile7 };
        await context.DesignerProfiles.AddRangeAsync(profiles);
        await context.SaveChangesAsync();

        // 3. Create Portfolio Items (2-3 items per designer)
        var portfolioItems = new List<PortfolioItem>
        {
            // Designer 1
            new()
            {
                DesignerProfileId = profile1.Id,
                Title = "Bawa-Inspired Courtyard Residence",
                Description = "A 3,200 sq.ft villa in Pelawatte incorporating exposed brick, timber columns, and an open central reflection pool.",
                ImageUrl = "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 450k-550k",
                ClientInitials = "K.M.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile1.Id,
                Title = "Minimalist Open-Concept Living Room",
                Description = "Natural teak cabinetry paired with polished cement floors and diffused daylighting fixtures.",
                ImageUrl = "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 200k-300k",
                ClientInitials = "S.D.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile1.Id,
                Title = "Modern Sustainable Kitchen Renovation",
                Description = "Zero-VOC finishes, recycled quartz countertops, and smart energy-efficient ambient lighting.",
                ImageUrl = "https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 350k-450k",
                ClientInitials = "T.W.",
                CompletionStatusBadge = ListingStatus.Published
            },

            // Designer 2 (At Capacity)
            new()
            {
                DesignerProfileId = profile2.Id,
                Title = "Warm Bohemian Haven",
                Description = "Earthy terracotta tones, macramé accents, cane furniture, and layered woven rugs in Havelock City.",
                ImageUrl = "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 150k-250k",
                ClientInitials = "A.R.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile2.Id,
                Title = "Nordic Sunlit Bedroom Suite",
                Description = "Light oak bedframe, linen drapery, and minimalist pendant lamps creating an airy oasis.",
                ImageUrl = "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 120k-200k",
                ClientInitials = "N.H.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile2.Id,
                Title = "Eclectic Studio Apartment Makeover",
                Description = "Space-saving multi-functional partition walls with curated brass lighting and vibrant gallery wall.",
                ImageUrl = "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 180k-280k",
                ClientInitials = "C.P.",
                CompletionStatusBadge = ListingStatus.Published
            },

            // Designer 3
            new()
            {
                DesignerProfileId = profile3.Id,
                Title = "Industrial Loft Living & Bar",
                Description = "Double-height ceiling penthouse featuring black steel trusses, matte charcoal joinery, and reclaimed timber bar counter.",
                ImageUrl = "https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 750k-1M",
                ClientInitials = "R.J.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile3.Id,
                Title = "Monochrome Tech Studio Headquarters",
                Description = "Acoustic slat wall panels, ergonomic workstation pods, and industrial track lighting.",
                ImageUrl = "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 900k-1.2M",
                ClientInitials = "D.K.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile3.Id,
                Title = "Raw Concrete & Leather Dining Lounge",
                Description = "Custom concrete dining table paired with distress leather chairs and Edison bulb chandelier.",
                ImageUrl = "https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 400k-600k",
                ClientInitials = "V.S.",
                CompletionStatusBadge = ListingStatus.Published
            },

            // Designer 4 (At Capacity)
            new()
            {
                DesignerProfileId = profile4.Id,
                Title = "Galle Fort Coastal Retreat",
                Description = "Restoration of a Dutch colonial townhouse with whitewashed walls, antique satinwood doors, and rattan loungers.",
                ImageUrl = "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 600k-850k",
                ClientInitials = "H.L.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile4.Id,
                Title = "Tropical Veranda & Pool Pavilion",
                Description = "Weather-resistant teak daybeds, terracotta planters, and outdoor mood lighting.",
                ImageUrl = "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 350k-500k",
                ClientInitials = "P.G.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile4.Id,
                Title = "Southern Breeze Master Suite",
                Description = "Four-poster king bed draped in handloom linen, brass ceiling fan, and louvered folding shutters.",
                ImageUrl = "https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 300k-450k",
                ClientInitials = "M.F.",
                CompletionStatusBadge = ListingStatus.Published
            },

            // Designer 5
            new()
            {
                DesignerProfileId = profile5.Id,
                Title = "Japandi Serenity Studio",
                Description = "Low-profile ash wood platform furniture, shoji screens, and muted beige textured micro-cement.",
                ImageUrl = "https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 150k-250k",
                ClientInitials = "J.N.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile5.Id,
                Title = "Minimalist Zen Powder Room",
                Description = "Floating stone basin, concealed perimeter LED strip, and matte gunmetal faucets.",
                ImageUrl = "https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 80k-140k",
                ClientInitials = "B.W.",
                CompletionStatusBadge = ListingStatus.Published
            },

            // Designer 6
            new()
            {
                DesignerProfileId = profile6.Id,
                Title = "Grand Marble & Velvet Penthouse Salon",
                Description = "Calacatta gold marble wall cladding, emerald velvet bespoke sofa, and 24k gold leaf ceiling molding.",
                ImageUrl = "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 1.5M-2.5M",
                ClientInitials = "E.B.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile6.Id,
                Title = "Art Deco Formal Dining Suite",
                Description = "Smoked glass 12-seater dining table, fluted walnut panels, and crystal chandelier.",
                ImageUrl = "https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 1M-1.8M",
                ClientInitials = "O.S.",
                CompletionStatusBadge = ListingStatus.Published
            },
            new()
            {
                DesignerProfileId = profile6.Id,
                Title = "Presidential Master Dressing Room",
                Description = "Integrated backlit glass wardrobes, central island with velvet watch trays, and full-length vanity mirror.",
                ImageUrl = "https://images.unsplash.com/photo-1558997519-83ea9252edf8?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 800k-1.2M",
                ClientInitials = "A.K.",
                CompletionStatusBadge = ListingStatus.Published
            },

            // Designer 7
            new()
            {
                DesignerProfileId = profile7.Id,
                Title = "Biophilic Eco Living Room & Indoor Garden",
                Description = "Integrated self-watering green wall, reclaimed rubberwood coffee table, and VOC-free lime plaster.",
                ImageUrl = "https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 200k-350k",
                ClientInitials = "L.T.",
                CompletionStatusBadge = ListingStatus.Draft
            },
            new()
            {
                DesignerProfileId = profile7.Id,
                Title = "Zero-Waste Urban Balcony Garden",
                Description = "Modular bamboo planters, terracotta irrigation ollas, and solar string lighting.",
                ImageUrl = "https://images.unsplash.com/photo-1534349762230-e0cadf78f5da?auto=format&fit=crop&w=1200&q=80",
                BudgetRangeLabel = "LKR 120k-200k",
                ClientInitials = "R.M.",
                CompletionStatusBadge = ListingStatus.Draft
            }
        };

        await context.PortfolioItems.AddRangeAsync(portfolioItems);

        // 4. Create Placeholder Contracts (for testing ActiveProjectCount capacity guard)
        // Designer 1: 1 active contract (Max = 3, Active = 1 => 2 slots remaining)
        // Designer 2: 2 active contracts (Max = 2, Active = 2 => AT CAPACITY)
        // Designer 3: 2 active contracts (Max = 4, Active = 2 => 2 slots remaining)
        // Designer 4: 3 active contracts (Max = 3, Active = 3 => AT CAPACITY)
        // Designer 5: 0 active contracts (Max = 3, Active = 0 => Free)
        // Designer 6: 1 active contract (Max = 2, Active = 1 => 1 slot remaining)
        // Designer 7: 0 active contracts (Max = 3, Active = 0 => Free)
        var contracts = new List<ContractStub>
        {
            // Designer 1 (1 Active, 1 Completed)
            new() { DesignerId = profile1.Id, Status = ContractStatus.Active },
            new() { DesignerId = profile1.Id, Status = ContractStatus.Completed },

            // Designer 2 (2 Active -> AT CAPACITY of 2)
            new() { DesignerId = profile2.Id, Status = ContractStatus.Active },
            new() { DesignerId = profile2.Id, Status = ContractStatus.Active },
            new() { DesignerId = profile2.Id, Status = ContractStatus.Completed },

            // Designer 3 (2 Active, 1 Cancelled -> 2 of 4)
            new() { DesignerId = profile3.Id, Status = ContractStatus.Active },
            new() { DesignerId = profile3.Id, Status = ContractStatus.Active },
            new() { DesignerId = profile3.Id, Status = ContractStatus.Cancelled },

            // Designer 4 (3 Active -> AT CAPACITY of 3)
            new() { DesignerId = profile4.Id, Status = ContractStatus.Active },
            new() { DesignerId = profile4.Id, Status = ContractStatus.Active },
            new() { DesignerId = profile4.Id, Status = ContractStatus.Active },

            // Designer 6 (1 Active -> 1 of 2)
            new() { DesignerId = profile6.Id, Status = ContractStatus.Active }
        };

        await context.Contracts.AddRangeAsync(contracts);
        await context.SaveChangesAsync();
    }
}
