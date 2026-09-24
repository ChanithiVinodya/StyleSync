import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { ThemeProvider } from './context/ThemeContext'
import LandingPage from './pages/LandingPage'
import DesignersPage from './modules/designers/DesignersPage'
import ProjectRequestsPage from './modules/project-requests/ProjectRequestsPage'
import QuotesContractsPage from './modules/quotes-contracts/QuotesContractsPage'
import ProjectExecutionPage from './modules/project-execution/ProjectExecutionPage'

export default function App() {
  return (
    <ThemeProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          {/* Student 1 owns this route */}
          <Route path="/designers" element={<DesignersPage />} />
          <Route path="/designers/:id" element={<DesignersPage />} />
          <Route path="/designers/studio" element={<DesignersPage />} />
          {/* Student 2 owns this route */}
          <Route path="/project-requests" element={<ProjectRequestsPage />} />
          {/* Student 3 owns this route */}
          <Route path="/quotes-contracts" element={<QuotesContractsPage />} />
          {/* Student 4 owns this route */}
          <Route path="/project-execution" element={<ProjectExecutionPage />} />
        </Routes>
      </BrowserRouter>
    </ThemeProvider>
  )
}
