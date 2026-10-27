import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '@rhino-dev/rhino-react';
import { useAppOwner } from '@/contexts/AppOwnerProvider';

// Role homes come from .codalio/ui-handoff.json#shared.role_home.
const ROLE_HOME = {
  customer: '/account/dashboard',
  counter_agent: '/counter/departures',
  fleet_manager: '/admin/fleet/matrix',
};

/** Every authenticated route passes through here; unauthenticated → /login. */
export const AuthenticatedRoute = ({ children }) => {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) return <Navigate to="/login" replace />;

  // NOTE: no upstream owner provider here. Its /:baseOwnerId lookup would
  // rewrite these flat URLs to /<orgId>/ and bounce the user home silently.
  return children ?? <Outlet />;
};

/** The home of whichever of the signed-in user's roles comes first. */
export const roleHomeFor = (hasRole) => {
  const role = Object.keys(ROLE_HOME).find((key) => hasRole(key));
  return role ? ROLE_HOME[role] : '/';
};

/**
 * Role gate. A page with roles: [] is visible to every authenticated user.
 *
 * The check is positive-only and treats "still loading" as "not yet
 * privileged": while roles resolve, an operator must not be shown owner UI.
 * The fallback is the visitor's OWN role home — never the home of the role that
 * was denied, which would redirect in a loop.
 */
export const RoleProtectedRoute = ({ roles = [], children }) => {
  const { hasRole, isLoading } = useAppOwner();
  const { isAuthenticated } = useAuth();
  const location = useLocation();

  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (roles.length === 0) return children ?? <Outlet />;
  if (isLoading) return <p>Resolving your access…</p>;

  if (roles.some((role) => hasRole(role))) return children ?? <Outlet />;

  const fallback = roleHomeFor(hasRole);
  if (fallback === location.pathname) return children ?? <Outlet />;

  return <Navigate to={fallback} replace />;
};

export const roleHome = (role) => ROLE_HOME[role] ?? null;
