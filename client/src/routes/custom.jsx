/* DriveFlow route tree.
 *
 * Route paths, order and hierarchy mirror the approved prototype's App.tsx 1:1
 * (.codalio/ui-prototype/files/App.tsx). The shell is the prototype's Layout;
 * every page is the vendored prototype page. Only the access tiers come from
 * .codalio/ui-handoff.json (flat routing scheme — no /:baseOwnerId segment).
 *
 * A catch-all falls back to "/" because the Codalio preview iframe is loaded at
 * /<org_id>/<product_id>, a URL no prototype route matches.
 */
import { Navigate, Route } from 'react-router-dom';
import { AppOwnerProvider } from '@/contexts/AppOwnerProvider';
import { RoleProtectedRoute } from './guards';
import Layout from '@/components/Layout';

import Landing from '@/pages/Landing';
import Booking from '@/pages/Booking';
import Vehicles from '@/pages/Vehicles';
import BookingConfigure from '@/pages/BookingConfigure';
import BookingConfirmation from '@/pages/BookingConfirmation';
import BookingCheckout from '@/pages/BookingCheckout';
import Signup from '@/pages/Signup';
import Login from '@/pages/Login';
import AccountDashboard from '@/pages/AccountDashboard';
import AccountBookings from '@/pages/AccountBookings';
import CounterAgreement from '@/pages/CounterAgreement';
import Counter from '@/pages/Counter';
import CounterDepartures from '@/pages/CounterDepartures';
import CounterCheckout from '@/pages/CounterCheckout';
import AccountBilling from '@/pages/AccountBilling';
import AccountProfile from '@/pages/AccountProfile';
import CounterReturns from '@/pages/CounterReturns';
import CounterSettlement from '@/pages/CounterSettlement';
import AdminFleet from '@/pages/AdminFleet';
import InspectionReturn from '@/pages/InspectionReturn';
import Admin from '@/pages/Admin';
import AdminFleetNew from '@/pages/AdminFleetNew';
import InspectionNew from '@/pages/InspectionNew';
import AdminFleetMatrix from '@/pages/AdminFleetMatrix';
import AdminRates from '@/pages/AdminRates';
import AdminRentalOverdue from '@/pages/AdminRentalOverdue';
import AdminMaintenance from '@/pages/AdminMaintenance';
import AdminMaintenanceNew from '@/pages/AdminMaintenanceNew';
import AdminAnalytics from '@/pages/AdminAnalytics';
import AdminActiveRentals from '@/pages/AdminActiveRentals';

const CUSTOMER = ['customer'];
const COUNTER = ['counter_agent', 'fleet_manager'];
const MANAGER = ['fleet_manager'];

export const customRoutes = () => [
  <Route
    key="app"
    element={
      <AppOwnerProvider>
        <Layout />
      </AppOwnerProvider>
    }
  >
    <Route path="/" element={<Landing />} />
    <Route path="/booking" element={<Booking />} />
    <Route path="/vehicles" element={<Vehicles />} />
    <Route path="/booking/configure" element={<BookingConfigure />} />
    <Route path="/booking/confirmation" element={<BookingConfirmation />} />
    <Route path="/booking/checkout" element={<BookingCheckout />} />
    <Route path="/signup" element={<Signup />} />
    <Route path="/login" element={<Login />} />
    <Route path="/account/dashboard" element={<RoleProtectedRoute roles={CUSTOMER}><AccountDashboard /></RoleProtectedRoute>} />
    <Route path="/account/bookings" element={<RoleProtectedRoute roles={CUSTOMER}><AccountBookings /></RoleProtectedRoute>} />
    <Route path="/counter/agreement" element={<RoleProtectedRoute roles={COUNTER}><CounterAgreement /></RoleProtectedRoute>} />
    <Route path="/counter" element={<RoleProtectedRoute roles={COUNTER}><Counter /></RoleProtectedRoute>} />
    <Route path="/counter/departures" element={<RoleProtectedRoute roles={COUNTER}><CounterDepartures /></RoleProtectedRoute>} />
    <Route path="/counter/check-out/:reservationId" element={<RoleProtectedRoute roles={COUNTER}><CounterCheckout /></RoleProtectedRoute>} />
    <Route path="/account/billing" element={<RoleProtectedRoute roles={CUSTOMER}><AccountBilling /></RoleProtectedRoute>} />
    <Route path="/account/profile" element={<RoleProtectedRoute roles={CUSTOMER}><AccountProfile /></RoleProtectedRoute>} />
    <Route path="/counter/returns" element={<RoleProtectedRoute roles={COUNTER}><CounterReturns /></RoleProtectedRoute>} />
    <Route path="/counter/settlement/:rentalId" element={<RoleProtectedRoute roles={COUNTER}><CounterSettlement /></RoleProtectedRoute>} />
    <Route path="/admin/fleet" element={<RoleProtectedRoute roles={MANAGER}><AdminFleet /></RoleProtectedRoute>} />
    <Route path="/inspections/return/:rentalId" element={<RoleProtectedRoute roles={COUNTER}><InspectionReturn /></RoleProtectedRoute>} />
    <Route path="/admin" element={<RoleProtectedRoute roles={MANAGER}><Admin /></RoleProtectedRoute>} />
    <Route path="/admin/fleet/new" element={<RoleProtectedRoute roles={MANAGER}><AdminFleetNew /></RoleProtectedRoute>} />
    <Route path="/inspections/new" element={<RoleProtectedRoute roles={COUNTER}><InspectionNew /></RoleProtectedRoute>} />
    <Route path="/admin/fleet/matrix" element={<RoleProtectedRoute roles={MANAGER}><AdminFleetMatrix /></RoleProtectedRoute>} />
    <Route path="/admin/rates" element={<RoleProtectedRoute roles={MANAGER}><AdminRates /></RoleProtectedRoute>} />
    <Route path="/admin/rentals/:rentalId/overdue" element={<RoleProtectedRoute roles={MANAGER}><AdminRentalOverdue /></RoleProtectedRoute>} />
    <Route path="/admin/maintenance" element={<RoleProtectedRoute roles={MANAGER}><AdminMaintenance /></RoleProtectedRoute>} />
    <Route path="/admin/maintenance/new" element={<RoleProtectedRoute roles={MANAGER}><AdminMaintenanceNew /></RoleProtectedRoute>} />
    <Route path="/admin/analytics" element={<RoleProtectedRoute roles={MANAGER}><AdminAnalytics /></RoleProtectedRoute>} />
    <Route path="/admin/rentals/active" element={<RoleProtectedRoute roles={MANAGER}><AdminActiveRentals /></RoleProtectedRoute>} />
  </Route>,
  // The preview iframe is loaded at /<org_id>/<product_id> — no prototype route
  // matches it, so unknown URLs fall back to the prototype home.
  <Route key="fallback" path="*" element={<Navigate to="/" replace />} />,
];

export default customRoutes;
