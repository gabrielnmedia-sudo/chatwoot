<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStorage } from '@vueuse/core';
import countries from 'shared/constants/countries';
import { formatDistanceToNow } from 'date-fns';
import { vOnClickOutside } from '@vueuse/components';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';

const props = defineProps({
  contacts: { type: Array, required: true },
  selectedContactIds: { type: Array, default: () => [] },
});

const emit = defineEmits(['toggleContact', 'showContact', 'toggleAllContacts']);

const { t } = useI18n();
const showColumnSelector = ref(false);

const availableColumns = [
  { key: 'name', label: 'Name' },
  { key: 'email', label: 'Email' },
  { key: 'phone_number', label: 'Phone Number' },
  { key: 'company_name', label: 'Company' },
  { key: 'city', label: 'City' },
  { key: 'country', label: 'Country' },
  { key: 'last_activity_at', label: 'Last Activity' },
];

const visibleColumnKeys = useStorage('chatwoot_contacts_table_columns', [
  'name',
  'email',
  'phone_number',
  'company_name',
  'last_activity_at',
]);

const visibleColumns = computed(() =>
  availableColumns.filter(col => visibleColumnKeys.value.includes(col.key))
);

const countriesMap = computed(() => {
  return countries.reduce((acc, country) => {
    acc[country.code] = country;
    acc[country.id] = country;
    return acc;
  }, {});
});

const getCountryName = (code) => countriesMap.value[code]?.name || code;

const toggleColumn = (key) => {
  if (visibleColumnKeys.value.includes(key)) {
    if (visibleColumnKeys.value.length > 1) {
      visibleColumnKeys.value = visibleColumnKeys.value.filter(k => k !== key);
    }
  } else {
    visibleColumnKeys.value.push(key);
  }
};

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
        // Deselect all
        props.contacts.forEach(contact => {
             if (isSelected(contact.id)) {
                 emit('toggleContact', { id: contact.id, value: false });
             }
        });
        // Alternatively, if the parent can handle bulk deselect:
        // emit('toggleAllContacts', false);
    } else {
        // Select all
        const allIds = props.contacts.map(c => c.id);
         // This might be inefficient to emit one by one. 
         // Better to emit a new event or rely on parent handling.
         // Given the current interface 'toggleContact' takes single ID, 
         // let's assume we iterate or if we can change the parent logic.
         // Let's stick to iterating for now or better, update the ContactsIndex to handle 'toggleAllContacts'
         
         // Actually, let's emit a bulk event 'toggleSelectAll'
          emit('toggleAllContacts', !isAllSelected.value);
    }
};

const timeAgo = (date) => {
    if (!date) return '';
    return formatDistanceToNow(new Date(date), { addSuffix: true });
};

const toggleColumnSelector = () => {
    showColumnSelector.value = !showColumnSelector.value;
};

const closeColumnSelector = () => {
    showColumnSelector.value = false;
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex justify-end relative">
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
            class="absolute top-full right-0 mt-2 z-10 flex flex-col p-2 min-w-48 bg-white dark:bg-n-solid-3 rounded-lg shadow-xl border border-n-weak"
        >
            <div
                v-for="col in availableColumns"
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
