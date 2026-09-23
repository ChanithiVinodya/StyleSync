import React, { useState, useEffect } from 'react';
import { 
  Building2, 
  Layers, 
  ArrowLeft, 
  Sparkles, 
  ShieldAlert, 
  ShieldCheck, 
  ExternalLink,
  UserCheck
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { DesignerProfile, UpdateDesignerProfileRequest, CreatePortfolioItemRequest } from '../types';
import { designerApi } from '../services/designerApi';
import { CapacityStatusCard } from './CapacityStatusCard';
import { DesignerProfileForm } from './DesignerProfileForm';
import { PortfolioManager } from './PortfolioManager';

export const DesignerStudioPortal: React.FC = () => {
  const [profile, setProfile] = useState<DesignerProfile | null>(null);
  const [activeTab, setActiveTab] = useState<'profile' | 'portfolio'>('profile');
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // Load profile (default designer ID 1 or active)
  useEffect(() => {
    loadProfile(1);
  }, []);

  const loadProfile = async (id: number) => {
    try {
      setIsLoading(true);
      const data = await designerApi.getProfile(id);
      setProfile(data);
    } catch (err) {
      console.error('Failed to load profile:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSaveProfile = async (updated: UpdateDesignerProfileRequest) => {
    if (!profile) return;
    try {
      setIsSaving(true);
      const saved = await designerApi.updateProfile(profile.id, updated);
      setProfile(saved);
    } finally {
      setIsSaving(false);
    }
  };

  const handleAddPortfolioItem = async (request: CreatePortfolioItemRequest) => {
    if (!profile) return;
    try {
      setIsSaving(true);
      const newItem = await designerApi.addPortfolioItem(profile.id, request);
      setProfile(prev => prev ? {
        ...prev,
        portfolioItems: [newItem, ...prev.portfolioItems]
      } : null);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeletePortfolioItem = async (itemId: number) => {
    if (!profile) return;
    try {
      setIsSaving(true);
      await designerApi.deletePortfolioItem(profile.id, itemId);
      setProfile(prev => prev ? {
        ...prev,
        portfolioItems: prev.portfolioItems.filter(item => item.id !== itemId)
      } : null);
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading || !profile) {
    return (
      <div className="min-h-screen bg-[#FBF9F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] flex items-center justify-center p-6">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 rounded-full border-2 border-[#C48A36] border-t-transparent animate-spin" />
          <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">Loading Designer Studio...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#FBF9F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] transition-colors duration-500 pb-20">
      {/* Top Navigation */}
      <header className="sticky top-0 z-40 bg-[#FAF8F5]/90 dark:bg-[#161311]/90 backdrop-blur-md border-b border-[#E7E1D7] dark:border-[#2C2723] px-4 sm:px-8 py-3.5">
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Link
              to="/"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold text-[#57534E] dark:text-[#A8A29E] bg-[#EFEAE1] dark:bg-[#201D1A] hover:bg-[#E4DDD1] dark:hover:bg-[#2C2723] border border-[#E2D8C9] dark:border-[#382F26] transition-colors"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Back to Home</span>
            </Link>
            <div className="h-4 w-px bg-[#E7E1D7] dark:border-[#2C2723] hidden sm:block" />
            <span className="font-serif text-base font-semibold text-[#1C1917] dark:text-[#FAF8F5] hidden sm:inline">
              Designer Studio Portal
            </span>
          </div>

          {/* Quick Profile Switcher for Testing Capacity States */}
          <div className="flex items-center gap-2">
            <span className="text-[11px] text-[#78716C] dark:text-[#A8A29E] hidden md:inline">
              Sample Designer:
            </span>
            <select
              value={profile.id}
              onChange={e => loadProfile(parseInt(e.target.value, 10))}
              className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#F4F0E8] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723] text-[#1C1917] dark:text-[#FAF8F5] cursor-pointer"
            >
              <option value={1}>1. Jayawardena Interiors (Under Capacity - 1/3)</option>
              <option value={2}>2. Studio Amara (AT CAPACITY - 2/2)</option>
              <option value={3}>3. Urban Loft Atelier (Under Capacity - 2/4)</option>
              <option value={4}>4. Artisan Living Spaces (AT CAPACITY - 3/3)</option>
              <option value={5}>5. Wickrama Spatial Concepts (Suspended)</option>
              <option value={7}>7. Greenline Eco Spaces (Draft)</option>
            </select>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 space-y-8">
        {/* Studio Title Banner */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="space-y-1">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] text-[11px] font-semibold text-[#925C18] dark:text-[#E8A849]">
              <UserCheck className="w-3.5 h-3.5" />
              <span>Designer Role Verified • ID #{profile.id}</span>
            </div>
            <h1 className="font-serif text-2xl sm:text-3xl font-medium text-[#1C1917] dark:text-[#FAF8F5]">
              {profile.displayName}
            </h1>
            <p className="text-xs sm:text-sm text-[#78716C] dark:text-[#A8A29E] max-w-2xl">
              Manage your published aesthetics, rates per square foot, and showcase room transformations.
            </p>
          </div>
        </div>

        {/* 1. Read-Only Capacity Guard Card */}
        <CapacityStatusCard profile={profile} />

        {/* 2. Tabs Navigation */}
        <div className="flex border-b border-[#E7E1D7] dark:border-[#2C2723]">
          <button
            type="button"
            onClick={() => setActiveTab('profile')}
            className={`px-5 py-3 text-sm font-semibold border-b-2 transition-all cursor-pointer ${
              activeTab === 'profile'
                ? 'border-[#C48A36] text-[#925C18] dark:text-[#E8A849]'
                : 'border-transparent text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
            }`}
          >
            Profile & Pricing Details
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('portfolio')}
            className={`px-5 py-3 text-sm font-semibold border-b-2 transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === 'portfolio'
                ? 'border-[#C48A36] text-[#925C18] dark:text-[#E8A849]'
                : 'border-transparent text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
            }`}
          >
            <span>Portfolio Showcase</span>
            <span className="px-2 py-0.5 rounded-full text-[10px] bg-[#EFEAE1] dark:bg-[#2C2723] font-bold">
              {profile.portfolioItems.length}
            </span>
          </button>
        </div>

        {/* 3. Tab Content */}
        {activeTab === 'profile' ? (
          <DesignerProfileForm
            initialProfile={profile}
            onSave={handleSaveProfile}
            isLoading={isSaving}
          />
        ) : (
          <PortfolioManager
            designerId={profile.id}
            items={profile.portfolioItems}
            onAddItem={handleAddPortfolioItem}
            onDeleteItem={handleDeletePortfolioItem}
            isLoading={isSaving}
          />
        )}
      </main>
    </div>
  );
};
