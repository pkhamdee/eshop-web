# Conventions for eshop-web

What the code does not tell you at a glance. Moved here from pkhamdee/eshop-infra's `docs/agents/conventions.md` when
eshop-web got its own repository (ADR 0009); the system-wide conventions (local environment, deploy, human-only
steps) are still there. e2e helpers named below are in `../eshop-infra/e2e/tests/steps.ts`.

- Routes in `src/routes.tsx`; signed-in sections are nested layout routes guarded by `<RequireRole role=.../>`, and
  the back office is its own `/staff` branch with `StaffLayout`. Pages in `src/pages/` (`src/pages/staff/`), API
  types and calls in `src/api/<area>.ts`.
- Fetch only through `src/api/client.ts` (`useApi`, `useReloadableApi`, `apiGet/Post/Put/GetBlob`,
  `problemMessage`): it adds the Bearer token and clears the session on a 401. Format money, dates and Flat Rate
  with `src/format.ts` (Asia/Bangkok).
- Thai copy, mobile-first, plain CSS in one file (`src/index.css`), 44 px touch targets, visible `:focus-visible`.
- Breakpoints are defined once, in the comment at the top of `src/index.css`: phone (base, 360 px and up), tablet
  `min-width: 768px`, wide `min-width: 1024px`, desktop `min-width: 1280px`. Use only these widths in media
  queries and name the breakpoint in a comment. Customer content sits in `.frame` (centred, max 1200 px); the
  header shows a menu button below 768 px and a top bar from 768 px (`AppLayout.tsx`). Staff screens
  (`StaffLayout.tsx`) have a sidebar from 1280 px and a slide-out menu behind a button below it. Both menus use
  `layout/useMenu.ts` for open/closed state, Escape-to-close from anywhere and focus back on the button (pass it
  the nav's ref to also move focus to its first link on opening, as Staff does); reuse it for any new menu.
- Lists of rows (Staff lists, including an Auction's Lots, and a Contract's Installments and Payments) use `components/ResponsiveList.tsx`, not
  per-page markup: give it `label`, `columns` (`{ label, cell, align?, block? }`, the first one names the row),
  `rows`, `rowKey`, and optionally `rowLink` / `dimmed` / `summary` (a total line: a table footer row, or a line
  after the cards). It renders a `<table>` from 1280 px and a list of cards
  (each value beside its column label) below, never both. Forms and action buttons inside a row go in a
  `block: true` column (as the Staff Lot actions and closed-Lot settlement do).
- Customer forms (sign-in, SMS code, Apply, Offer) and short personal screens (Application, Account, Contracts)
  sit in `.column-narrow` (~480 px, centred, at every size); a Contract in `.column-wide` (960 px). e2e checks a
  form with `expectFormColumn(field)` and the 360 px phone with `expectFitsNarrowestPhone(page)`.
- Staff sign-in is a `.column-narrow` card too. Other Staff forms (Product, Lot, new Auction) are `.staff-form`
  cards (full width on a phone, at most 760 px) and put two related fields in a `.staff-field-pair` (stacked on a
  phone, side by side from 768 px). e2e runs a Staff session at 360 px with `atNarrowestPhone(page)` and checks
  pairs with `placement(first, second)`.
- e2e: Customer sections are reached with `navigateTo(page, 'สินค้า' | 'ประมูล' | 'บัญชีของฉัน' | 'เข้าสู่ระบบ')`
  in `../eshop-infra/e2e/tests/steps.ts` (menu on phone, top bar on desktop), Staff sections with `navigateStaffTo(page, …)`
  (slide-out menu on phone, sidebar on desktop); `isPhone()` tells the projects apart. `expectResponsiveList`
  checks a list is a table on desktop and labelled cards on phone.
- Card lists (catalog Products, Auction Lots) use `ul.card-grid` (1 / 2 / 3 / 4 columns at phone / tablet / wide /
  desktop). Product and Lot pages use `.detail-layout` with `.detail-media` (photo) and `.detail-panel`: stacked
  below 1024 px, side by side from it. e2e checks layouts by position, not class: `gridColumns(list)` and
  `placement(photo, panel)` (`'beside' | 'below' | 'overlapping'`) in `../eshop-infra/e2e/tests/steps.ts`; `cardsAcross(list)` reads columns from
  the first card's width when a grid holds fewer cards than columns (an Auction with one Lot). The Lot page
  (`.lot-detail`) puts its bidding panel before the photos in the page, so it is on screen unscrolled on a phone;
  from 1024 px the photos sit left of it. That is fine for focus order only while the photo area holds nothing
  focusable.
- The image drops all capabilities: Caddy's file capability is removed with `setcap -r` and it listens on 8080.
- Service worker (ADR 0006, #59): hand-written `src/pwa/sw.js`, built to `/sw.js` by the `serviceWorker()` plugin in
  `vite.config.ts` (it injects the build's file list and a content hash), registered in production builds only.
  It pre-caches built static files and `public/offline.html` and never intercepts `/api/*`, `/images/*` or
  `/thirdparty-mock/*`; don't add runtime caching of API responses. Anything in `public/` is pre-cached, so keep
  it small. `vite dev` has no worker; test it with `vite build && vite preview` or the image.

