import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import QuotesPage from './pages/QuotesPage';
import ContractsPage from './pages/ContractsPage';
import ErrorBoundary from './components/ErrorBoundary';
import './styles/theme.css';
import { FileText, FileCheck, ArrowLeft } from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';

export const QuotesContractsPage: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  const isContractsPath = location.pathname.includes('/contracts');
  const [activeTab, setActiveTab] = useState<'quotes' | 'contracts'>(
    isContractsPath ? 'contracts' : 'quotes'
  );

  const handleTabChange = (tab: 'quotes' | 'contracts') => {
    setActiveTab(tab);
  };

  return (
    <ErrorBoundary>
      <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5]">
        {/* Module Header Bar */}
        <header className="sticky top-0 z-30 bg-[#FAF8F5]/90 dark:bg-[#12100E]/90 backdrop-blur-md border-b border-[#E7E1D7] dark:border-[#2E2824] px-6 py-4">
          <div className="max-w-7xl mx-auto flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="flex items-center gap-4">
              <button
                onClick={() => navigate(-1)}
                className="p-2 rounded-xl text-[#57534E] dark:text-[#A8A29E] hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition-colors"
                title="Go Back"
              >
                <ArrowLeft className="w-5 h-5" />
              </button>
              <Logo variant="auto" size="sm" />
              <div>
                <h1 className="font-serif text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                  Quotes & Contracts Portal
                </h1>
                <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                  Scope estimation, itemized quotes, & binding legal agreements
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              {/* Tab Switcher */}
              <div className="flex items-center p-1 bg-[#EFEAE1] dark:bg-[#201C19] rounded-2xl border border-[#E7E1D7] dark:border-[#2E2824]">
                <button
                  onClick={() => handleTabChange('quotes')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all ${
                    activeTab === 'quotes'
                      ? 'bg-white dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] shadow-xs'
                      : 'text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
                  }`}
                >
                  <FileText className="w-4 h-4 text-[#C48A36]" />
                  <span>Quotes</span>
                </button>
                <button
                  onClick={() => handleTabChange('contracts')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all ${
                    activeTab === 'contracts'
                      ? 'bg-white dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] shadow-xs'
                      : 'text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
                  }`}
                >
                  <FileCheck className="w-4 h-4 text-[#C48A36]" />
                  <span>Contracts</span>
                </button>
              </div>
              <GlassThemeToggle />
            </div>
          </div>
        </header>

        {/* Content Body */}
        <main className="max-w-7xl mx-auto p-4 sm:p-8">
          {activeTab === 'quotes' ? (
            <QuotesPage onGoToContracts={() => setActiveTab('contracts')} />
          ) : (
            <ContractsPage />
          )}
        </main>
      </div>
    </ErrorBoundary>
  );
};

export default QuotesContractsPage;
