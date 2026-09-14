import { PersonaInfo, CaseStudy, Testimonial, FeaturePillar } from '../types';

export const HERO_DATA = {
  eyebrow: "Verified Marketplace & Room Makeover Platform",
  title: "Interior design, perfectly matched. Reliably delivered.",
  subtitle: "Share your room and your style. Get matched with a designer who fits. Watch your renovation move forward, milestone by milestone, with human sign-off at every stage.",
  stats: [
    { value: "99.4%", label: "On-Budget Completion", subtext: "Zero hidden quote creep" },
    { value: "48 hrs", label: "Deterministic Match", subtext: "Capacity-verified designers" },
    { value: "100%", label: "Contract Milestone Tracking", subtext: "Dual human sign-offs" },
  ],
};

export const FEATURES_DATA: FeaturePillar[] = [
  {
    id: "smart-matching",
    number: "01",
    title: "Smart Matching",
    subtitle: "Mathematical alignment, not vague AI guesswork",
    description: "We match you using what actually matters — your room's layout, lighting, and style, plus your budget — against designers who are verified and genuinely have capacity to take you on.",
    bulletPoints: [
      "Matched on real style fit — Japandi, Warm Modern, Traditional, Organic Minimalist, and more",
      "Only matched with designers who have real availability — never overloaded",
      "Matched against real past projects similar to your room",
    ],
    highlightMetric: "98.7% Client Satisfaction on First Match",
  },
  {
    id: "transparent-quotes",
    number: "02",
    title: "Transparent Quotes",
    subtitle: "Guaranteed pricing with locked caps",
    description: "Say goodbye to surprise overages and vague ballpark estimates. You receive a clear, itemized breakdown of materials, trade labor, and designer fees before any contract is signed.",
    bulletPoints: [
      "Every material price verified against regional supplier trade catalogs",
      "Labor costs calculated directly from your room's dimensions and complexity",
      "Guaranteed price cap — zero surprise fees or unapproved markups",
    ],
    highlightMetric: "$0 Surprise Overages on 99.4% of Projects",
  },
  {
    id: "milestone-tracking",
    number: "03",
    title: "Milestone Tracking",
    subtitle: "Clear progress stages from concept to handover",
    description: "Every project is organized into four clear stages: Concept Approval, Technical Specs, Delivery & Staging, and Final Handover. You always know exactly where your makeover stands.",
    bulletPoints: [
      "Track furniture and material shipments straight to your room",
      "Visual photo updates verify quality before each phase completes",
      "Coordinated staging schedules prevent contractor downtime and delivery delays",
    ],
    highlightMetric: "100% On-Schedule Milestone Tracking",
  },
  {
    id: "human-approval",
    number: "04",
    title: "Human Approval",
    subtitle: "Smart planning tools, verified by real people",
    description: "Technology handles the measurements and calculations, but real people review every detail. Both you and your dedicated StyleSync coordinator sign off before any milestone is marked complete.",
    bulletPoints: [
      "Dedicated Project Coordinator assigned to monitor your renovation",
      "Dual sign-off required before advancing to the next project phase",
      "Documented revision cycles ensure your feedback is captured and delivered",
    ],
    highlightMetric: "Dual Human Sign-Off on Every Milestone",
  },
];

export const PERSONAS_DATA: PersonaInfo[] = [
  {
    id: "client",
    title: "For Clients",
    badge: "Mobile App (iOS & Android)",
    tagline: "Transform your living space with clarity and peace of mind.",
    description: "Optimized for homeowners to quickly capture room geometry and follow their makeover at every step.",
    keyBenefits: [
      "Direct camera room capture and architectural style survey",
      "Transparent itemized quote with calculated trade pricing",
      "Live milestone photo updates and material delivery tracking",
    ],
    ctaText: "Get the Mobile App",
    ctaType: "mobile",
    platformNote: "Clients submit briefs and track makeovers via the StyleSync mobile app.",
  },
  {
    id: "designer",
    title: "For Interior Designers",
    badge: "Web Workspace Portal",
    tagline: "Receive curated, high-intent clients without administrative friction.",
    description: "Purpose-built for independent studios seeking qualified project briefs matched to their aesthetic signature.",
    keyBenefits: [
      "Algorithmic matching to homeowners with verified project scopes",
      "Automated specification and itemized quotation builders",
      "Milestone-based progress and payment status tracking",
    ],
    ctaText: "Join as Designer",
    ctaType: "web",
    platformNote: "Access your design studio, moodboards, and contract tools on web.",
  },
  {
    id: "coordinator",
    title: "For Project Coordinators",
    badge: "Operations Command",
    tagline: "Real-time visibility across logistics, vendors, and milestone schedules.",
    description: "Centralized operational hub to coordinate multi-trade delivery schedules and on-site handoffs.",
    keyBenefits: [
      "Unified project timeline with proactive delay risk alerts",
      "Direct freight and material tracking across furniture suppliers",
      "Digital verification console for milestone inspections and punch lists",
    ],
    ctaText: "Coordinator Log In",
    ctaType: "web",
    platformNote: "Manage multi-site operations and vendor logistics on the desktop web suite.",
  },
  {
    id: "admin",
    title: "For Platform Admins",
    badge: "Governance & Quality",
    tagline: "Enforce marketplace integrity, verification, and code-based rules.",
    description: "Comprehensive governance tools to calibrate regional rate standards and audit platform activity.",
    keyBenefits: [
      "Multi-stage designer vetting and credential verification",
      "Rule engine configurator for regional labor and material baselines",
      "Full audit trail for every contract change and milestone",
    ],
    ctaText: "Admin Console",
    ctaType: "web",
    platformNote: "Enterprise compliance, milestone controls, and system rules management.",
  },
];

export const CASE_STUDIES: CaseStudy[] = [
  {
    id: "japandi-sanctuary",
    title: "The Pacific Heights Sanctuary",
    location: "San Francisco, CA",
    roomType: "Living & Dining Makeover",
    designerName: "Kenji Mori",
    designerStudio: "Studio Kanso",
    matchScore: 98,
    calculatedBudget: "$18,400",
    finalBudget: "$18,400",
    timelineWeeks: 4,
    afterImage: "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1200&q=80",
    beforeImage: "https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80",
    highlight: "Custom white oak slat partitions, travertine cocktail table, and bespoke linen sectional.",
    tags: ["Japandi", "Living Room", "Custom Millwork"],
    clientQuote: "StyleSync eliminated every ounce of renovation anxiety. The quote was calculated down to the last dollar, and our designer Kenji was the exact aesthetic match we dreamed of.",
  },
  {
    id: "tribeca-loft",
    title: "Tribeca Cast-Iron Loft",
    location: "New York, NY",
    roomType: "Open-Concept Lounge & Library",
    designerName: "Claire Dupont",
    designerStudio: "Atelier Vane",
    matchScore: 96,
    calculatedBudget: "$31,200",
    finalBudget: "$31,200",
    timelineWeeks: 6,
    afterImage: "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80",
    beforeImage: "https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1200&q=80",
    highlight: "Restored ceiling timbers, matte patinated steel shelving, bouclé swivel chairs, and architectural cove lighting.",
    tags: ["Warm Industrial", "Great Room", "Heritage"],
    clientQuote: "The material delivery tracking meant we never had boxes sitting in our hallway for weeks. Every delivery synced perfectly with the carpentry milestone.",
  },
  {
    id: "austin-suite",
    title: "Barton Hills Primary Suite",
    location: "Austin, TX",
    roomType: "Bedroom & Reading Sanctuary",
    designerName: "Elena Rostova",
    designerStudio: "Rostova Design Group",
    matchScore: 97,
    calculatedBudget: "$12,850",
    finalBudget: "$12,850",
    timelineWeeks: 3,
    afterImage: "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80",
    beforeImage: "https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=1200&q=80",
    highlight: "Limewash walls, custom upholstered channel headboard, raw travertine sconces, and natural flax linens.",
    tags: ["Organic Minimalist", "Primary Bedroom", "Acoustic"],
    clientQuote: "Having the dual sign-off with our project coordinator gave us so much confidence. Nothing was paid until Elena and our coordinator checked every stitch.",
  },
];

export const TRUST_PILLARS = [
  {
    title: "Deterministic Rule Engine",
    subtitle: "Zero Guesswork or AI Hallucinations",
    description: "Every designer recommendation, square-foot price calculation, and material schedule is computed using rigid deterministic constraints — never loose generative AI promises.",
    icon: "Cpu",
  },
  {
    title: "Dual Human Approval at Every Stage",
    subtitle: "Client & Coordinator Two-Key Sign-Off",
    description: "Milestones are approved exclusively when both the client and the dedicated StyleSync Project Coordinator inspect and digitally approve the physical work.",
    icon: "ShieldCheck",
  },
  {
    title: "Calculated Itemized Quotes",
    subtitle: "Trade-Grounded Itemized Pricing",
    description: "Our proprietary formula calculates material MSRP, supplier discounts, regional trade labor brackets, and logistics upfront, contractually locking the budget ceiling.",
    icon: "Calculator",
  },
  {
    title: "Immutable Audit Trail",
    subtitle: "Full Accountability & Milestone Ledger",
    description: "Every specification change, material delivery confirmation, and milestone photo is cryptographically recorded with a tamper-evident audit history.",
    icon: "FileCheck",
  },
];

export const TESTIMONIALS: Testimonial[] = [
  {
    id: "1",
    author: "Julian & Sarah Vance",
    role: "Homeowners & Mobile App Clients",
    location: "Pacific Heights, SF",
    rating: 5,
    quote: "We had two nightmare renovations before StyleSync. Being able to see our Japandi makeover broken into four clear milestones with locked budgets was revolutionary. The mobile app gave us daily photo updates.",
    project: "Pacific Heights Living Room Makeover",
    avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80",
  },
  {
    id: "2",
    author: "Kenji Mori",
    role: "Principal Interior Designer",
    location: "Studio Kanso, Los Angeles",
    rating: 5,
    quote: "As a designer, 50% of my time used to be chasing clients for unpaid invoices and negotiating scope creep. StyleSync locks in structured milestone sign-offs. I can focus 100% on the art of spatial design.",
    project: "24 Verified Makeovers Completed",
    avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80",
  },
  {
    id: "3",
    author: "Marissa Chen",
    role: "Senior Project Coordinator",
    location: "StyleSync Operations, New York",
    rating: 5,
    quote: "The web operations suite lets me monitor delivery ETAs from 14 different furniture manufacturers simultaneously. When a custom table was delayed by customs, our system alerted us 10 days before staging.",
    project: "98 Projects Coordinated in 2024",
    avatar: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=80",
  },
];

export const FAQ_ITEMS = [
  {
    q: "How does the deterministic match-score engine work?",
    a: "When clients submit room photos and answer spatial preferences in the mobile app, our engine analyzes architectural style, dimensions, lighting orientation, desired budget, and timeline. It compares these directly with our vetted designers' verified past work, regional availability, and live project load.",
  },
  {
    q: "Why do clients use a mobile app while designers and staff use the web?",
    a: "Clients need a lightweight, pocket-friendly experience: taking room photos with their smartphone camera, scanning dimensions, receiving push notifications when materials arrive, and tapping to approve milestones. Designers, project coordinators, and administrators need high-resolution desktop workspaces for CAD files, multi-vendor procurement sheets, and compliance auditing.",
  },
  {
    q: "How does StyleSync guarantee the budget will not creep?",
    a: "Unlike traditional contractor estimates that rely on vague allowances, StyleSync's quotation engine uses real trade catalogs and regional labor rates to calculate an itemized price. Once agreed, this budget is contractually locked. If any unexpected structural change is requested, it must pass dual human approval before any extra cost is incurred.",
  },
  {
    q: "What does 'dual human approval' mean?",
    a: "At every milestone (e.g. initial 3D plans, material delivery, completed millwork), milestones are not marked complete until both the client and their dedicated StyleSync Project Coordinator inspect photos and sign off. This prevents unilateral approvals and ensures professional quality standards.",
  },
];
