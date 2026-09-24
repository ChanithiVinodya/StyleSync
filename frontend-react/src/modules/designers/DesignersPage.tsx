import React, { useState, useEffect } from 'react';
import { useParams, useSearchParams, useNavigate, useLocation } from 'react-router-dom';
import { DesignerDirectoryPage } from './pages/DesignerDirectoryPage';
import { DesignerProfileGalleryPage } from './pages/DesignerProfileGalleryPage';
import { DesignerPortfolioGalleryPage } from './pages/DesignerPortfolioGalleryPage';
import { AdminDesignerGovernancePage } from './pages/AdminDesignerGovernancePage';
import { DesignerStudioPortal } from './components/DesignerStudioPortal';

interface DesignersPageProps {
  initialRole?: string;
}

export default function DesignersPage({ initialRole = 'admin' }: DesignersPageProps) {
  const { id } = useParams<{ id?: string }>();
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();
  const location = useLocation();

  const [currentUserRole, setCurrentUserRole] = useState<string>(
    searchParams.get('role') || initialRole
  );

  // Internal state allows smooth tab switching and back navigation
  const [selectedDesignerId, setSelectedDesignerId] = useState<number | null>(
    id ? parseInt(id, 10) : searchParams.get('designerId') ? parseInt(searchParams.get('designerId')!, 10) : null
  );
  
  const determineInitialView = (): 'directory' | 'profile' | 'gallery' | 'studio' | 'admin' => {
    if (location.pathname.includes('/admin') || searchParams.get('view') === 'admin') {
      return 'admin';
    }
    if (location.pathname.includes('/studio') || searchParams.get('view') === 'studio') {
      return 'studio';
    }
    if (location.pathname.includes('/gallery') || searchParams.get('view') === 'gallery') {
      return 'gallery';
    }
    if (id || searchParams.get('designerId')) {
      return 'profile';
    }
    return 'directory';
  };

  const [activeView, setActiveView] = useState<'directory' | 'profile' | 'gallery' | 'studio' | 'admin'>(determineInitialView);

  useEffect(() => {
    if (location.pathname.includes('/admin') || searchParams.get('view') === 'admin') {
      setActiveView('admin');
    } else if (id) {
      const parsed = parseInt(id, 10);
      if (!isNaN(parsed)) {
        setSelectedDesignerId(parsed);
        if (location.pathname.includes('/gallery') || searchParams.get('view') === 'gallery') {
          setActiveView('gallery');
        } else {
          setActiveView('profile');
        }
      }
    } else if (location.pathname.includes('/studio') || searchParams.get('view') === 'studio') {
      setActiveView('studio');
    } else {
      const designerIdParam = searchParams.get('designerId');
      if (designerIdParam) {
        setSelectedDesignerId(parseInt(designerIdParam, 10));
        if (searchParams.get('view') === 'gallery') {
          setActiveView('gallery');
        } else {
          setActiveView('profile');
        }
      } else {
        setActiveView('directory');
      }
    }
  }, [id, searchParams, location.pathname]);

  const handleSelectDesigner = (designerId: number) => {
    setSelectedDesignerId(designerId);
    setActiveView('profile');
    setSearchParams({ designerId: designerId.toString() });
  };

  const handleOpenGallery = (designerId?: number) => {
    const targetId = designerId || selectedDesignerId;
    if (targetId) {
      setSelectedDesignerId(targetId);
      setActiveView('gallery');
      setSearchParams({ designerId: targetId.toString(), view: 'gallery' });
    }
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

  const handleOpenAdmin = () => {
    setActiveView('admin');
    setSearchParams({ view: 'admin' });
  };

  const handleExitToDirectory = () => {
    setActiveView('directory');
    setSearchParams({});
  };

  if (activeView === 'admin') {
    return (
      <AdminDesignerGovernancePage
        userRole={currentUserRole}
        onBack={handleExitToDirectory}
        onRoleChange={newRole => setCurrentUserRole(newRole)}
      />
    );
  }

  if (activeView === 'studio') {
    return (
      <div className="relative">
        <div className="bg-[#1C1917] text-[#FAF8F5] px-4 py-2.5 flex items-center justify-between text-xs border-b border-[#38312B]">
          <span className="font-semibold text-[#E8A849]">Designer Studio Management Workspace</span>
          <button
            onClick={handleExitToDirectory}
            className="underline hover:text-white transition-colors cursor-pointer"
          >
            ← Exit to Public Directory
          </button>
        </div>
        <DesignerStudioPortal />
      </div>
    );
  }

  if (activeView === 'gallery' && selectedDesignerId) {
    return (
      <DesignerPortfolioGalleryPage
        designerId={selectedDesignerId}
        onBack={handleBackToDirectory}
        onViewProfile={() => {
          setActiveView('profile');
          setSearchParams({ designerId: selectedDesignerId.toString() });
        }}
      />
    );
  }

  if (activeView === 'profile' && selectedDesignerId) {
    return (
      <DesignerProfileGalleryPage
        designerId={selectedDesignerId}
        onBack={handleBackToDirectory}
        onOpenStudio={handleOpenStudio}
        onOpenProofOfWork={() => handleOpenGallery(selectedDesignerId)}
      />
    );
  }

  return (
    <DesignerDirectoryPage
      onSelectDesigner={handleSelectDesigner}
      onOpenStudio={handleOpenStudio}
      onOpenAdmin={handleOpenAdmin}
    />
  );
}
