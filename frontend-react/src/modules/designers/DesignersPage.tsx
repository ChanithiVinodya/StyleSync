import React, { useState, useEffect } from 'react';
import { useParams, useSearchParams, useNavigate } from 'react-router-dom';
import { DesignerDirectoryPage } from './pages/DesignerDirectoryPage';
import { DesignerProfileGalleryPage } from './pages/DesignerProfileGalleryPage';
import { DesignerStudioPortal } from './components/DesignerStudioPortal';

export default function DesignersPage() {
  const { id } = useParams<{ id?: string }>();
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();

  // Internal state allows smooth tab switching and back navigation
  const [selectedDesignerId, setSelectedDesignerId] = useState<number | null>(
    id ? parseInt(id, 10) : searchParams.get('designerId') ? parseInt(searchParams.get('designerId')!, 10) : null
  );
  const [activeView, setActiveView] = useState<'directory' | 'profile' | 'studio'>(
    window.location.pathname.includes('/studio') || searchParams.get('view') === 'studio'
      ? 'studio'
      : (id || searchParams.get('designerId'))
      ? 'profile'
      : 'directory'
  );

  useEffect(() => {
    if (id) {
      const parsed = parseInt(id, 10);
      if (!isNaN(parsed)) {
        setSelectedDesignerId(parsed);
        setActiveView('profile');
      }
    } else if (window.location.pathname.includes('/studio') || searchParams.get('view') === 'studio') {
      setActiveView('studio');
    } else {
      const designerIdParam = searchParams.get('designerId');
      if (designerIdParam) {
        setSelectedDesignerId(parseInt(designerIdParam, 10));
        setActiveView('profile');
      } else {
        setActiveView('directory');
      }
    }
  }, [id, searchParams]);

  const handleSelectDesigner = (designerId: number) => {
    setSelectedDesignerId(designerId);
    setActiveView('profile');
    setSearchParams({ designerId: designerId.toString() });
  };

  const handleBackToDirectory = () => {
    setSelectedDesignerId(null);
    setActiveView('directory');
    setSearchParams({});
  };

  const handleOpenStudio = () => {
    setActiveView('studio');
    setSearchParams({ view: 'studio' });
  };

  const handleExitStudio = () => {
    setActiveView('directory');
    setSearchParams({});
  };

  if (activeView === 'studio') {
    return (
      <div className="relative">
        <div className="bg-[#1C1917] text-[#FAF8F5] px-4 py-2.5 flex items-center justify-between text-xs border-b border-[#38312B]">
          <span className="font-semibold text-[#E8A849]">Designer Studio Management Workspace</span>
          <button
            onClick={handleExitStudio}
            className="underline hover:text-white transition-colors cursor-pointer"
          >
            ← Exit to Public Directory
          </button>
        </div>
        <DesignerStudioPortal />
      </div>
    );
  }

  if (activeView === 'profile' && selectedDesignerId) {
    return (
      <DesignerProfileGalleryPage
        designerId={selectedDesignerId}
        onBack={handleBackToDirectory}
        onOpenStudio={handleOpenStudio}
      />
    );
  }

  return (
    <DesignerDirectoryPage
      onSelectDesigner={handleSelectDesigner}
      onOpenStudio={handleOpenStudio}
    />
  );
}
