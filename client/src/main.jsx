import './lib/api'; // configureApi runs before anything else
import './styles.css'; // the design system stylesheet (prototype styles.css, verbatim)
import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@rhino-dev/rhino-react';
import App from './App';

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, refetchOnWindowFocus: false } },
});

// A blank #root is the hardest failure to diagnose: the bundle loads 200 and
// mounts nothing, with no console error. Render a visible fallback on any
// bootstrap failure instead of leaving the user on a white screen.
const showFatal = (error) => {
  const root = document.getElementById('root');
  if (!root) return;
  root.innerHTML = `<pre style="padding:1rem;font-family:monospace;color:#b91c1c">DriveFlow failed to start\n\n${
    error?.stack ?? error
  }</pre>`;
};

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error) {
    // eslint-disable-next-line no-console
    console.error('DriveFlow render error', error);
  }

  render() {
    if (this.state.error) {
      return (
        <pre style={{ padding: '1rem', color: '#b91c1c', fontFamily: 'monospace' }}>
          {`DriveFlow hit an unexpected error\n\n${this.state.error?.stack ?? this.state.error}`}
        </pre>
      );
    }
    return this.props.children;
  }
}

try {
  ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
      <ErrorBoundary>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <App />
          </AuthProvider>
        </QueryClientProvider>
      </ErrorBoundary>
    </React.StrictMode>,
  );
} catch (error) {
  showFatal(error);
}
