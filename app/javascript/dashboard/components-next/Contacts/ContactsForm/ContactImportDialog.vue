<script setup>
import { ref, computed, reactive, watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { CONTACT_COLUMNS } from 'dashboard/constants/contactColumns';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['import']);
const { t } = useI18n();

const uiFlags = useMapGetter('contacts/getUIFlags');
const customAttributes = useMapGetter('attributes/getContactAttributes');
const isImportingContact = computed(() => uiFlags.value.isImporting);

const dialogRef = ref(null);
const fileInput = ref(null);

const hasSelectedFile = ref(null);
const selectedFileName = ref('');
const csvHeaders = ref([]);
const columnMapping = reactive({});

const csvUrl = '/downloads/import-contacts-sample.csv';

const targetAttributes = computed(() => {
    const standard = CONTACT_COLUMNS.filter(c => c.key !== 'last_activity_at').map(c => ({ 
        key: c.key === 'company_name' ? 'company' : c.key, 
        label: c.label 
    })); // remove read-only or irrelevant and map company_name to company
    const custom = customAttributes.value.map(attr => ({
        key: attr.attributeKey,
        label: attr.attributeDisplayName,
        iCustom: true
    }));
    return [...standard, ...custom].filter(a => a.key !== 'tags'); // Tags might be special? Keep them for now if backend supports.
});

const isValidMapping = computed(() => {
    // Return true if at least one column is mapped, or if we allow importing without mapping (backend defaults)
    // Actually, letting user map nothing is fine (empty import), but usually they should map Name or Email.
    return true; 
});

const handleFileClick = () => fileInput.value?.click();

const processFileName = fileName => {
  const lastDotIndex = fileName.lastIndexOf('.');
  const extension = fileName.slice(lastDotIndex);
  const baseName = fileName.slice(0, lastDotIndex);

  return baseName.length > 20
    ? `${baseName.slice(0, 20)}...${extension}`
    : fileName;
};

// Simple CSV Line Parser that handles quotes
const parseCSVLine = (text) => {
    const re_valid = /^\s*(?:'[^'\\]*(?:\\[\S\s][^'\\]*)*'|"[^"\\]*(?:\\[\S\s][^"\\]*)*"|[^,'"\s\\]*(?:\s+[^,'"\s\\]+)*)\s*(?:,\s*(?:'[^'\\]*(?:\\[\S\s][^'\\]*)*'|"[^"\\]*(?:\\[\S\s][^"\\]*)*"|[^,'"\s\\]*(?:\s+[^,'"\s\\]+)*)\s*)*$/;
    
    // Fallback split if regex is too complex/slow, but for headers it should be fine.
    // Using simple split for robustness in this environment without heavy libraries
    // Splitting by comma, ignoring commas inside double quotes
    const matches = text.match(/(".*?"|[^",\s]+)(?=\s*,|\s*$)/g) || text.split(',');
    return matches.map(m => m.replace(/^"|"$/g, '').trim());
};

const parseFileHeaders = (file) => {
    const reader = new FileReader();
    reader.onload = (e) => {
        const text = e.target.result;
        const firstLine = text.split(/\r\n|\n/)[0];
        if (firstLine) {
            // Rudimentary parsing: split by comma if no quotes, else try basic regex
            if (firstLine.includes('"')) {
                 csvHeaders.value = firstLine.match(/(".*?"|[^",]+)(?=\s*,|\s*$)/g).map(h => h.replace(/^"|"$/g, '').trim());
            } else {
                 csvHeaders.value = firstLine.split(',').map(h => h.trim());
            }
            autoMapColumns();
        }
    };
    reader.readAsText(file);
};

const autoMapColumns = () => {
    // Reset mapping
    Object.keys(columnMapping).forEach(key => delete columnMapping[key]);
    
    // Try to find matches
    targetAttributes.value.forEach(attr => {
        const match = csvHeaders.value.find(h => h.toLowerCase().replace(/_/g, '') === attr.label.toLowerCase().replace(/\s/g, ''));
        if (match) {
            columnMapping[attr.key] = match;
        }
        // Special case for Name/Email
        if (attr.key === 'email' && !columnMapping['email']) {
             const emailHeader = csvHeaders.value.find(h => h.toLowerCase().includes('email'));
             if (emailHeader) columnMapping['email'] = emailHeader;
        }
        if (attr.key === 'name' && !columnMapping['name']) {
             const nameHeader = csvHeaders.value.find(h => h.toLowerCase().includes('name'));
             if (nameHeader) columnMapping['name'] = nameHeader;
        }
    });
};

const handleFileChange = () => {
  const file = fileInput.value?.files[0];
  hasSelectedFile.value = file;
  selectedFileName.value = file ? processFileName(file.name) : '';
  if (file) {
      parseFileHeaders(file);
  } else {
      csvHeaders.value = [];
  }
};

const handleRemoveFile = () => {
  hasSelectedFile.value = null;
  if (fileInput.value) {
    fileInput.value.value = null;
  }
  selectedFileName.value = '';
  csvHeaders.value = [];
};

const uploadFile = async () => {
  if (!hasSelectedFile.value) return;
  emit('import', { file: hasSelectedFile.value, mapping: columnMapping });
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.TITLE')"
    :confirm-button-label="
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.IMPORT')
    "
    :is-loading="isImportingContact"
    :disable-confirm-button="isImportingContact || (hasSelectedFile && !isValidMapping)"
    @confirm="uploadFile"
  >
    <template #description>
      <p class="mb-4 text-sm text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DESCRIPTION') }}
        <a
          :href="csvUrl"
          target="_blank"
          rel="noopener noreferrer"
          download="import-contacts-sample.csv"
          class="text-n-blue-text"
        >
          {{
            t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DOWNLOAD_LABEL')
          }}
        </a>
      </p>
    </template>

    <div class="flex flex-col gap-4">
      <div class="flex items-center gap-2">
        <label class="text-sm text-n-slate-12 whitespace-nowrap">
          {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.LABEL') }}
        </label>
        <div class="flex items-center justify-between w-full gap-2">
          <span v-if="hasSelectedFile" class="text-sm text-n-slate-12">
            {{ selectedFileName }}
          </span>
          <Button
            v-if="!hasSelectedFile"
            :label="
              t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.CHOOSE_FILE')
            "
            icon="i-lucide-upload"
            color="slate"
            variant="ghost"
            size="sm"
            class="!w-fit"
            @click="handleFileClick"
          />
          <div v-else class="flex items-center gap-1">
            <Button
              :label="t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.CHANGE')"
              color="slate"
              variant="ghost"
              size="sm"
              @click="handleFileClick"
            />
            <div class="w-px h-3 bg-n-strong" />
            <Button
              icon="i-lucide-trash"
              color="slate"
              variant="ghost"
              size="sm"
              @click="handleRemoveFile"
            />
          </div>
        </div>
      </div>

      <div v-if="hasSelectedFile && csvHeaders.length" class="flex flex-col gap-3 mt-2 border-t border-n-weak pt-4">
        <h4 class="text-sm font-medium text-n-slate-12">
          Map Columns
        </h4>
        <div class="grid grid-cols-2 gap-4">
            <div class="text-xs font-medium text-n-slate-11">Contact Attribute</div>
            <div class="text-xs font-medium text-n-slate-11">CSV Column</div>
        </div>
        <div class="max-h-60 overflow-y-auto flex flex-col gap-2">
            <div
                v-for="attr in targetAttributes"
                :key="attr.key"
                class="grid grid-cols-2 gap-4 items-center"
            >
                <div class="text-sm text-n-slate-12">{{ attr.label }}</div>
                <select
                    v-model="columnMapping[attr.key]"
                    class="h-8 rounded-md border-n-weak bg-n-alpha-1 text-sm text-n-slate-12 px-2 focus:ring-1 focus:ring-n-brand focus:border-n-brand"
                >
                    <option :value="undefined">Skip</option>
                    <option
                        v-for="header in csvHeaders"
                        :key="header"
                        :value="header"
                    >
                        {{ header }}
                    </option>
                </select>
            </div>
        </div>
      </div>
    </div>
    <input
      ref="fileInput"
      type="file"
      accept="text/csv"
      class="hidden"
      @change="handleFileChange"
    />
  </Dialog>
</template>
