export type PersonaRole = 'client' | 'designer' | 'coordinator' | 'admin';

export interface PersonaInfo {
  id: PersonaRole;
  title: string;
  badge: string;
  tagline: string;
  description: string;
  keyBenefits: string[];
  ctaText: string;
  ctaType: 'mobile' | 'web';
  platformNote: string;
}

export interface CaseStudy {
  id: string;
  title: string;
  location: string;
  roomType: string;
  designerName: string;
  designerStudio: string;
  matchScore: number;
  calculatedBudget: string;
  finalBudget: string;
  timelineWeeks: number;
  afterImage: string;
  beforeImage: string;
  highlight: string;
  tags: string[];
  clientQuote: string;
}

export interface Testimonial {
  id: string;
  author: string;
  role: string;
  location: string;
  rating: number;
  quote: string;
  project: string;
  avatar: string;
}

export interface FeaturePillar {
  id: string;
  number: string;
  title: string;
  subtitle: string;
  description: string;
  bulletPoints: string[];
  highlightMetric: string;
}

export interface HeroStat {
  value: string;
  label: string;
  subtext: string;
}

export interface HeroData {
  eyebrow: string;
  title: string;
  subtitle: string;
  stats: HeroStat[];
}
