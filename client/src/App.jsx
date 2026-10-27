import { BrowserRouter, Routes } from 'react-router-dom';
import { customRoutes } from './routes/custom';

/**
 * Routes are declared once, in customRoutes(), and mounted through <Routes>
 * inside a single BrowserRouter. <Routes> (unlike useRoutes) is explicitly
 * documented to accept <Route> elements, so the declaration style used by
 * customRoutes is guaranteed to match.
 */
export const AppRoutes = () => <Routes>{customRoutes()}</Routes>;

export const App = () => (
  <BrowserRouter>
    <AppRoutes />
  </BrowserRouter>
);

export default App;
