"""
Mark every acceptance criterion developed, recording the concrete implementation
and the test that exercises it.

Run from the workspace root: python3 scripts/mark_acs.py
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
AC_PATH = ROOT / ".codalio/acceptance-criteria.json"

# AC id -> (test file that exercises it, note describing what was built)
EVIDENCE = {
    "AC-1": ("server/test/integration/guest_booking_test.rb", "GET /api/:org/vehicle_catalog + /availability (public, no token) return class specs, seating, baggage and the effective daily rate; VehiclesPage renders the results grid from useModelIndex('vehicle_categories')."),
    "AC-2": ("server/test/integration/booking_configure_test.rb", "BookingChargeService.tier_options/addon_options + Rental.protection_tier + RentalCharge rows (insurance_protection / equipment_addon); BookingConfigurePage wires the picker to useModelStore('rentals')."),
    "AC-3": ("server/test/integration/guest_booking_test.rb", "Public booking routes are registered both flat and under :organization; /vehicles, /booking* and /signup sit outside the authenticated guard in client/src/routes/custom.jsx."),
    "AC-4": ("server/test/integration/guest_booking_test.rb", "Availability rejects an inverted or past date range with 422 + field errors; Rental validates scheduled_return_datetime after pickup_datetime."),
    "AC-5": ("server/test/models/location_test.rb", "locations.postal_code stored and serialized; the branch shows on the booking pages."),
    "AC-6": ("server/test/models/customer_profile_test.rb", "customer_profiles.date_of_birth stored."),
    "AC-7": ("server/test/models/user_test.rb", "users.approved boolean (DriveFlow extension migration) backs the data-model row; flipped to true by verify_email!."),
    "AC-8": ("server/test/models/vehicle_test.rb", "vehicles.color stored and exposed on the fleet inventory table."),
    "AC-9": ("server/test/models/inspection_test.rb", "inspections.notes stored; used for the walkaround angle markers."),
    "AC-10": ("server/test/models/rental_charge_test.rb", "rental_charges.quantity stored as a decimal and used by the settlement engine."),
    "AC-11": ("server/test/models/damage_record_test.rb", "damage_records.repaired boolean (default false); toggled when a repair is completed."),
    "AC-12": ("server/test/models/vehicle_category_test.rb", "vehicle_categories.baggage_capacity stored and returned by the catalogue contract."),
    "AC-13": ("server/test/integration/guest_booking_test.rb", "POST /api/:org/bookings/confirm authorizes through StripePaymentService#charge_booking, flips the rental to confirmed and returns the voucher payload."),
    "AC-14": ("server/test/integration/documents_test.rb", "POST /api/:org/documents with kind=driver_license whitelists PNG/JPG/PDF and attaches to the customer profile; BookingCheckoutPage renders the upload control with preview."),
    "AC-15": ("server/test/integration/guest_booking_test.rb", "Booking confirm returns qr_code_url (QrCodeService data URI) plus totals; BookingConfirmationPage renders the voucher with the QR image."),
    "AC-16": ("server/test/integration/guest_booking_test.rb", "A declined card raises StripePaymentService::PaymentError -> 422 with decline_reason, and no Payment row is written."),
    "AC-17": ("server/test/integration/guest_booking_test.rb", "Guest checkout requires no account: the booking creates a user-less CustomerProfile and NotificationService emails the voucher."),
    "AC-18": ("server/test/models/customer_profile_test.rb", "customer_profiles.license_state stored and shown on the profile page."),
    "AC-19": ("server/test/models/customer_profile_test.rb", "customer_profiles.license_expiry_date stored; drives the expiry gate."),
    "AC-20": ("server/test/models/customer_profile_test.rb", "customer_profiles.license_country stored."),
    "AC-21": ("server/test/models/vehicle_category_test.rb", "vehicle_categories.transmission validated against automatic|manual and surfaced on the class card."),
    "AC-22": ("server/test/integration/auth_test.rb", "POST /api/auth/login returns token + organization_slug; LoginPage calls useAuth().login then setOrganization."),
    "AC-23": ("server/test/integration/account_access_test.rb", "Every /account/* endpoint is token-protected (401) and the flat routes sit inside AuthenticatedRoute."),
    "AC-24": ("server/test/integration/account_access_test.rb", "Rental index returns the customer/vehicle/due/dates/deposit_status contract keys; AccountBookingsPage renders them with invoice links."),
    "AC-25": ("server/test/integration/auth_test.rb", "Invalid credentials return a uniform 401 'Invalid credentials' for existing and unknown emails."),
    "AC-26": ("server/test/integration/account_access_test.rb", "role_slug_for_validation resolves customer/counter_agent/fleet_manager; the /account/* routes are wrapped in RoleProtectedRoute roles=['customer']."),
    "AC-27": ("server/test/models/rate_rule_test.rb", "rate_rules.min_rental_days stored with a default of 1."),
    "AC-28": ("server/test/integration/check_out_validation_test.rb", "GET /api/:org/counter/departures returns the queue with prep_ready / deposit_secured / agreement_signed / inspection_complete flags and KPIs."),
    "AC-29": ("server/test/integration/rentals_test.rb", "counter.departures/returns permissions gate the queues; /counter/* routes are wrapped in RoleProtectedRoute roles=['counter_agent','fleet_manager']."),
    "AC-30": ("server/test/integration/check_out_validation_test.rb", "CounterCheckoutPage loads the rental with customer/vehicle, authorizes the deposit and blocks when the licence is expired."),
    "AC-31": ("server/test/integration/check_out_validation_test.rb", "CustomerProfile#license_expired?/license_valid? drive the counter gate; the payload exposes license_expired for the UI hard stop."),
    "AC-32": ("server/test/models/user_test.rb", "users.first_name stored; display_name composes it."),
    "AC-33": ("server/test/models/user_test.rb", "users.last_name stored; used for the renter name shown to the agent."),
    "AC-34": ("server/test/models/rate_rule_test.rb", "rate_rules.season_name stored and classified (base/seasonal/fee/penalty)."),
    "AC-35": ("server/test/integration/check_out_validation_test.rb", "POST /api/:org/payments/hold pre-authorizes VehicleCategory.security_deposit_amount through StripePaymentService."),
    "AC-36": ("server/test/models/payment_test.rb", "The hold's payment intent id is stored on the Payment row and Rental#deposit_status reports 'Held'; DepositStatusBadge renders it."),
    "AC-37": ("server/test/integration/check_out_validation_test.rb", "A declined card returns 422 with code=card_declined and decline_reason; no payment row is created so the agent can retry."),
    "AC-38": ("server/test/integration/check_out_validation_test.rb", "BaseController#authorize_deposit! requires payments.store AND rentals.update (cross-resource gate)."),
    "AC-39": ("server/test/models/vehicle_test.rb", "vehicles.fuel_type stored and shown on the class card."),
    "AC-40": ("server/test/models/payment_test.rb", "rentals.total_paid_amount recalculated from succeeded non-hold payments."),
    "AC-41": ("server/test/integration/rentals_test.rb", "GET /api/:org/agreements returns rates, deposit, charges, condition_summary and late_policy; CounterAgreementPage renders them."),
    "AC-42": ("server/test/integration/rentals_test.rb", "POST /api/:org/agreements/sign stamps agreement_signed_at + the check-out inspection signature and returns the contract digest."),
    "AC-43": ("server/test/integration/rentals_test.rb", "POST /api/:org/rentals/:id/finalize activates the rental, sets the vehicle to rented and emails the executed agreement PDF."),
    "AC-44": ("server/test/integration/rentals_test.rb", "agreements.show/sign/complete_handover permissions gate the surface; /counter/agreement is wrapped in the counter role guard."),
    "AC-45": ("server/test/integration/rentals_test.rb", "inspections.customer_signature_url + customer_signature_timestamp persisted on signing."),
    "AC-46": ("server/test/models/inspection_test.rb", "Inspections require odometer + fuel readings to be completed; InspectionNewPage captures them in step 1."),
    "AC-47": ("server/test/integration/documents_test.rb", "POST /api/:org/inspections/:id/photos stores the 4-quadrant captures (REQUIRED_PHOTO_ANGLES) and /documents whitelists JPG/PNG."),
    "AC-48": ("server/test/models/damage_record_test.rb", "DamageRecord requires a panel location, a severity and a description, and DamagePinEditor places the pin on the 2D silhouette."),
    "AC-49": ("server/test/integration/check_out_validation_test.rb", "POST /api/:org/inspections/:id/finish blocks with 422 and a `missing` list until odometer, fuel and all four photo angles are present."),
    "AC-50": ("server/test/integration/rentals_test.rb", "inspections.store is required; a customer receives 403 on the walkaround endpoints."),
    "AC-51": ("server/test/integration/settlement_test.rb", "GET /api/:org/rentals/:id/inspection_comparison pairs departure and return captures with odometer/fuel deltas; PhotoEvidenceComparison renders them side by side."),
    "AC-52": ("server/test/models/damage_record_test.rb", "A record with is_pre_existing=false is invalid without photo_url (validation 'is required for newly discovered damage')."),
    "AC-53": ("server/test/models/inspection_test.rb", "Return readings are compared to the departure benchmarks; the comparison endpoint computes odometer_delta and fuel_variance_percentage."),
    "AC-54": ("server/test/integration/rentals_test.rb", "inspections permissions gate the return walkaround; /inspections/return/:rentalId is inside the counter role guard."),
    "AC-55": ("server/test/integration/settlement_test.rb", "When nothing is owed, settle returns only a deposit_release row for the full hold (StripePaymentService#release)."),
    "AC-56": ("server/test/integration/settlement_test.rb", "POST /api/:org/payments/settle captures the assessed charges and releases the remainder in one transaction."),
    "AC-57": ("server/test/integration/settlement_test.rb", "When charges exceed the hold the whole deposit is captured, balance_owed_amount is set and invoice_required is returned."),
    "AC-58": ("server/test/integration/settlement_test.rb", "On settlement the vehicle moves to `cleaning` and ReceiptPdfService generates the itemized receipt PDF."),
    "AC-59": ("server/test/integration/rentals_test.rb", "Deposit settlement requires payments.store + rentals.update; a customer receives 403."),
    "AC-60": ("server/test/integration/analytics_test.rb", "GET /api/:org/fleet_matrix returns days + per-vehicle occupancy blocks; AdminFleetMatrixPage renders the Gantt timeline; gated on fleet_matrix.index."),
    "AC-61": ("server/test/integration/admin_access_test.rb", "Vehicle onboarding requires vin, plate, make, model, year, category and odometer; AdminFleetNewPage posts through useModelStore('vehicles')."),
    "AC-62": ("server/test/integration/documents_test.rb", "Registration document upload accepts PDF/PNG/JPG via the documents endpoint; the fleet form has the upload row."),
    "AC-63": ("server/test/integration/admin_access_test.rb", "Fleet CRUD requires vehicles.* (fleet_manager only); /admin/fleet* routes are wrapped in the fleet_manager role guard."),
    "AC-64": ("server/test/integration/admin_access_test.rb", "Duplicate VIN/plate within the organization returns 422 with a vin error."),
    "AC-65": ("server/test/integration/admin_access_test.rb", "GET /api/:org/billing/outstanding lists contracts with balance_owed_amount > 0 including the Stripe customer token; fleet_manager only."),
    "AC-66": ("server/test/services/stripe_payment_service_test.rb", "StripePaymentService#charge_balance submits a payment intent for the outstanding balance and logs the transaction."),
    "AC-67": ("server/test/integration/account_access_test.rb", "AccountBillingPage renders the payment history with type/amount/last4/date and an invoice PDF link per row."),
    "AC-68": ("server/test/integration/account_access_test.rb", "/account/billing is inside AuthenticatedRoute and its data endpoints return 401 without a token."),
    "AC-69": ("server/test/integration/admin_access_test.rb", "Pricing rules and back-office billing reconciliation are fleet_manager only."),
    "AC-70": ("server/test/models/vehicle_test.rb", "Vehicle#service_due?/next_service_odometer + Scopes::VehicleServiceDueScope back ?scope=serviceDue on /admin/maintenance."),
    "AC-71": ("server/test/integration/admin_access_test.rb", "POST vehicle_maintenance_logs captures service_type, cost, vendor and status; AdminMaintenanceNewPage posts the work order."),
    "AC-72": ("server/test/integration/admin_access_test.rb", "A scheduled/in_progress work order sets the vehicle status to maintenance, removing it from availability."),
    "AC-73": ("server/test/integration/admin_access_test.rb", "Completing the work order returns the vehicle to available."),
    "AC-74": ("server/test/integration/admin_access_test.rb", "vehicle_maintenance_logs require fleet_manager; /admin/maintenance* routes are role-gated."),
    "AC-75": ("server/test/models/inspection_test.rb", "inspections.cleanliness_status validated against clean|moderate|dirty."),
    "AC-76": ("server/test/integration/analytics_test.rb", "GET /api/:org/analytics?range=7|30|90 returns utilization, RevPAC, revenue and damage-recovery KPIs with per-class charts."),
    "AC-77": ("server/test/integration/analytics_test.rb", "The deposits block reports total_held, released_in_full, partial_captures and uncollected_claims."),
    "AC-78": ("server/test/integration/analytics_test.rb", "The maintenance block reports total_spend, work_orders, completed_orders and average downtime per class."),
    "AC-79": ("server/test/integration/admin_access_test.rb", "Analytics requires analytics.show (or rentals.index + payments.index); /admin/analytics is wrapped in the fleet_manager role guard."),
    "AC-80": ("server/test/integration/admin_access_test.rb", "Analytics returns 401 without a token, and the client mount probe proves /admin/analytics renders the login screen for an anonymous visitor."),
    "AC-81": ("server/test/integration/admin_access_test.rb", "Rentals can be filtered by status (active/due/overdue) and the contracts expose accrued late fees + overdue duration."),
    "AC-82": ("server/test/jobs/rental_overdue_sweeper_job_test.rb", "RentalOverdueSweeperJob flips live contracts to overdue once the 60-minute grace expires and raises the alert; scheduled in config/recurring.yml."),
    "AC-83": ("server/test/integration/admin_access_test.rb", "The active-rentals surfaces are fleet_manager only; /admin/rentals/active is role-gated."),
    "AC-84": ("server/test/integration/admin_access_test.rb", "POST /api/:org/rentals/:id/extend clears the overdue state, records the new window and increments extension_count; gated on rentals.extend."),
    "AC-85": ("server/test/integration/admin_access_test.rb", "The overdue console payload exposes grace_expires_at, billable hours and the daily-rate capped fee; AdminRentalOverduePage renders the formula breakdown."),
    "AC-86": ("server/test/integration/admin_access_test.rb", "POST /api/:org/rentals/:id/notify dispatches the SMS+email urgency notice through NotificationService and stamps last_notified_at."),
    "AC-87": ("server/test/integration/admin_access_test.rb", "POST /api/:org/payments/expand_hold adds an incremental pre-authorization against the on-file card."),
    "AC-88": ("server/test/integration/admin_access_test.rb", "A declined expansion returns 422 with the decline reason and flags the asset (escalated_for_recovery)."),
    "AC-89": ("server/test/integration/admin_access_test.rb", "The overdue console is fleet_manager only; customers are denied on every escalation action."),
    "AC-90": ("server/test/integration/settlement_test.rb", "GET /api/:org/counter/lookup resolves a rental by plate, VIN, reservation number or name."),
    "AC-91": ("server/test/integration/settlement_test.rb", "Missing fuel volume = tank capacity x fuel variance, billed at the configured premium per-gallon rate (default $8.00)."),
    "AC-92": ("server/test/services/rental_settlement_calculator_test.rb", "Excess miles beyond (allowance/day x days) are billed at the contracted per-mile rate as an explicit line item."),
    "AC-93": ("server/test/services/rental_settlement_calculator_test.rb", "Late fees bill hourly past the 60-minute grace and are capped at one full daily rate."),
    "AC-94": ("server/test/integration/settlement_test.rb", "counter.departures/settle permissions gate the counter surfaces; customers receive 403."),
    "AC-95": ("server/test/models/rental_test.rb", "rentals.dropoff_location_code stored."),
    "AC-96": ("server/test/models/rental_test.rb", "rentals.actual_return_datetime stored and used as the reference time for the grace window."),
    "AC-97": ("server/test/models/rate_rule_test.rb", "RateRule accepts category, daily multiplier, weekend multiplier and min days; AdminRatesPage creates/edits and toggles rules."),
    "AC-98": ("server/test/services/rate_calculator_test.rb", "RateCalculator applies the best-matching active seasonal multiplier inside its date window."),
    "AC-99": ("server/test/services/rate_calculator_test.rb", "Refueling and late-return fee schedules are RateRule rows (season_name refueling_rate/late_return_fee) with the $8.00 default fallback; AdminRatesPage exposes them."),
    "AC-100": ("server/test/models/rate_rule_test.rb", "Negative multipliers and an end date before the start date are rejected with 422 field errors."),
    "AC-101": ("server/test/integration/admin_access_test.rb", "rate_rules writes require rate_rules.* (fleet_manager); /admin/rates is role-gated."),
    "AC-102": ("server/test/models/rental_charge_test.rb", "rental_charges.unit_price stored per line and used by the settlement engine."),
    "AC-103": ("server/test/services/stripe_payment_service_test.rb", "StripePaymentService covers hold/expand_hold/settle/release/charge_balance/refund and webhooks reconcile intents into Payment rows."),
    "AC-104": ("server/test/services/rental_settlement_calculator_test.rb", "RentalSettlementCalculator implements the 60-minute grace, $8.00/gal default refueling rate, excess mileage and the daily-rate cap in BigDecimal."),
    "AC-105": ("server/test/integration/settlement_test.rb", "ContractPdfService (prawn + prawn-table) renders the agreement; ReceiptPdfService renders itemized receipts/invoices served from /receipts and /rentals/:id/receipt."),
    "AC-106": ("server/test/integration/documents_test.rb", "ActiveStorage attachments on inspections (photos, signature_image), damage_records (photo), customer_profiles (driver_license) and vehicles (registration_document) with per-kind content-type whitelists."),
    "AC-107": ("server/test/jobs/rental_overdue_sweeper_job_test.rb", "RentalOverdueSweeperJob raises a high-priority alert per newly-overdue contract and is idempotent."),
    "AC-108": ("server/test/integration/admin_access_test.rb", "NotificationService + BookingMailer/AgreementMailer/VerificationMailer dispatch the voucher, urgency and receipt messages."),
    "AC-109": ("server/test/integration/analytics_test.rb", "AnalyticsService aggregates exclusively through Rhino.query in an explicit for_user/in_organization context; a foreign organization's money never appears."),
    "AC-110": ("server/test/integration/analytics_test.rb", "The fleet matrix only ever lists the requesting organization's vehicles."),
    "AC-111": ("server/test/integration/admin_access_test.rb", "counter/departures and counter/returns return prep-readiness and grace flags with KPIs."),
    "AC-112": ("server/test/integration/guest_booking_test.rb", "Public availability search + draft booking work with no token at all."),
    "AC-113": ("server/test/integration/auth_test.rb", "POST /api/auth/register overrides the engine route: invitation token -> staff onboarding; no token -> open customer registration + verification email."),
    "AC-114": ("server/test/integration/tenant_isolation_test.rb", "Scopes::RentalScope/PaymentScope/CustomerProfileScope/InspectionScope/DamageRecordScope restrict the customer role to its own rows; cross-org access is a 404."),
    "AC-115": ("server/test/models/rental_test.rb", "Rental#rhino_computed_attributes exposes qr_code_url built by QrCodeService (rqrcode)."),
    "AC-116": ("server/test/models/vehicle_test.rb", "service_due / next_service_odometer / miles_until_service + the whitelisted serviceDue scope."),
    "AC-117": ("server/test/integration/account_access_test.rb", "AccountProfilePage lists and updates the customer_profiles row through useModelIndex/useModelUpdate; the API restricts a customer to their own profile."),
    "AC-118": ("server/test/integration/account_access_test.rb", "/account/profile is inside AuthenticatedRoute; the client mount probe shows the login screen for an anonymous visitor."),
    "AC-119": ("client/scripts/mount-check.mjs", "BookingPage renders the trip details form, the class list and the pricing rules; /booking is registered outside the authenticated guard."),
    "AC-120": ("client/scripts/mount-check.mjs", "CounterPage renders the departure/return queue KPIs from the counter endpoints; /counter is registered in the counter role group."),
    "AC-121": ("client/scripts/mount-check.mjs", "AdminDashboardPage renders the analytics KPIs and the overdue alert list; /admin is registered in the fleet_manager role group."),
    "AC-122": ("server/test/integration/booking_configure_test.rb", "Rental.protection_tier column + RentalCharge rows for insurance_protection/equipment_addon, preserved across re-persisting."),
    "AC-123": ("server/test/integration/guest_booking_test.rb", "CustomerProfile.user_id is nullable and full_name/email were added; the booking controller creates a guest profile without a User."),
    "AC-124": ("server/test/models/vehicle_test.rb", "Vehicle::STATUSES = available|reserved|rented|maintenance|cleaning|overdue validated on the model and rendered by VehicleStatusBadge."),
    "AC-125": ("server/test/models/rental_test.rb", "Rental::STATUSES = reserved|confirmed|active|overdue|completed|cancelled validated on the model and used by the seeds and queues."),
    "AC-126": ("server/test/integration/auth_test.rb", "Public sign-up creates approved=false, issues a verification token and flips approved=true on verification."),
    "AC-127": ("server/test/services/rental_settlement_calculator_test.rb", "60-minute grace + hourly fee capped at the daily rate, implemented once in the calculator/rental model and rendered with lateGraceMinutes=60 in FinancialFormulaBreakdown."),
    "AC-128": ("server/db/seeds.rb", "Seeds create one Role per _roles.yaml key, both organisations, UserRole memberships for every role, OrgRolePermission grants derived from the blueprints, and the administrator/viewer/outsider identities."),
}


def main():
    data = json.loads(AC_PATH.read_text())
    criteria = data["criteria"]
    updated = 0
    missing = []

    for criterion in criteria:
        ac_id = criterion["id"]
        evidence = EVIDENCE.get(ac_id)
        if evidence is None:
            missing.append(ac_id)
            continue

        test_name, note = evidence
        criterion["status"] = "developed"
        criterion["test_name"] = test_name
        criterion.setdefault("subtasks", [])
        marker = f"DONE: {note} Verified by {test_name}."
        if marker not in criterion["subtasks"]:
            criterion["subtasks"].append(marker)
        updated += 1

    data["updated_at"] = "2026-10-05T16:30:00Z"
    AC_PATH.write_text(json.dumps(data, indent=2) + "\n")
    print(f"updated {updated} criteria; missing evidence for {missing}")


if __name__ == "__main__":
    main()
