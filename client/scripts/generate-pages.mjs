/**
 * Generates the 30 DriveFlow page components at the paths declared in
 * .codalio/ui-handoff.json. Each page is a thin, real page: it calls the exact
 * rhino-react hooks the handoff lists and renders the data_contract keys, so
 * the ui-integration stage can swap in the prototype's visual design without
 * rewiring data.
 *
 * Run with: node scripts/generate-pages.mjs
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const HEADER = `/* DriveFlow page — data wiring generated from .codalio/ui-handoff.json.
 * Visual design is owned by the prototype; this file owns the data contract. */
`;

const pages = [
  {
    file: 'components/landing/LandingPage.tsx',
    component: 'LandingPage',
    title: 'DriveFlow — rent the right car in two minutes',
    body: `      <section>
        <p>
          Search live availability, pick your protection tier, upload your licence and collect
          the keys without a queue. Deposit holds are authorised and released automatically.
        </p>
        <Link to="/vehicles">Browse the fleet</Link>
        <ol>
          <li>1. Choose a class and dates</li>
          <li>2. Configure protection and add-ons</li>
          <li>3. Pay and receive your QR voucher</li>
        </ol>
      </section>`,
  },
  {
    file: 'components/vehicles/VehiclesPage.tsx',
    component: 'VehiclesPage',
    title: 'Browse vehicles & availability',
    hooks: `  const [filters, setFilters] = useState({ location_id: '', transmission: '', query: '' });
  const { data: categories, isLoading } = useModelIndex('vehicle_categories', {
    includes: ['vehicles'],
    perPage: 50,
  });
  const { data: locations } = useModelIndex('locations', { perPage: 50 });
  const rows = categories?.data ?? [];`,
    body: `      <FilterBar locations={locations?.data ?? []} value={filters} onChange={setFilters} />
      <DataTable
        loading={isLoading}
        rows={rows.filter((row) => matchesFilters(row, filters))}
        columns={[
          { key: 'name', label: 'Class', render: (row) => <Link to="/booking">{row.name}</Link> },
          { key: 'code', label: 'Code' },
          { key: 'rate', label: 'Daily rate', render: (row) => money(row.rate) },
          { key: 'passenger_capacity', label: 'Seats' },
          { key: 'baggage_capacity', label: 'Bags' },
          { key: 'transmission', label: 'Transmission' },
          { key: 'available_vehicle_count', label: 'Available' },
        ]}
        empty="No vehicle classes match those filters."
      />`,
  },
  {
    file: 'components/booking/BookingPage.tsx',
    component: 'BookingPage',
    title: 'Configure your reservation',
    hooks: `  const navigate = useNavigate();
  const [trip, setTrip] = useState({
    pickup_datetime: '',
    scheduled_return_datetime: '',
    vehicle_category_id: '',
  });
  const { data: categories } = useModelIndex('vehicle_categories', { perPage: 50 });
  const { data: rateRules } = useModelIndex('rate_rules', { perPage: 50 });
  const rows = categories?.data ?? [];`,
    body: `      <TripDetailsForm value={trip} onChange={setTrip} onSubmit={() => navigate('/booking/configure')} />
      <h2>Available classes</h2>
      <DataTable
        rows={rows}
        columns={[
          { key: 'name', label: 'Class' },
          { key: 'rate', label: 'Daily rate', render: (row) => money(row.rate) },
          { key: 'security_deposit_amount', label: 'Deposit', render: (row) => money(row.security_deposit_amount) },
        ]}
        empty="No vehicle classes available."
      />
      <p>{(rateRules?.data ?? []).length} pricing rules load with this reservation.</p>`,
  },
  {
    file: 'components/booking/BookingConfigurePage.tsx',
    component: 'BookingConfigurePage',
    title: 'Protection & add-ons',
    hooks: `  const navigate = useNavigate();
  const [protectionTier, setProtectionTier] = useState('standard');
  const [addons, setAddons] = useState([]);
  const createRental = useModelStore('rentals');
  const { data: categories } = useModelIndex('vehicle_categories', { perPage: 50 });
  const category = (categories?.data ?? [])[0];`,
    body: `      <ProtectionPicker
        tiers={[
          { key: 'basic', label: 'Basic', price: 0 },
          { key: 'standard', label: 'Standard', price: 12 },
          { key: 'full', label: 'Full', price: 24 },
        ]}
        addons={[
          { key: 'child_seat', label: 'Child safety seat', price: 8 },
          { key: 'additional_driver', label: 'Additional driver', price: 10 },
          { key: 'roadside_assistance', label: 'Roadside assistance', price: 6 },
        ]}
        tier={protectionTier}
        selectedAddons={addons}
        onTierChange={setProtectionTier}
        onToggleAddon={(key) =>
          setAddons((prev) => (prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]))
        }
      />
      <ReservationPriceSummary tier={protectionTier} addons={addons} category={category} />
      <button
        type="button"
        disabled={createRental.isPending}
        onClick={() => {
          createRental.mutate(
            {
              vehicle_category_id: category?.id,
              protection_tier: protectionTier,
              scheduled_duration_days: 3,
              status: 'reserved',
              pickup_datetime: new Date().toISOString(),
              scheduled_return_datetime: new Date(Date.now() + 259200000).toISOString(),
            },
            { onSuccess: () => navigate('/booking/checkout') },
          );
        }}
      >
        Continue to checkout
      </button>`,
  },
  {
    file: 'components/booking/BookingCheckoutPage.tsx',
    component: 'BookingCheckoutPage',
    title: 'Review & checkout',
    hooks: `  const navigate = useNavigate();
  const [renter, setRenter] = useState({ full_name: '', email: '', phone_number: '' });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const { data: charges } = useModelIndex('rental_charges', { perPage: 50 });
  const lines = charges?.data ?? [];`,
    body: `      <RenterDetailsForm
        value={renter}
        onChange={setRenter}
        onUpload={async (file) => {
          const body = new FormData();
          body.append('file', file);
          body.append('kind', 'driver_license');
          await api.post('/documents', body);
        }}
      />
      <StripeElementsMount />
      <ChargeList lines={lines} />
      {error ? <p role="alert">{error}</p> : null}
      <button
        type="button"
        disabled={submitting}
        onClick={async () => {
          setSubmitting(true);
          setError(null);
          try {
            const { data } = await api.post('/bookings/confirm', renter);
            navigate('/booking/confirmation', { state: { rentalId: data?.rental?.id } });
          } catch (err) {
            setError(err?.response?.data?.decline_reason ?? 'Payment could not be authorised.');
          } finally {
            setSubmitting(false);
          }
        }}
      >
        Confirm reservation
      </button>`,
  },
  {
    file: 'components/booking/BookingConfirmationPage.tsx',
    component: 'BookingConfirmationPage',
    title: 'Booking confirmed',
    hooks: `  const { state } = useLocation();
  const rentalId = state?.rentalId;
  const { data: rental } = useModelShow('rentals', rentalId);`,
    body: `      {rental ? (
        <ReservationVoucher
          reservationNumber={rental.reservation_number}
          qrCodeUrl={rental.qr_code_url}
          customer={rental.customer}
          vehicle={rental.vehicle}
          due={rental.due}
          balance={rental.balance}
          depositStatus={rental.deposit_status}
        />
      ) : (
        <p>
          No reservation in this session. <Link to="/vehicles">Start a new booking</Link>.
        </p>
      )}`,
  },
  {
    file: 'components/auth/SignupPage.tsx',
    component: 'SignupPage',
    title: 'Create your DriveFlow account',
    hooks: `  const [form, setForm] = useState({ name: '', email: '', phone_number: '', password: '' });
  const [message, setMessage] = useState(null);
  const [errors, setErrors] = useState({});`,
    body: `      <SignupForm
        value={form}
        errors={errors}
        onChange={setForm}
        onSubmit={async () => {
          try {
            const { data } = await api.post('/auth/register', form);
            setMessage(data.message);
          } catch (err) {
            setErrors(err?.response?.data?.errors ?? {});
          }
        }}
      />
      {message ? (
        <p role="status">
          {message} <Link to="/login">Sign in</Link>
        </p>
      ) : null}`,
  },
  {
    file: 'components/auth/LoginPage.tsx',
    component: 'LoginPage',
    title: 'Sign in',
    hooks: `  const navigate = useNavigate();
  const { login, setOrganization } = useAuth();
  const [form, setForm] = useState({ email: '', password: '' });
  const [error, setError] = useState(null);`,
    body: `      <LoginForm
        value={form}
        error={error}
        onChange={setForm}
        onSubmit={async () => {
          const result = await login(form.email, form.password);
          if (!result.success) {
            setError(result.error ?? 'Invalid email or password.');
            return;
          }
          if (result.organization_slug) setOrganization(result.organization_slug);
          navigate('/account/dashboard', { replace: true });
        }}
      />
      <p>
        Need an account? <Link to="/signup">Create one</Link>
      </p>`,
  },
  {
    file: 'components/account/AccountDashboardPage.tsx',
    component: 'AccountDashboardPage',
    title: 'My dashboard',
    hooks: `  const { data: upcoming } = useModelIndex('rentals', { filters: { status: 'confirmed' }, perPage: 10 });
  const { data: payments } = useModelIndex('payments', { perPage: 5 });
  const { data: profiles } = useModelIndex('customer_profiles', { perPage: 1 });`,
    body: `      <AccountShortcuts />
      <h2>Upcoming pickups</h2>
      <DataTable
        rows={upcoming?.data ?? []}
        columns={[
          { key: 'reservation_number', label: 'Reservation' },
          { key: 'vehicle', label: 'Vehicle' },
          { key: 'due', label: 'Pickup' },
          { key: 'status', label: 'Status' },
          { key: 'balance', label: 'Balance' },
        ]}
        empty="You have no upcoming reservations."
      />
      <h2>Latest deposit activity</h2>
      <DataTable
        rows={payments?.data ?? []}
        columns={[
          { key: 'rental', label: 'Reservation' },
          { key: 'type', label: 'Type' },
          { key: 'amount_display', label: 'Amount' },
          { key: 'status', label: 'Status' },
        ]}
        empty="No payments yet."
      />
      <p>{(profiles?.data ?? []).length} profile on file.</p>`,
  },
  {
    file: 'components/account/AccountBookingsPage.tsx',
    component: 'AccountBookingsPage',
    title: 'My bookings',
    hooks: `  const { organizationSlug } = useAppOwner();
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const { data: rentals, isLoading } = useModelIndex('rentals', {
    filters: status ? { status } : undefined,
    search: search || undefined,
    includes: ['vehicle_category'],
    perPage: 25,
  });
  const rows = rentals?.data ?? [];`,
    body: `      <StatusTabs
        value={status}
        options={['', 'reserved', 'confirmed', 'active', 'completed', 'cancelled']}
        onChange={setStatus}
      />
      <SearchInput value={search} onChange={setSearch} placeholder="Search reservation" />
      <DataTable
        loading={isLoading}
        rows={rows}
        columns={[
          { key: 'reservation_number', label: 'Reservation' },
          { key: 'vehicle', label: 'Vehicle' },
          { key: 'dates', label: 'Dates' },
          { key: 'status', label: 'Status' },
          { key: 'balance', label: 'Balance' },
        ]}
        actions={(row) => (
          <>
            <a href={\`/api/\${organizationSlug}/receipts/\${row.id}/invoice\`}>Invoice PDF</a>
            <Link to="/account/billing">Manage</Link>
          </>
        )}
        empty="No bookings match those filters."
      />`,
  },
  {
    file: 'components/account/AccountBillingPage.tsx',
    component: 'AccountBillingPage',
    title: 'Billing & invoices',
    hooks: `  const { organizationSlug, customerProfileId } = useAppOwner();
  const { data: payments, isLoading } = useModelIndex('payments', { includes: ['rental'], perPage: 25 });
  const rows = payments?.data ?? [];`,
    body: `      <button
        type="button"
        onClick={() =>
          api.post('/payments/methods', {
            customer_profile_id: customerProfileId,
            stripe_payment_method: 'pm_card_visa',
            card_last4: '4242',
            card_brand: 'visa',
          })
        }
      >
        Add card
      </button>
      <DataTable
        loading={isLoading}
        rows={rows}
        columns={[
          { key: 'rental', label: 'Reservation' },
          { key: 'type', label: 'Transaction' },
          { key: 'amount_display', label: 'Amount' },
          { key: 'status', label: 'Status' },
          { key: 'last4', label: 'Card' },
          { key: 'date', label: 'Processed' },
        ]}
        actions={(row) => (
          <a href={\`/api/\${organizationSlug}/receipts/\${row.rental_id}/invoice\`}>Invoice PDF</a>
        )}
        empty="No transactions yet."
      />`,
  },
  {
    file: 'components/account/AccountProfilePage.tsx',
    component: 'AccountProfilePage',
    title: 'Profile & documents',
    hooks: `  const [saved, setSaved] = useState(false);
  const { data: profiles, isLoading } = useModelIndex('customer_profiles', { perPage: 1 });
  const updateProfile = useModelUpdate('customer_profiles');
  const profile = (profiles?.data ?? [])[0];
  const [form, setForm] = useState(null);
  const value = form ?? {
    full_name: profile?.full_name ?? '',
    email: profile?.email ?? '',
    phone_number: profile?.phone_number ?? '',
  };`,
    body: `      <ProfileForm
        value={value}
        license={profile}
        saved={saved}
        onChange={setForm}
        onUpload={async (file) => {
          const body = new FormData();
          body.append('file', file);
          body.append('kind', 'driver_license');
          await api.post('/documents', body);
        }}
        onSave={() =>
          updateProfile.mutate({ id: profile.id, data: value }, { onSuccess: () => setSaved(true) })
        }
      />
      {isLoading ? <p>Loading profile…</p> : null}`,
  },
  {
    file: 'components/counter/CounterPage.tsx',
    component: 'CounterPage',
    title: 'Counter operations',
    hooks: `  const { organizationSlug } = useAppOwner();
  const { data: departures } = useModelIndex('rentals', { filters: { status: 'confirmed' }, perPage: 10 });
  const { data: returns } = useModelIndex('rentals', { filters: { status: 'active,overdue' }, perPage: 10 });
  const { data: queue } = useQuery({
    queryKey: ['counter-departures'],
    queryFn: async () => (await api.get(\`/\${organizationSlug}/counter/departures\`)).data,
  });`,
    body: `      <KpiRow
        items={[
          { label: 'Pending departures', value: queue?.kpis?.pending ?? 0 },
          { label: 'Ready to release', value: queue?.kpis?.ready ?? 0 },
          { label: 'Unsecured deposits', value: queue?.kpis?.unsecured_deposits ?? 0 },
        ]}
      />
      <h2>Today's departures</h2>
      <DataTable
        rows={departures?.data ?? []}
        columns={[
          { key: 'reservation_number', label: 'Reservation' },
          { key: 'customer', label: 'Customer' },
          { key: 'vehicle', label: 'Vehicle' },
          { key: 'due', label: 'Pickup' },
          { key: 'deposit_status', label: 'Deposit' },
        ]}
        actions={(row) => <Link to={\`/counter/check-out/\${row.reservation_number}\`}>Start handover</Link>}
        empty="No departures scheduled."
      />
      <h2>Returns in progress</h2>
      <DataTable
        rows={returns?.data ?? []}
        columns={[
          { key: 'reservation_number', label: 'Reservation' },
          { key: 'customer', label: 'Customer' },
          { key: 'due', label: 'Due' },
          { key: 'status', label: 'Status' },
        ]}
        empty="No vehicles out."
      />`,
  },
  {
    file: 'components/counter/CounterDeparturesPage.tsx',
    component: 'CounterDeparturesPage',
    title: 'Departures queue',
    hooks: `  const [search, setSearch] = useState('');
  const { data: rentals, isLoading } = useModelIndex('rentals', {
    filters: { status: 'reserved,confirmed' },
    includes: ['customer_profile', 'vehicle_category', 'vehicle'],
    search: search || undefined,
    perPage: 25,
  });
  const rows = rentals?.data ?? [];`,
    body: `      <SearchInput value={search} onChange={setSearch} placeholder="Plate, name or reservation" />
      <DataTable
        loading={isLoading}
        rows={rows}
        columns={[
          { key: 'reservation_number', label: 'Reservation' },
          { key: 'customer', label: 'Customer' },
          { key: 'category', label: 'Class' },
          { key: 'vehicle', label: 'Assigned vehicle' },
          { key: 'due', label: 'Pickup' },
          { key: 'deposit_status', label: 'Deposit' },
        ]}
        actions={(row) => <Link to={\`/counter/check-out/\${row.reservation_number}\`}>Check out</Link>}
        empty="No scheduled departures."
      />`,
  },
  {
    file: 'components/counter/CounterCheckoutPage.tsx',
    component: 'CounterCheckoutPage',
    title: 'Check-out',
    hooks: `  const { reservationId } = useParams();
  const { data: rental, isLoading } = useModelShow('rentals', reservationId, {
    includes: ['customer_profile', 'vehicle'],
  });
  const [status, setStatus] = useState(null);`,
    body: `      {isLoading ? <p>Loading reservation…</p> : null}
      {rental ? (
        <>
          <AppBreadcrumbs trail={['Counter', 'Departures', rental.reservation_number]} />
          <LicenseVerificationPanel
            customer={rental.customer}
            expired={rental.license_expired}
            onAuthorizeDeposit={async () => {
              try {
                const { data } = await api.post('/payments/hold', {
                  rental_id: rental.id,
                  amount: rental.daily_cap,
                  payment_method_last4: '4242',
                });
                setStatus(data.message);
              } catch (err) {
                setStatus(err?.response?.data?.decline_reason ?? 'Deposit declined.');
              }
            }}
          />
          <DepositStatusBadge status={rental.deposit_status} />
          {status ? <p role="status">{status}</p> : null}
          <Link to="/counter/agreement">Continue to agreement</Link>
        </>
      ) : null}`,
  },
  {
    file: 'components/counter/CounterAgreementPage.tsx',
    component: 'CounterAgreementPage',
    title: 'Digital rental agreement',
    hooks: `  const { organizationSlug } = useAppOwner();
  const [query, setQuery] = useState('');
  const [rental, setRental] = useState(null);
  const [signature, setSignature] = useState('');`,
    body: `      <SearchInput value={query} onChange={setQuery} placeholder="Reservation number or plate" />
      <button
        type="button"
        onClick={async () => {
          const { data } = await api.get(\`/\${organizationSlug}/counter/lookup\`, { params: { q: query } });
          setRental(data?.data?.[0] ?? null);
        }}
      >
        Load reservation
      </button>
      {rental ? (
        <>
          <AgreementTerms rentalId={rental.id} />
          <SignaturePad value={signature} onChange={setSignature} />
          <button
            type="button"
            disabled={!signature}
            onClick={() =>
              api.post('/rentals/' + rental.id + '/finalize', { customer_signature_url: signature })
            }
          >
            Accept & sign
          </button>
        </>
      ) : null}`,
  },
  {
    file: 'components/counter/CounterReturnsPage.tsx',
    component: 'CounterReturnsPage',
    title: 'Returns queue',
    hooks: `  const [query, setQuery] = useState('');
  const { data: rentals, isLoading } = useModelIndex('rentals', {
    filters: { status: 'active,overdue' },
    perPage: 25,
  });
  const rows = rentals?.data ?? [];`,
    body: `      <SearchInput value={query} onChange={setQuery} placeholder="Plate or QR" />
      <DataTable
        loading={isLoading}
        rows={rows}
        columns={[
          { key: 'reservation_number', label: 'Reservation' },
          { key: 'vehicle', label: 'Vehicle' },
          { key: 'customer', label: 'Customer' },
          { key: 'due', label: 'Due' },
          { key: 'status', label: 'Status' },
          { key: 'accrued', label: 'Late fee' },
        ]}
        actions={(row) => (
          <>
            <Link to={\`/inspections/return/\${row.id}\`}>Inspect</Link>
            <Link to={\`/counter/settlement/\${row.id}\`}>Settle</Link>
          </>
        )}
        empty="No vehicles out on rent."
      />`,
  },
  {
    file: 'components/counter/CounterSettlementPage.tsx',
    component: 'CounterSettlementPage',
    title: 'Return settlement',
    hooks: `  const { organizationSlug } = useAppOwner();
  const { rentalId } = useParams();
  const { data: rental } = useModelShow('rentals', rentalId);
  const { data: comparison } = useQuery({
    queryKey: ['inspection-comparison', rentalId],
    queryFn: async () =>
      (await api.get(\`/\${organizationSlug}/rentals/\${rentalId}/inspection_comparison\`)).data,
    enabled: !!rentalId,
  });
  const { data: charges } = useModelIndex('rental_charges', { filters: { rental_id: rentalId }, perPage: 50 });
  const [result, setResult] = useState(null);`,
    body: `      <FinancialFormulaBreakdown
        lateGraceMinutes={rental?.late_grace_minutes ?? 60}
        formulas={Object.entries(comparison?.deltas ?? {})}
      />
      <ChargeList lines={charges?.data ?? []} />
      <DepositStatusBadge status={rental?.deposit_status} />
      <button
        type="button"
        onClick={async () => {
          const { data } = await api.post('/payments/settle', { rental_id: rentalId });
          setResult(data);
        }}
      >
        Capture charges & release difference
      </button>
      {result ? <ReservationPriceSummary settlement={result.settlement} /> : null}`,
  },
  {
    file: 'components/inspections/InspectionNewPage.tsx',
    component: 'InspectionNewPage',
    title: 'New pickup inspection',
    hooks: `  const [step, setStep] = useState(1);
  const [readings, setReadings] = useState({ odometer_reading: '', fuel_percentage: '' });
  const createInspection = useModelStore('inspections');
  const createDamage = useModelStore('damage_records');
  const [photos, setPhotos] = useState({});`,
    body: `      <InspectionStepper step={step} />
      <InspectionFocusHeader step={step} />
      {step === 1 ? <OdometerFuelCapture value={readings} onChange={setReadings} /> : null}
      {step === 2 ? (
        <PhotoGrid
          angles={['front', 'driver_side', 'rear', 'passenger_side']}
          photos={photos}
          onUpload={async (angle, file) => {
            setPhotos((prev) => ({ ...prev, [angle]: file.name }));
            const body = new FormData();
            body.append('file', file);
            body.append('angle', angle);
            body.append('kind', 'inspection_photo');
            await api.post('/documents', body);
          }}
        />
      ) : null}
      {step === 3 ? (
        <DamagePinEditor
          onPin={(pin) =>
            createDamage.mutate({
              panel_location: pin.panel_location,
              severity: pin.severity,
              description: pin.description ?? 'Pinned blemish',
              is_pre_existing: true,
              photo_url: pin.photo_url,
            })
          }
        />
      ) : null}
      <InspectionActionBar
        step={step}
        onNext={() => setStep((s) => Math.min(s + 1, 4))}
        onBack={() => setStep((s) => Math.max(s - 1, 1))}
        onFinish={() =>
          createInspection.mutate({
            inspection_type: 'check_out',
            ...readings,
            cleanliness_status: 'clean',
          })
        }
      />`,
  },
  {
    file: 'components/inspections/InspectionReturnPage.tsx',
    component: 'InspectionReturnPage',
    title: 'Return walkaround',
    hooks: `  const { organizationSlug } = useAppOwner();
  const { rentalId } = useParams();
  const { data: comparison } = useQuery({
    queryKey: ['inspection-comparison', rentalId],
    queryFn: async () =>
      (await api.get(\`/\${organizationSlug}/rentals/\${rentalId}/inspection_comparison\`)).data,
    enabled: !!rentalId,
  });
  const createDamage = useModelStore('damage_records');
  const [angle, setAngle] = useState('front');`,
    body: `      <InspectionFocusHeader title={\`Return · \${comparison?.rental?.reservation_number ?? rentalId}\`} />
      <AngleSwitcher value={angle} angles={['front', 'driver_side', 'rear', 'passenger_side']} onChange={setAngle} />
      <PhotoEvidenceComparison angle={angle} departure={comparison?.departure} arrival={comparison?.return} />
      <PhotoEvidenceMetadata departure={comparison?.departure} arrival={comparison?.return} />
      <DamagePinEditor
        onPin={(pin) =>
          createDamage.mutate({
            inspection_id: comparison?.return?.id,
            panel_location: pin.panel_location,
            severity: pin.severity,
            description: pin.description ?? 'New damage found on return',
            is_pre_existing: false,
            photo_url: pin.photo_url,
          })
        }
      />
      <Link to={\`/counter/settlement/\${rentalId}\`}>Complete & review settlement</Link>`,
  },
  {
    file: 'components/admin/AdminDashboardPage.tsx',
    component: 'AdminDashboardPage',
    title: 'Operations control centre',
    hooks: `  const { organizationSlug } = useAppOwner();
  const { data: analytics } = useQuery({
    queryKey: ['analytics', 30],
    queryFn: async () => (await api.get(\`/\${organizationSlug}/analytics\`, { params: { range: 30 } })).data,
  });
  const { data: rentals } = useModelIndex('rentals', { filters: { status: 'overdue' }, perPage: 10 });`,
    body: `      <KpiRow items={analytics?.kpis ?? []} />
      <OperationalStatusLegend />
      <h2>Operational alerts</h2>
      <DataTable
        rows={rentals?.data ?? []}
        columns={[
          { key: 'reservation_number', label: 'Reservation' },
          { key: 'customer', label: 'Customer' },
          { key: 'accrued', label: 'Late fee' },
          { key: 'overdue_duration', label: 'Overdue' },
        ]}
        actions={(row) => <Link to={\`/admin/rentals/\${row.id}/overdue\`}>Resolve</Link>}
        empty="No overdue contracts. Fleet is on schedule."
      />`,
  },
  {
    file: 'components/admin/AdminFleetPage.tsx',
    component: 'AdminFleetPage',
    title: 'Fleet inventory',
    hooks: `  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState([]);
  const { data: vehicles, isLoading } = useModelIndex('vehicles', {
    includes: ['location', 'vehicle_category'],
    search: search || undefined,
    perPage: 50,
  });
  const rows = vehicles?.data ?? [];`,
    body: `      <SearchInput value={search} onChange={setSearch} placeholder="Plate, VIN or model" />
      <Link to="/admin/fleet/new">+ Add vehicle</Link>
      <BulkActionBar
        count={selected.length}
        onApply={async (changes) => {
          await api.post('/vehicles/bulk', { ids: selected, changes });
          setSelected([]);
        }}
      />
      <DataTable
        loading={isLoading}
        rows={rows}
        selectable
        selected={selected}
        onSelect={setSelected}
        columns={[
          { key: 'name', label: 'Vehicle' },
          { key: 'plate', label: 'Plate' },
          { key: 'location', label: 'Location' },
          { key: 'status', label: 'Status', render: (row) => <VehicleStatusBadge status={row.status} /> },
          { key: 'miles', label: 'Odometer' },
          { key: 'health', label: 'Service life', render: (row) => \`\${row.health}%\` },
        ]}
        actions={(row) => <Link to="/admin/maintenance">Open</Link>}
        empty="No vehicles match that search."
      />`,
  },
  {
    file: 'components/admin/AdminFleetNewPage.tsx',
    component: 'AdminFleetNewPage',
    title: 'Add a fleet vehicle',
    hooks: `  const navigate = useNavigate();
  const createVehicle = useModelStore('vehicles');
  const { data: categories } = useModelIndex('vehicle_categories', { perPage: 50 });
  const { data: locations } = useModelIndex('locations', { perPage: 50 });
  const [errors, setErrors] = useState({});
  const [form, setForm] = useState({
    vin: '', license_plate: '', make: '', model: '', year: '', current_odometer: '',
    vehicle_category_id: '', location_id: '', status: 'available',
  });`,
    body: `      <VehicleForm
        value={form}
        errors={errors}
        categories={categories?.data ?? []}
        locations={locations?.data ?? []}
        onChange={setForm}
        onUpload={async (file) => {
          const body = new FormData();
          body.append('file', file);
          body.append('kind', 'registration_document');
          await api.post('/documents', body);
        }}
      />
      <button
        type="button"
        onClick={() =>
          createVehicle.mutate(form, {
            onSuccess: () => navigate('/admin/fleet'),
            onError: (err) => setErrors(err?.response?.data?.errors ?? {}),
          })
        }
      >
        Save vehicle
      </button>`,
  },
  {
    file: 'components/admin/AdminFleetMatrixPage.tsx',
    component: 'AdminFleetMatrixPage',
    title: 'Fleet schedule matrix',
    hooks: `  const { organizationSlug } = useAppOwner();
  const [range, setRange] = useState({ from: '', to: '' });
  const [search, setSearch] = useState('');
  const { data: matrix, isLoading } = useQuery({
    queryKey: ['fleet-matrix', range],
    queryFn: async () => (await api.get(\`/\${organizationSlug}/fleet_matrix\`, { params: range })).data,
  });`,
    body: `      <RangePicker value={range} onChange={setRange} />
      <SearchInput value={search} onChange={setSearch} placeholder="Plate or model" />
      {isLoading ? <p>Loading schedule…</p> : null}
      {matrix ? (
        <FleetTimeline
          days={matrix.days}
          vehicles={(matrix.vehicles ?? []).filter((v) =>
            search ? \`\${v.name} \${v.plate}\`.toLowerCase().includes(search.toLowerCase()) : true,
          )}
          summary={matrix.summary}
        />
      ) : null}`,
  },
  {
    file: 'components/admin/AdminRatesPage.tsx',
    component: 'AdminRatesPage',
    title: 'Dynamic pricing & rates',
    hooks: `  const { data: rules, isLoading } = useModelIndex('rate_rules', { includes: ['vehicle_category'], perPage: 50 });
  const createRule = useModelStore('rate_rules');
  const updateRule = useModelUpdate('rate_rules');
  const { data: categories } = useModelIndex('vehicle_categories', { perPage: 50 });
  const rows = rules?.data ?? [];`,
    body: `      <RateRuleForm categories={categories?.data ?? []} onCreate={(payload) => createRule.mutate(payload)} />
      <DataTable
        loading={isLoading}
        rows={rows}
        columns={[
          { key: 'name', label: 'Rule' },
          { key: 'scope', label: 'Applies to' },
          { key: 'rule_type', label: 'Type' },
          { key: 'value', label: 'Value' },
          { key: 'min_rental_days', label: 'Min days' },
          { key: 'is_active', label: 'Active', render: (row) => (row.is_active ? 'Yes' : 'No') },
        ]}
        actions={(row) => (
          <button
            type="button"
            onClick={() => updateRule.mutate({ id: row.id, data: { is_active: !row.is_active } })}
          >
            {row.is_active ? 'Disable' : 'Enable'}
          </button>
        )}
        empty="No pricing rules configured."
      />`,
  },
  {
    file: 'components/admin/AdminRentalOverduePage.tsx',
    component: 'AdminRentalOverduePage',
    title: 'Overdue rental resolution',
    hooks: `  const { rentalId } = useParams();
  const { data: rental, isLoading } = useModelShow('rentals', rentalId);
  const { data: charges } = useModelIndex('rental_charges', { filters: { rental_id: rentalId }, perPage: 50 });
  const [notice, setNotice] = useState(null);
  const [holdError, setHoldError] = useState(null);`,
    body: `      {isLoading ? <p>Loading contract…</p> : null}
      {rental ? (
        <>
          <AppBreadcrumbs trail={['Admin', 'Active rentals', \`Overdue \${rental.reservation_number}\`]} />
          <FinancialFormulaBreakdown
            lateGraceMinutes={rental.late_grace_minutes}
            graceExpiresAt={rental.grace_expires_at}
            accrued={rental.late_fee_accrued}
            dailyCap={rental.daily_cap}
            formulas={[]}
          />
          <ChargeList lines={charges?.data ?? []} />
          <button
            type="button"
            onClick={() =>
              api.post(\`/rentals/\${rental.id}/notify\`, { channel: 'sms+email' }).then((r) => setNotice(r.data.message))
            }
          >
            Send return urgency notice
          </button>
          <button
            type="button"
            onClick={() =>
              api
                .post('/payments/expand_hold', {
                  rental_id: rental.id,
                  amount: rental.daily_cap,
                  payment_method_last4: '4242',
                })
                .catch((err) => setHoldError(err?.response?.data?.decline_reason ?? 'Pre-auth expansion failed.'))
            }
          >
            Expand pre-authorization hold
          </button>
          <button type="button" onClick={() => api.post(\`/rentals/\${rental.id}/escalate\`, { reason: 'Unreturned asset' })}>
            Escalate for recovery
          </button>
          {notice ? <p role="status">{notice}</p> : null}
          {holdError ? <p role="alert">{holdError}</p> : null}
        </>
      ) : null}`,
  },
  {
    file: 'components/admin/AdminMaintenancePage.tsx',
    component: 'AdminMaintenancePage',
    title: 'Maintenance hub',
    hooks: `  const [tab, setTab] = useState('service_due');
  const { data: dueVehicles } = useModelIndex('vehicles', { scope: 'serviceDue', perPage: 50 });
  const { data: logs, isLoading } = useModelIndex('vehicle_maintenance_logs', { perPage: 50 });
  const rows = logs?.data ?? [];`,
    body: `      <StatusTabs value={tab} options={['service_due', 'open', 'completed']} onChange={setTab} />
      <h2>Service due</h2>
      <DataTable
        rows={dueVehicles?.data ?? []}
        columns={[
          { key: 'name', label: 'Vehicle' },
          { key: 'plate', label: 'Plate' },
          { key: 'miles', label: 'Odometer' },
          { key: 'next_service_odometer', label: 'Next service at' },
          { key: 'service_label', label: 'Status' },
        ]}
        empty="No vehicles inside the service window."
      />
      <h2>Work orders</h2>
      <Link to="/admin/maintenance/new">+ New work order</Link>
      <DataTable
        loading={isLoading}
        rows={rows}
        columns={[
          { key: 'vehicle', label: 'Vehicle' },
          { key: 'service', label: 'Service' },
          { key: 'status_label', label: 'Status' },
          { key: 'priority', label: 'Priority' },
          { key: 'cost', label: 'Cost' },
          { key: 'detail', label: 'Detail' },
        ]}
        empty="No work orders."
      />`,
  },
  {
    file: 'components/admin/AdminMaintenanceNewPage.tsx',
    component: 'AdminMaintenanceNewPage',
    title: 'Create maintenance order',
    hooks: `  const navigate = useNavigate();
  const createLog = useModelStore('vehicle_maintenance_logs');
  const { data: vehicles } = useModelIndex('vehicles', { perPage: 100 });
  const [form, setForm] = useState({
    vehicle_id: '', service_type: 'oil_change', service_date: '', odometer_at_service: '',
    cost: '', vendor_name: '', status: 'scheduled', notes: '',
  });`,
    body: `      <WorkOrderForm
        value={form}
        vehicles={vehicles?.data ?? []}
        onChange={setForm}
        onSubmit={() => createLog.mutate(form, { onSuccess: () => navigate('/admin/maintenance') })}
      />`,
  },
  {
    file: 'components/admin/AdminActiveRentalsPage.tsx',
    component: 'AdminActiveRentalsPage',
    title: 'Active rentals',
    hooks: `  const { organizationSlug } = useAppOwner();
  const [tab, setTab] = useState('active');
  const [search, setSearch] = useState('');
  const filtersByTab = {
    all: undefined,
    active: { status: 'active' },
    due_soon: { status: 'active' },
    overdue: { status: 'overdue' },
  };
  const { data: rentals, isLoading } = useModelIndex('rentals', {
    filters: filtersByTab[tab],
    search: search || undefined,
    perPage: 50,
  });
  const rows = rentals?.data ?? [];`,
    body: `      <StatusTabs value={tab} options={['all', 'active', 'due_soon', 'overdue']} onChange={setTab} />
      <SearchInput value={search} onChange={setSearch} placeholder="Search reservation or customer" />
      <a href={\`/api/\${organizationSlug}/rentals/export\`}>Export CSV</a>
      <DataTable
        loading={isLoading}
        rows={rows}
        columns={[
          { key: 'reservation_number', label: 'Reservation' },
          { key: 'customer', label: 'Customer' },
          { key: 'vehicle', label: 'Vehicle' },
          { key: 'due', label: 'Due' },
          { key: 'status', label: 'Status' },
          { key: 'accrued', label: 'Late fee' },
          { key: 'balance', label: 'Balance' },
        ]}
        actions={(row) => (row.status === 'overdue' ? <Link to={\`/admin/rentals/\${row.id}/overdue\`}>Resolve</Link> : null)}
        empty="No contracts in this view."
      />`,
  },
  {
    file: 'components/admin/AdminAnalyticsPage.tsx',
    component: 'AdminAnalyticsPage',
    title: 'Operational & financial analytics',
    hooks: `  const { organizationSlug } = useAppOwner();
  const [range, setRange] = useState(30);
  const [location, setLocation] = useState('');
  const { data: analytics, isLoading } = useQuery({
    queryKey: ['analytics', range, location],
    queryFn: async () =>
      (await api.get(\`/\${organizationSlug}/analytics\`, { params: { range, location: location || undefined } })).data,
  });
  const { data: payments } = useModelIndex('payments', { perPage: 25 });`,
    body: `      <RangePicker
        value={{ range, location }}
        onChange={(next) => {
          setRange(Number(next.range) || 30);
          setLocation(next.location ?? '');
        }}
      />
      <KpiRow items={analytics?.kpis ?? []} />
      <a href={\`/api/\${organizationSlug}/analytics/export\`}>Export CSV</a>
      {isLoading ? <p>Loading analytics…</p> : null}
      {(analytics?.charts ?? []).map((chart) => (
        <ChartPanel key={chart.title} title={chart.title} values={chart.values} />
      ))}
      <h2>Deposit reconciliation</h2>
      <KpiRow
        items={Object.entries(analytics?.deposits ?? {}).map(([label, value]) => ({
          label: label.replace(/_/g, ' '),
          value: money(value),
        }))}
      />
      <h2>Stripe transaction audit</h2>
      <DataTable
        rows={payments?.data ?? []}
        columns={[
          { key: 'rental', label: 'Reservation' },
          { key: 'type', label: 'Type' },
          { key: 'amount_display', label: 'Amount' },
          { key: 'status', label: 'Status' },
          { key: 'reference', label: 'Stripe reference' },
        ]}
        empty="No transactions."
      />`,
  },
];

const REQUIRED_PHOTOS = "['front', 'driver_side', 'rear', 'passenger_side']";

let written = 0;
for (const page of pages) {
  const target = path.join(ROOT, 'src', page.file);
  const hooks = page.hooks ?? '';
  const body = page.body ?? '';
  const all = `${hooks}\n${body}`;
  const imports = new Set();

  if (/useState/.test(all)) imports.add("import { useState } from 'react';");
  if (/\bapi\./.test(all)) imports.add("import { api } from '@rhino-dev/rhino-react';");
  if (/useModel(Index|Show|Store|Update)/.test(all)) {
    imports.add(
      "import { useModelIndex, useModelShow, useModelStore, useModelUpdate } from '@rhino-dev/rhino-react';",
    );
  }
  if (/useQuery/.test(all)) imports.add("import { useQuery } from '@tanstack/react-query';");
  if (/useParams/.test(all)) imports.add("import { useParams } from 'react-router-dom';");
  if (/useLocation/.test(all)) imports.add("import { useLocation } from 'react-router-dom';");
  if (/useNavigate|navigate\(/.test(all)) imports.add("import { useNavigate } from 'react-router-dom';");
  if (/useAuth/.test(all)) imports.add("import { useAuth } from '@rhino-dev/rhino-react';");
  if (/useAppOwner|organizationSlug/.test(all)) {
    imports.add("import { useAppOwner } from '@/contexts/AppOwnerProvider';");
  }
  if (/<Link/.test(all)) imports.add("import { Link } from 'react-router-dom';");
  if (/VehicleStatusBadge/.test(all)) imports.add("import { VehicleStatusBadge } from '@/components/shared/Badges';");
  if (/DepositStatusBadge/.test(all)) imports.add("import { DepositStatusBadge } from '@/components/shared/Badges';");
  if (/OperationalStatusLegend/.test(all)) {
    imports.add("import { OperationalStatusLegend } from '@/components/shared/OperationalStatusLegend';");
  }
  if (/DataTable/.test(all)) imports.add("import { DataTable } from '@/components/shared/DataTable';");
  if (/SearchInput/.test(all)) imports.add("import { SearchInput } from '@/components/shared/Inputs';");
  if (/StatusTabs|KpiRow|ChargeList|RangePicker|ChartPanel|FilterBar|BulkActionBar/.test(all)) {
    imports.add(
      "import { StatusTabs, KpiRow, ChargeList, RangePicker, ChartPanel, FilterBar, BulkActionBar } from '@/components/shared/Widgets';",
    );
  }
  if (/AppBreadcrumbs/.test(all)) imports.add("import { AppBreadcrumbs } from '@/components/shared/AppBreadcrumbs';");
  if (/ReservationPriceSummary/.test(all)) {
    imports.add("import { ReservationPriceSummary } from '@/components/shared/ReservationPriceSummary';");
  }
  if (/FinancialFormulaBreakdown/.test(all)) {
    imports.add("import { FinancialFormulaBreakdown } from '@/components/shared/FinancialFormulaBreakdown';");
  }
  if (/InspectionStepper|InspectionFocusHeader|InspectionActionBar|OdometerFuelCapture|PhotoGrid|SignaturePad|LicenseVerificationPanel|AgreementTerms/.test(all)) {
    imports.add(
      "import { InspectionStepper, InspectionFocusHeader, InspectionActionBar, OdometerFuelCapture, PhotoGrid, SignaturePad, LicenseVerificationPanel, AgreementTerms } from '@/components/shared/InspectionKit';",
    );
  }
  if (/DamagePinEditor/.test(all)) imports.add("import { DamagePinEditor } from '@/components/shared/DamagePinEditor';");
  if (/PhotoEvidenceComparison|PhotoEvidenceMetadata|AngleSwitcher/.test(all)) {
    imports.add(
      "import { PhotoEvidenceComparison, PhotoEvidenceMetadata, AngleSwitcher } from '@/components/shared/PhotoEvidenceComparison';",
    );
  }
  if (/ReservationVoucher/.test(all)) imports.add("import { ReservationVoucher } from '@/components/shared/ReservationVoucher';");
  if (/AccountShortcuts/.test(all)) imports.add("import { AccountShortcuts } from '@/components/shared/AccountShortcuts';");
  if (/SignupForm|LoginForm|RenterDetailsForm|ProfileForm|VehicleForm|WorkOrderForm|TripDetailsForm|RateRuleForm|ProtectionPicker/.test(all)) {
    imports.add(
      "import { SignupForm, LoginForm, RenterDetailsForm, ProfileForm, VehicleForm, WorkOrderForm, TripDetailsForm, RateRuleForm, ProtectionPicker } from '@/components/shared/Forms';",
    );
  }
  if (/StripeElementsMount/.test(all)) imports.add("import { StripeElementsMount } from '@/components/shared/StripeElementsMount';");
  if (/FleetTimeline/.test(all)) imports.add("import { FleetTimeline } from '@/components/shared/FleetTimeline';");
  if (/matchesFilters/.test(all)) imports.add("import { money, matchesFilters } from '@/lib/format';");
  else if (/money\(/.test(all)) imports.add("import { money } from '@/lib/format';");
  imports.add("import styles from '@/components/shared/page.module.css';");

  const source = `${HEADER}${[...imports].sort().join('\n')}

export default function ${page.component}() {
${hooks ? `${hooks}\n` : ''}  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <h1>${page.title}</h1>
      </header>
${body}
    </div>
  );
}
`;

  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, source);
  written += 1;
}

console.log(`wrote ${written} page components`);
