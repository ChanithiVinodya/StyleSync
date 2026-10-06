import { BrowserRouter, Routes, Route, NavLink } from "react-router-dom";
import QuotesPage from "./pages/QuotesPage";
import ContractsPage from "./pages/ContractsPage";
import ErrorBoundary from "./components/ErrorBoundary";
import "./styles/theme.css";

function Header() {
  return (
    <header className="qc-navbar">
      <div className="qc-navbar__brand">
        <div className="qc-navbar__logo">SS</div>
        <span>Interior Design & Room Makeover Marketplace</span>
      </div>
      <nav className="qc-navbar__nav">
        <NavLink
          to="/quotes"
          className={({ isActive }) =>
            `qc-nav-link ${isActive ? "qc-nav-link--active" : ""}`
          }
        >
          Quotes
        </NavLink>
        <NavLink
          to="/contracts"
          className={({ isActive }) =>
            `qc-nav-link ${isActive ? "qc-nav-link--active" : ""}`
          }
        >
          Contracts
        </NavLink>
      </nav>
    </header>
  );
}

function App() {
  return (
    <ErrorBoundary>
      <BrowserRouter>
        <Header />
        <Routes>
          <Route path="/quotes" element={<QuotesPage />} />
          <Route path="/contracts" element={<ContractsPage />} />
          <Route path="*" element={<QuotesPage />} />
        </Routes>
      </BrowserRouter>
    </ErrorBoundary>
  );
}

export default App;