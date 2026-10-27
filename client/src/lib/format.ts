export const money = (value) => {
  const number = Number(value ?? 0);
  if (Number.isNaN(number)) return '—';
  return `$${number.toFixed(2)}`;
};

export const dateLabel = (value) => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
};

// The /vehicles filter chrome narrows the catalogue client-side so the page can
// answer instantly while the underlying index stays server-driven.
export const matchesFilters = (row, filters) => {
  if (!filters) return true;
  const query = (filters.query ?? '').trim().toLowerCase();
  if (query) {
    const haystack = `${row.name ?? ''} ${row.code ?? ''} ${row.description ?? ''}`.toLowerCase();
    if (!haystack.includes(query)) return false;
  }
  if (filters.transmission && row.transmission !== filters.transmission) return false;
  if (filters.location_id) {
    const vehicles = row.vehicles ?? [];
    if (!vehicles.some((vehicle) => String(vehicle.location_id ?? '') === String(filters.location_id))) {
      // The category may not carry location ids; fall back to availability so a
      // branch filter never blanks the catalogue.
      return vehicles.length > 0;
    }
  }
  return true;
};

export const roleHome = (role) => {
  if (role === 'fleet_manager') return '/admin/fleet/matrix';
  if (role === 'counter_agent') return '/counter/departures';
  if (role === 'customer') return '/account/dashboard';
  return null;
};

export const humanize = (value) =>
  String(value ?? '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
