<script setup>
import { ref, computed } from 'vue';
import { useStorage } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import ContactSortMenu from './components/ContactSortMenu.vue';
import ContactMoreActions from './components/ContactMoreActions.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import { CONTACT_COLUMNS, DEFAULT_VISIBLE_COLUMNS } from 'dashboard/constants/contactColumns';

defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  buttonLabel: { type: String, default: '' },
  activeSort: { type: String, default: 'last_activity_at' },
  activeOrdering: { type: String, default: '' },
  isSegmentsView: { type: Boolean, default: false },
  hasActiveFilters: { type: Boolean, default: false },
  isLabelView: { type: Boolean, default: false },
  isActiveView: { type: Boolean, default: false },
});

const emit = defineEmits([
  'search',
  'filter',
  'update:sort',
  'add',
  'import',
  'createSegment',
  'deleteSegment',
]);

const showColumnSelector = ref(false);

const visibleColumnKeys = useStorage('chatwoot_contacts_table_columns', DEFAULT_VISIBLE_COLUMNS);

const toggleColumnSelector = () => {
  showColumnSelector.value = !showColumnSelector.value;
};

const closeColumnSelector = () => {
  showColumnSelector.value = false;
};

const toggleColumn = (key) => {
  if (visibleColumnKeys.value.includes(key)) {
    if (visibleColumnKeys.value.length > 1) {
      visibleColumnKeys.value = visibleColumnKeys.value.filter(k => k !== key);
    }
  } else {
    visibleColumnKeys.value.push(key);
  }
};
</script>

<template>
  <header class="sticky top-0 z-40">
    <div
      class="flex items-start sm:items-center justify-between w-full py-6 px-6 gap-2 mx-auto max-w-[60rem]"
    >
      <span class="text-xl font-medium truncate text-n-slate-12">
        {{ headerTitle }}
      </span>
      <div class="flex items-center flex-col sm:flex-row flex-shrink-0 gap-4">
        <div v-if="showSearch" class="flex items-center gap-2 w-full">
          <Input
            :model-value="searchValue"
            type="search"
            :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            class="w-full"
            @input="emit('search', $event.target.value)"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
              />
            </template>
          </Input>
        </div>
        <div class="flex items-center flex-shrink-0 gap-4">
          <div class="flex items-center gap-2">
            <div v-if="!isLabelView && !isActiveView" class="relative">
              <Button
                id="toggleContactsFilterButton"
                :icon="
                  isSegmentsView ? 'i-lucide-pen-line' : 'i-lucide-list-filter'
                "
                color="slate"
                size="sm"
                class="relative w-8"
                variant="ghost"
                @click="emit('filter')"
              >
                <div
                  v-if="hasActiveFilters && !isSegmentsView"
                  class="absolute top-0 right-0 w-2 h-2 rounded-full bg-n-brand"
                />
              </Button>
              <slot name="filter" />
            </div>
            <Button
              v-if="
                hasActiveFilters &&
                !isSegmentsView &&
                !isLabelView &&
                !isActiveView
              "
              icon="i-lucide-save"
              color="slate"
              size="sm"
              variant="ghost"
              @click="emit('createSegment')"
            />
            <Button
              v-if="isSegmentsView && !isLabelView && !isActiveView"
              icon="i-lucide-trash"
              color="slate"
              size="sm"
              variant="ghost"
              @click="emit('deleteSegment')"
            />

            <!-- Column Selector -->
            <div class="relative flex items-center">
              <Button
                icon="i-lucide-settings-2"
                variant="ghost"
                color="slate"
                size="sm"
                @click="toggleColumnSelector"
              />
              <div
                v-if="showColumnSelector"
                v-on-click-outside="closeColumnSelector"
                class="absolute top-full right-0 mt-2 z-50 flex flex-col p-2 min-w-48 bg-white dark:bg-n-solid-3 rounded-lg shadow-xl border border-n-weak"
              >
                <div
                  v-for="col in CONTACT_COLUMNS"
                  :key="col.key"
                  class="flex items-center gap-2 p-2 hover:bg-n-alpha-1 rounded cursor-pointer"
                  @click.stop="toggleColumn(col.key)"
                >
                  <Checkbox
                    :model-value="visibleColumnKeys.includes(col.key)"
                    @click.stop="toggleColumn(col.key)"
                  />
                  <span class="text-sm text-n-slate-12 select-none">{{ col.label }}</span>
                </div>
              </div>
            </div>

            <ContactSortMenu
              :active-sort="activeSort"
              :active-ordering="activeOrdering"
              @update:sort="emit('update:sort', $event)"
            />
            <ContactMoreActions
              @add="emit('add')"
              @import="emit('import')"
            />
          </div>
          <div class="w-px h-4 bg-n-strong" />
          <ComposeConversation>
            <template #trigger="{ toggle }">
              <Button :label="buttonLabel" size="sm" @click="toggle" />
            </template>
          </ComposeConversation>
        </div>
      </div>
    </div>
  </header>
</template>
