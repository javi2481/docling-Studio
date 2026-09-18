import type { RouteLocationNormalized, RouteRecordRaw } from 'vue-router'

import { parseMode } from '../../shared/routing/modes'
import { ROUTES } from '../../shared/routing/names'

/**
 * Route table used by the production router and by tests.
 *
 * Lives in its own file so importing the router definition doesn't
 * trigger `createWebHistory()` (which needs `window` and breaks the
 * default node-environment vitest tests). Tests build a router with
 * `createMemoryHistory()` over this same table.
 */
export const routes: RouteRecordRaw[] = [
  // ---------------------------------------------------------------------------
  // Legacy routes — kept functional during the 0.6.0 transition.
  // ---------------------------------------------------------------------------
  {
    path: '/',
    name: ROUTES.HOME,
    component: () => import('../../pages/HomePage.vue'),
  },
  {
    path: '/studio',
    name: ROUTES.STUDIO,
    component: () => import('../../pages/StudioPage.vue'),
  },
  {
    path: '/history',
    name: ROUTES.HISTORY,
    component: () => import('../../pages/HistoryPage.vue'),
  },
  {
    path: '/analyses',
    name: ROUTES.ANALYSES,
    component: () => import('../../pages/AnalysesPage.vue'),
  },
  {
    path: '/analyses/:id',
    name: ROUTES.ANALYSIS_DETAIL,
    component: () => import('../../pages/AnalysisDetailPage.vue'),
    props: true,
  },
  {
    path: '/documents',
    name: ROUTES.DOCUMENTS,
    component: () => import('../../pages/DocumentsPage.vue'),
  },
  {
    path: '/search',
    name: ROUTES.SEARCH,
    component: () => import('../../pages/SearchPage.vue'),
  },
  // #303 — the standalone /reasoning workspace was retired; reasoning now
  // lives inside the doc workspace's Parse view. Redirect circulating deep
  // links so shared URLs don't 404 (mode defaults to parse on /docs/:id).
  {
    path: '/reasoning',
    redirect: '/docs',
  },
  {
    path: '/reasoning/:docId',
    redirect: (to) => `/docs/${to.params.docId}`,
  },
  {
    path: '/settings',
    name: ROUTES.SETTINGS,
    component: () => import('../../pages/SettingsPage.vue'),
  },

  // ---------------------------------------------------------------------------
  // 0.6.0 — Document-centric routes (#207). Placeholder pages until E3/E4/E5
  // implement them; the legacy routes above keep working in parallel.
  // ---------------------------------------------------------------------------
  {
    path: '/docs',
    name: ROUTES.DOCS_LIBRARY,
    component: () => import('../../pages/DocsLibraryPage.vue'),
  },
  {
    path: '/docs/new',
    name: ROUTES.DOCS_NEW,
    component: () => import('../../pages/DocsNewPage.vue'),
  },
  {
    path: '/docs/:id',
    name: ROUTES.DOC_WORKSPACE,
    component: () => import('../../pages/DocWorkspacePage.vue'),
    props: (route: RouteLocationNormalized) => ({
      id: String(route.params.id),
      mode: parseMode(route.query.mode),
    }),
  },
  {
    path: '/ingest',
    name: ROUTES.STORES_LIST,
    component: () => import('../../pages/StoresListPage.vue'),
  },
  {
    path: '/ingest/new',
    name: ROUTES.STORE_CREATE,
    component: () => import('../../pages/StoreCreatePage.vue'),
  },
  {
    path: '/ingest/:store',
    name: ROUTES.STORE_DETAIL,
    component: () => import('../../pages/StoreDetailPage.vue'),
    props: true,
  },
  {
    path: '/ingest/:store/edit',
    name: ROUTES.STORE_EDIT,
    component: () => import('../../pages/StoreEditPage.vue'),
    props: true,
  },
  {
    path: '/ingest/:store/query',
    name: ROUTES.STORE_QUERY,
    component: () => import('../../pages/StoreQueryPage.vue'),
    props: true,
  },
  // Legacy `/index/*` → `/ingest/*`
  { path: '/index', redirect: '/ingest' },
  { path: '/index/new', redirect: '/ingest/new' },
  {
    path: '/index/:store',
    redirect: (to) => `/ingest/${to.params.store}`,
  },
  {
    path: '/index/:store/edit',
    redirect: (to) => `/ingest/${to.params.store}/edit`,
  },
  {
    path: '/index/:store/query',
    redirect: (to) => `/ingest/${to.params.store}/query`,
  },
  {
    path: '/runs',
    name: ROUTES.RUNS,
    redirect: { name: ROUTES.ANALYSES },
  },
  {
    path: '/runs/:id',
    name: ROUTES.RUN_DETAIL,
    redirect: (to) => ({ name: ROUTES.ANALYSIS_DETAIL, params: { id: to.params.id } }),
  },

  // ---------------------------------------------------------------------------
  // 404 — must come last.
  // ---------------------------------------------------------------------------
  {
    path: '/:pathMatch(.*)*',
    name: ROUTES.NOT_FOUND,
    redirect: '/',
  },
]
