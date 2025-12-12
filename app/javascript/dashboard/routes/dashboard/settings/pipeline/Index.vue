<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

import AddPipelineStage from './AddPipelineStage.vue';
import EditPipelineStage from './EditPipelineStage.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedStage = ref({});

const records = computed(
  () => getters['pipelineStages/getPipelineStages'].value
);
const uiFlags = computed(() => getters['pipelineStages/getUIFlags'].value);

const deleteMessage = computed(() => ` ${selectedStage.value.name}?`);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  selectedStage.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedStage.value = response;
};
const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteStage = async id => {
  try {
    await store.dispatch('pipelineStages/delete', id);
    useAlert(t('PIPELINE_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('PIPELINE_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[selectedStage.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedStage.value.id] = true;
  closeDeletePopup();
  deleteStage(selectedStage.value.id);
};

const tableHeaders = computed(() => {
  return [
    t('PIPELINE_MGMT.LIST.TABLE_HEADER.NAME'),
    t('PIPELINE_MGMT.LIST.TABLE_HEADER.COLOR'),
  ];
});

onBeforeMount(() => {
  store.dispatch('pipelineStages/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('PIPELINE_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('PIPELINE_MGMT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('PIPELINE_MGMT.HEADER')"
        :description="$t('PIPELINE_MGMT.DESCRIPTION')"
        :link-text="$t('PIPELINE_MGMT.LEARN_MORE')"
        feature-name="pipeline_stages"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('PIPELINE_MGMT.HEADER_BTN_TXT')"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <table class="min-w-full overflow-x-auto divide-y divide-n-weak">
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody class="flex-1 divide-y divide-n-weak text-n-slate-12">
          <tr v-for="(stage, index) in records" :key="stage.name">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span class="mb-1 font-medium break-words text-n-slate-12">
                {{ stage.name }}
              </span>
            </td>
            <td class="py-4 leading-6 ltr:pr-4 rtl:pl-4">
              <div class="flex items-center">
                <span
                  class="w-4 h-4 mr-1 border border-solid rounded rtl:mr-0 rtl:ml-1 border-n-weak"
                  :style="{ backgroundColor: stage.color }"
                />
                {{ stage.color }}
              </div>
            </td>
            <td class="py-4 min-w-xs">
              <div class="flex gap-1 justify-end">
                <Button
                  v-tooltip.top="$t('PIPELINE_MGMT.FORM.EDIT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  :is-loading="loading[stage.id]"
                  @click="openEditPopup(stage)"
                />
                <Button
                  v-tooltip.top="$t('PIPELINE_MGMT.FORM.DELETE')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  :is-loading="loading[stage.id]"
                  @click="openDeletePopup(stage, index)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddPipelineStage @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditPipelineStage
        :selected-response="selectedStage"
        @close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('PIPELINE_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('PIPELINE_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('PIPELINE_MGMT.DELETE.CONFIRM.YES')"
      :reject-text="$t('PIPELINE_MGMT.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>
