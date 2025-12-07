<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStorage } from '@vueuse/core';
import countries from 'shared/constants/countries';
import { formatDistanceToNow } from 'date-fns';
import { useMapGetter } from 'dashboard/composables/store';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import { CONTACT_COLUMNS, DEFAULT_VISIBLE_COLUMNS } from 'dashboard/constants/contactColumns';

const props = defineProps({
  contacts: { type: Array, required: true },
  selectedContactIds: { type: Array, default: () => [] },
});

const emit = defineEmits(['toggleContact', 'showContact', 'toggleAllContacts']);

const { t } = useI18n();
const allLabels = useMapGetter('labels/getLabels');

// Shared storage key with ContactHeader.vue
const visibleColumnKeys = useStorage('chatwoot_contacts_table_columns', DEFAULT_VISIBLE_COLUMNS);

const visibleColumns = computed(() =>
  CONTACT_COLUMNS.filter(col => visibleColumnKeys.value.includes(col.key))
);

const countriesMap = computed(() => {
  return countries.reduce((acc, country) => {
    acc[country.code] = country;
    acc[country.id] = country;
    return acc;
  }, {});
});

const getCountryName = (code) => countriesMap.value[code]?.name || code;

const isSelected = (id) => props.selectedContactIds.includes(id);

const handleSelect = (id, checked) => {
  emit('toggleContact', { id, value: checked });
};

const isAllSelected = computed(() => {
    return props.contacts.length > 0 && props.selectedContactIds.length === props.contacts.length;
});

const isIndeterminate = computed(() => {
    return props.selectedContactIds.length > 0 && props.selectedContactIds.length < props.contacts.length;
});

const toggleSelectAll = () => {
    if (isAllSelected.value) {
        emit('toggleAllContacts', false);
    } else {
        emit('toggleAllContacts', true);
    }
};

const timeAgo = (date) => {
    if (!date) return '';
    return formatDistanceToNow(new Date(date), { addSuffix: true });
};

// Helper to get label details from name or object
const getLabelData = (label) => {
    if (typeof label === 'string') {
        const found = allLabels.value.find(l => l.title === label);
        return found || { title: label, color: '#000000' };
    }
    return label;
};
</script>

<template>
  <div class="flex flex-col gap-4">


    <div class="overflow-x-auto border border-n-weak rounded-lg">
      <table class="w-full text-left text-sm whitespace-nowrap">
        <thead class="bg-n-alpha-1 text-n-slate-11 font-medium border-b border-n-weak">
          <tr>
            <th class="px-4 py-3 w-10">
                <Checkbox
                    :model-value="isAllSelected"
                    :indeterminate="isIndeterminate"
                     @click.stop="toggleSelectAll"
                />
            </th>
            <th v-for="col in visibleColumns" :key="col.key" class="px-4 py-3">
              {{ col.label }}
            </th>
            <th class="px-4 py-3 w-20">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-weak bg-n-background">
            <tr
                v-for="contact in contacts"
                :key="contact.id"
                class="hover:bg-n-alpha-1 transition-colors"
                @click="handleRowClick(contact.id)"
            >
                <td class="px-4 py-3">
                    <Checkbox
                        :model-value="isSelected(contact.id)"
                        @change="(e) => handleSelect(contact.id, e.target.checked)"
                    />
                </td>
                
                <td v-if="visibleColumnKeys.includes('name')" class="px-4 py-3">
                    <div class="flex items-center gap-3">
                        <Avatar
                            :name="contact.name"
                            :src="contact.thumbnail"
                            :size="24"
                            rounded-full
                        />
                        <span class="text-n-slate-12 font-medium">{{ contact.name }}</span>
                    </div>
                </td>

                <td v-if="visibleColumnKeys.includes('email')" class="px-4 py-3 text-n-slate-11">
                    {{ contact.email }}
                </td>

                <td v-if="visibleColumnKeys.includes('phone_number')" class="px-4 py-3 text-n-slate-11">
                    {{ contact.phoneNumber }}
                </td>

                <td v-if="visibleColumnKeys.includes('company_name')" class="px-4 py-3 text-n-slate-11">
                     {{ contact.additionalAttributes?.companyName }}
                </td>

                <td v-if="visibleColumnKeys.includes('city')" class="px-4 py-3 text-n-slate-11">
                     {{ contact.additionalAttributes?.city }}
                </td>

                 <td v-if="visibleColumnKeys.includes('country')" class="px-4 py-3 text-n-slate-11">
                    <div v-if="contact.additionalAttributes?.country" class="flex items-center gap-2">
                        <Flag :country="contact.additionalAttributes?.country" class="size-4" />
                        <span>{{ getCountryName(contact.additionalAttributes?.country) }}</span>
                    </div>
                </td>
                
                <td v-if="visibleColumnKeys.includes('tags')" class="px-4 py-3 text-n-slate-11">
                    <div v-if="contact.labels" class="flex items-center gap-1 flex-wrap max-w-xs">
                        <div 
                            v-for="label in contact.labels" 
                            :key="label" 
                            class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border border-n-weak"
                        >
                             <div
                                class="w-1.5 h-1.5 rounded-full mr-1.5"
                                :style="{ backgroundColor: getLabelData(label).color }"
                            />
                            {{ getLabelData(label).title || label }}
                        </div>
                    </div>
                </td>

                <td v-if="visibleColumnKeys.includes('last_activity_at')" class="px-4 py-3 text-n-slate-11">
                    {{ timeAgo(contact.lastActivityAt) }}
                </td>

                <td class="px-4 py-3">
                    <Button
                        icon="i-lucide-external-link"
                        variant="ghost"
                        color="slate"
                        size="xs"
                        @click="emit('showContact', contact.id)"
                    />
                </td>
            </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
