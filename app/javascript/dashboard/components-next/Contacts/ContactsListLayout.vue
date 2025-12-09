<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStorage } from '@vueuse/core';

import ContactListHeaderWrapper from 'dashboard/components-next/Contacts/ContactsHeader/ContactListHeaderWrapper.vue';
import ContactsActiveFiltersPreview from 'dashboard/components-next/Contacts/ContactsHeader/components/ContactsActiveFiltersPreview.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import ContactImportHistory from 'dashboard/components-next/Contacts/ContactImportHistory.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  showPaginationFooter: { type: Boolean, default: true },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 100 },
  itemsPerPage: { type: Number, default: 15 },
  activeSort: { type: String, default: '' },
  activeOrdering: { type: String, default: '' },
  activeSegment: { type: Object, default: null },
  segmentsId: { type: [String, Number], default: 0 },
  hasAppliedFilters: { type: Boolean, default: false },
  isFetchingList: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:currentPage',
  'update:sort',
  'search',
  'applyFilter',
  'clearFilters',
]);

const route = useRoute();

const contactListHeaderWrapper = ref(null);
const isSidebarOpen = useStorage('chatwoot_contact_import_sidebar_open', false);

const isNotSegmentView = computed(() => {
  return route.name !== 'contacts_dashboard_segments_index';
});

const isActiveView = computed(() => {
  return route.name === 'contacts_dashboard_active';
});

const isLabelView = computed(
  () => route.name === 'contacts_dashboard_labels_index'
);

const showActiveFiltersPreview = computed(() => {
  return (
    (props.hasAppliedFilters || !isNotSegmentView.value) &&
    !props.isFetchingList &&
    !isLabelView.value &&
    !isActiveView.value
  );
});

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};

const openFilter = () => {
  contactListHeaderWrapper.value?.onToggleFilters();
};
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background relative"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <ContactListHeaderWrapper
        ref="contactListHeaderWrapper"
        :show-search="isNotSegmentView && !isActiveView"
        :search-value="searchValue"
        :active-sort="activeSort"
        :active-ordering="activeOrdering"
        :header-title="headerTitle"
        :active-segment="activeSegment"
        :segments-id="segmentsId"
        :has-applied-filters="hasAppliedFilters"
        :is-label-view="isLabelView"
        :is-active-view="isActiveView"
        @update:sort="emit('update:sort', $event)"
        @search="emit('search', $event)"
        @apply-filter="emit('applyFilter', $event)"
        @clear-filters="emit('clearFilters')"
      />
      <main class="flex-1 overflow-y-auto">
        <div class="w-full mx-auto">
          <ContactsActiveFiltersPreview
            v-if="showActiveFiltersPreview"
            :active-segment="activeSegment"
            @clear-filters="emit('clearFilters')"
            @open-filter="openFilter"
          />
          <slot name="default" />
        </div>
      </main>
      <footer v-if="showPaginationFooter" class="sticky bottom-0 z-0 px-4 pb-4">
        <PaginationFooter
          current-page-info="CONTACTS_LAYOUT.PAGINATION_FOOTER.SHOWING"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
    
    <ContactImportHistory 
      v-if="isSidebarOpen" 
      @close="isSidebarOpen = false" 
    />

    <div v-else class="absolute top-4 right-4 z-50">
      <Button
        icon="i-lucide-history"
        variant="outline"
        color="slate"
        size="sm"
        @click="isSidebarOpen = true"
      />
    </div>
  </section>
</template>
