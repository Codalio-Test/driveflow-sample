// configureApi must run exactly once, before anything renders. Imported first
// from src/main.jsx so every hook sees a configured axios instance.
import { configureApi } from '@rhino-dev/rhino-react';

configureApi({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  // DriveFlow is organisation-scoped: /api/{org}/{model}. The org slug is
  // carried in storage by useAuth().setOrganization() after login — the browser
  // URL stays flat (no /:baseOwnerId segment).
  tenancy: 'path',
  onUnauthorized: () => {
    // Token already cleared by the client; the router sends the user to /login.
    if (typeof window !== 'undefined' && !window.location.pathname.startsWith('/login')) {
      window.location.assign('/login');
    }
  },
  onForbidden: (error) => {
    // Authenticated but not permitted — keep the session, surface the message.
    // eslint-disable-next-line no-console
    console.warn('Forbidden:', error?.response?.data?.message ?? 'permission denied');
  },
});

export default true;
