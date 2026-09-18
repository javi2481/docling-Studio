<template>
  <section class="analysis-detail">
    <div v-if="loading" class="state">{{ t('analyses.loading') }}</div>
    <div v-else-if="error || !analysis" class="state state--error">{{ t('analyses.failed') }}</div>
    <template v-else>
      <header class="detail-header">
        <RouterLink :to="{ name: ROUTES.ANALYSES }" class="back-link">
          ← {{ t('analyses.title') }}
        </RouterLink>
        <div>
          <p class="eyebrow">{{ analysis.status }}</p>
          <h1>{{ analysis.documentFilename || analysis.documentId }}</h1>
          <p class="meta">{{ analysis.id }} · {{ formatDate(analysis.createdAt) }}</p>
        </div>
        <div class="detail-actions">
          <DownloadDropdown :doc-id="analysis.documentId" />
        </div>
      </header>
      <nav class="detail-tabs" data-e2e="analysis-detail-tabs" aria-label="Analysis views">
        <button
          type="button"
          class="detail-tab"
          :class="{ active: viewTab === 'parse' }"
          data-e2e="analysis-tab-parse"
          @click="viewTab = 'parse'"
        >
          {{ t('breadcrumb.mode.parse') }}
        </button>
        <button
          type="button"
          class="detail-tab"
          :class="{ active: viewTab === 'chunk' }"
          data-e2e="analysis-tab-chunk"
          @click="viewTab = 'chunk'"
        >
          {{ t('breadcrumb.mode.chunk') }}
        </button>
        <button
          type="button"
          class="detail-tab"
          :class="{ active: viewTab === 'graph' }"
          data-e2e="analysis-tab-graph"
          @click="viewTab = 'graph'"
        >
          {{ t('studio.maintain') }}
        </button>
      </nav>
      <DocParseTab
        v-if="viewTab === 'parse'"
        :doc-id="analysis.documentId"
        :analysis-id="analysis.id"
      />
      <DocChunkTab
        v-else-if="viewTab === 'chunk'"
        :doc-id="analysis.documentId"
        :available-stores="[]"
      />
      <div v-else class="graph-tab" data-e2e="analysis-graph-tab">
        <GraphView :doc-id="analysis.documentId" />
      </div>
    </template>
  </section>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchAnalysis } from '../features/analysis/api'
import GraphView from '../features/analysis/ui/GraphView.vue'
import type { Analysis } from '../shared/types'
import { useI18n } from '../shared/i18n'
import { ROUTES } from '../shared/routing/names'
import DocParseTab from './DocParseTab.vue'
import DocChunkTab from './DocChunkTab.vue'
import DownloadDropdown from '../features/document/ui/DownloadDropdown.vue'

const props = defineProps<{ id: string }>()
const { t } = useI18n()
const analysis = ref<Analysis | null>(null)
const loading = ref(true)
const error = ref(false)
const viewTab = ref<'parse' | 'chunk' | 'graph'>('parse')

function formatDate(value: string): string {
  return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(
    new Date(value),
  )
}

onMounted(async () => {
  try {
    analysis.value = await fetchAnalysis(props.id)
  } catch {
    error.value = true
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.analysis-detail {
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.detail-header {
  display: flex;
  align-items: flex-start;
  gap: 20px;
  flex-shrink: 0;
  padding: 18px 24px 14px;
  border-bottom: 1px solid var(--border);
}
.back-link {
  display: inline-block;
  margin-bottom: 14px;
  color: var(--accent);
  font-size: 12px;
  text-decoration: none;
}
.eyebrow {
  color: var(--accent);
  font:
    500 11px 'IBM Plex Mono',
    monospace;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}
h1 {
  margin-top: 3px;
  font-size: 20px;
}
.meta {
  margin-top: 3px;
  color: var(--text-muted);
  font:
    11px 'IBM Plex Mono',
    monospace;
}
.detail-actions {
  margin-left: auto;
}
.detail-tabs {
  display: flex;
  gap: 4px;
  flex-shrink: 0;
  padding: 8px 24px 0;
  border-bottom: 1px solid var(--border);
}
.detail-tab {
  padding: 8px 14px;
  border: none;
  border-bottom: 2px solid transparent;
  background: transparent;
  color: var(--text-secondary);
  font-size: 13px;
  cursor: pointer;
}
.detail-tab:hover {
  color: var(--text-primary);
}
.detail-tab.active {
  color: var(--accent);
  border-bottom-color: var(--accent);
}
.analysis-detail :deep(.parse-tab),
.analysis-detail :deep(.chunk-tab),
.graph-tab {
  min-height: 0;
  flex: 1;
}
.graph-tab {
  display: flex;
  flex-direction: column;
  overflow: hidden;
  padding: 12px 16px;
}
.state {
  padding: 56px 24px;
  color: var(--text-secondary);
}
.state--error {
  color: var(--error);
}
</style>
