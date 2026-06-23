import type { ReactNode } from 'react';
import { NavLink } from 'react-router-dom';

import { useAuth } from '../auth/AuthContext';

const NAV_ITEMS = [
  { to: '/', label: 'Overview', exact: true },
  { to: '/providers', label: 'Verification', exact: false },
  { to: '/commission', label: 'Commission', exact: false },
];

export function Layout({ children }: { children: ReactNode }) {
  const { user, signOut } = useAuth();

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="brand">
          <span className="brand__mark">+</span>
          <span className="brand__name">Dr.Plus</span>
        </div>
        <p className="sidebar__caption">Control Hub</p>
        <nav className="nav">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.exact}
              className={({ isActive }) => `nav__item${isActive ? ' nav__item--active' : ''}`}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>

      <div className="main">
        <header className="topbar">
          <div className="topbar__title">Platform Control Hub</div>
          <div className="topbar__user">
            <div className="topbar__email">
              {user ? `${user.firstName} ${user.lastName}` : 'Administrator'}
            </div>
            <button type="button" className="btn btn--ghost" onClick={signOut}>
              Sign out
            </button>
          </div>
        </header>
        <main className="content">{children}</main>
      </div>
    </div>
  );
}
