import React from "react";

interface Props {
  children: React.ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export default class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error("ErrorBoundary caught an error:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          padding: 32,
          maxWidth: 600,
          margin: "40px auto",
          fontFamily: "system-ui, -apple-system, sans-serif",
          backgroundColor: "#fff",
          borderRadius: 8,
          boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
          border: "1px solid #fee2e2"
        }}>
          <h2 style={{ color: "#dc2626", marginTop: 0 }}>Something went wrong</h2>
          <p style={{ color: "#4b5563" }}>
            An unexpected error occurred in the UI interface. The application prevented a crash.
          </p>
          <pre style={{
            backgroundColor: "#f9fafb",
            padding: 12,
            borderRadius: 6,
            fontSize: 13,
            overflowX: "auto",
            color: "#991b1b"
          }}>
            {this.state.error?.toString()}
          </pre>
          <button
            onClick={() => {
              this.setState({ hasError: false, error: null });
              window.location.reload();
            }}
            style={{
              marginTop: 16,
              padding: "8px 16px",
              backgroundColor: "#2563eb",
              color: "#fff",
              border: "none",
              borderRadius: 6,
              cursor: "pointer",
              fontWeight: 500
            }}
          >
            Reload Application
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}