import "./styles.css";
import React from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Layout from "./components/Layout";
import Landing from "./pages/Landing";
import Booking from "./pages/Booking";
import Vehicles from "./pages/Vehicles";
import BookingConfigure from "./pages/BookingConfigure";
import BookingConfirmation from "./pages/BookingConfirmation";
import BookingCheckout from "./pages/BookingCheckout";
import Signup from "./pages/Signup";
import Login from "./pages/Login";
import AccountDashboard from "./pages/AccountDashboard";
import AccountBookings from "./pages/AccountBookings";
import CounterAgreement from "./pages/CounterAgreement";
import Counter from "./pages/Counter";
import CounterDepartures from "./pages/CounterDepartures";
import CounterCheckout from "./pages/CounterCheckout";
import AccountBilling from "./pages/AccountBilling";
import AccountProfile from "./pages/AccountProfile";
import CounterReturns from "./pages/CounterReturns";
import CounterSettlement from "./pages/CounterSettlement";
import AdminFleet from "./pages/AdminFleet";
import InspectionReturn from "./pages/InspectionReturn";
import Admin from "./pages/Admin";
import AdminFleetNew from "./pages/AdminFleetNew";
import InspectionNew from "./pages/InspectionNew";
import AdminFleetMatrix from "./pages/AdminFleetMatrix";
import AdminRates from "./pages/AdminRates";
import AdminRentalOverdue from "./pages/AdminRentalOverdue";
import AdminMaintenance from "./pages/AdminMaintenance";
import AdminMaintenanceNew from "./pages/AdminMaintenanceNew";
import AdminAnalytics from "./pages/AdminAnalytics";
import AdminActiveRentals from "./pages/AdminActiveRentals";

function App() {
  return (
    <BrowserRouter>

      <Routes>
        <Route element={<Layout />}>
                <Route path="/" element={<Landing />} />
      <Route path="/booking" element={<Booking />} />
      <Route path="/vehicles" element={<Vehicles />} />
      <Route path="/booking/configure" element={<BookingConfigure />} />
      <Route path="/booking/confirmation" element={<BookingConfirmation />} />
      <Route path="/booking/checkout" element={<BookingCheckout />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/login" element={<Login />} />
      <Route path="/account/dashboard" element={<AccountDashboard />} />
      <Route path="/account/bookings" element={<AccountBookings />} />
      <Route path="/counter/agreement" element={<CounterAgreement />} />
      <Route path="/counter" element={<Counter />} />
      <Route path="/counter/departures" element={<CounterDepartures />} />
      <Route path="/counter/check-out/:reservationId" element={<CounterCheckout />} />
      <Route path="/account/billing" element={<AccountBilling />} />
      <Route path="/account/profile" element={<AccountProfile />} />
      <Route path="/counter/returns" element={<CounterReturns />} />
      <Route path="/counter/settlement/:rentalId" element={<CounterSettlement />} />
      <Route path="/admin/fleet" element={<AdminFleet />} />
      <Route path="/inspections/return/:rentalId" element={<InspectionReturn />} />
      <Route path="/admin" element={<Admin />} />
      <Route path="/admin/fleet/new" element={<AdminFleetNew />} />
      <Route path="/inspections/new" element={<InspectionNew />} />
      <Route path="/admin/fleet/matrix" element={<AdminFleetMatrix />} />
      <Route path="/admin/rates" element={<AdminRates />} />
      <Route path="/admin/rentals/:rentalId/overdue" element={<AdminRentalOverdue />} />
      <Route path="/admin/maintenance" element={<AdminMaintenance />} />
      <Route path="/admin/maintenance/new" element={<AdminMaintenanceNew />} />
      <Route path="/admin/analytics" element={<AdminAnalytics />} />
      <Route path="/admin/rentals/active" element={<AdminActiveRentals />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
