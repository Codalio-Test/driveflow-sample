import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { useOrganization, useAuth, api } from '@rhino-dev/rhino-react';

// ---------------------------------------------------------------------------
// AppOwnerProvider — owner context for FLAT routes.
//
// The approved prototype uses flat browser paths (/dashboard, /admin/fleet/...)
// with no /:baseOwnerId segment, so the organization must come from context.
// Rhino v4's upstream owner provider assumes the org id is in the URL
// (useParams) and "repairs" a URL without it by navigating to /<orgId>/ — which
// matches no flat route and bounces the user home with no console error.
//
// This provider instead resolves the organization from the signed-in session
// (the slug useAuth() persisted at login) and asks the tenant-scoped /me
// endpoint for the caller's roles in that organization. Nothing here rewrites
// the URL.
// ---------------------------------------------------------------------------

export const AppOwnerContext = createContext({
  organizationSlug: null,
  organization: null,
  user: null,
  roles: [],
  roleSlugs: [],
  customerProfileId: null,
  hasRole: () => false,
  isLoading: true,
  refetch: () => {},
});

export const useAppOwner = () => useContext(AppOwnerContext);

export const AppOwnerProvider = ({ children }) => {
  const { isAuthenticated } = useAuth();
  const organizationSlug = useOrganization();
  const [state, setState] = useState({
    user: null,
    organization: null,
    roles: [],
    roleSlugs: [],
    customerProfileId: null,
    isLoading: false,
    // Nothing has been resolved yet. Skipping this flag is what makes a deep
    // link flash-redirect: on the very first render, before the effect runs,
    // "not loading with no roles" would look like "no access" and the role gate
    // would bounce the user to the home route.
    resolved: false,
    error: null,
  });
  const [nonce, setNonce] = useState(0);

  useEffect(() => {
    let cancelled = false;

    if (!isAuthenticated || !organizationSlug) {
      setState({
        user: null,
        organization: null,
        roles: [],
        roleSlugs: [],
        customerProfileId: null,
        isLoading: false,
        resolved: true,
        error: null,
      });
      return () => {
        cancelled = true;
      };
    }

    setState((prev) => ({ ...prev, isLoading: true, error: null }));

    api
      .get(`/${organizationSlug}/me`)
      .then((response) => {
        if (cancelled) return;
        const data = response.data ?? {};
        setState({
          user: data.user ?? null,
          organization: data.organization ?? null,
          roles: data.roles ?? [],
          roleSlugs: data.role_slugs ?? [],
          customerProfileId: data.customer_profile_id ?? null,
          isLoading: false,
          resolved: true,
          error: null,
        });
      })
      .catch((error) => {
        if (cancelled) return;
        setState({
          user: null,
          organization: null,
          roles: [],
          roleSlugs: [],
          customerProfileId: null,
          isLoading: false,
          resolved: true,
          error,
        });
      });

    return () => {
      cancelled = true;
    };
  }, [isAuthenticated, organizationSlug, nonce]);

  // Until the first resolution settles, a signed-in session is "still loading"
  // rather than "no roles" — the role gates depend on that distinction.
  const mustResolve = isAuthenticated && Boolean(organizationSlug);
  const isLoading = state.isLoading || (mustResolve && !state.resolved);

  const value = useMemo(() => {
    const slugs = state.roleSlugs.map((slug) => String(slug).toLowerCase());
    return {
      ...state,
      isLoading,
      organizationSlug,
      // Gate on a POSITIVE match: while roles are loading hasRole() is false for
      // everybody, so callers must treat isLoading as "not yet privileged"
      // rather than negating this.
      hasRole: (name) => (slugs.length === 0 ? false : slugs.includes(String(name).toLowerCase())),
      refetch: () => setNonce((n) => n + 1),
    };
  }, [state, organizationSlug, isLoading]);

  return <AppOwnerContext.Provider value={value}>{children}</AppOwnerContext.Provider>;
};

export default AppOwnerProvider;
