<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const store = useStore();
const { t } = useI18n();

const pipelineStages = computed(
  () => store.getters['pipelineStages/getPipelineStages']
);

const pipelineStagesList = computed(() => {
  return pipelineStages.value.map(stage => ({
    id: stage.id,
    name: stage.name,
    thumbnail: {
      name: 'span',
      content: '',
      style: {
        backgroundColor: stage.color,
        width: '12px',
        height: '12px',
        borderRadius: '50%',
        display: 'inline-block',
        marginRight: '8px',
        border: '1px solid var(--color-border)',
      },
    },
  }));
});

const assignedPipelineStage = computed(() => {
  if (!props.selectedContact || !props.selectedContact.pipeline_stage_id)
    return null;
  const stage = pipelineStages.value.find(
    s => s.id === props.selectedContact.pipeline_stage_id
  );
  if (!stage) return null;
  return {
    id: stage.id,
    name: stage.name,
    thumbnail: {
      name: 'span',
      content: '',
      style: {
        backgroundColor: stage.color,
        width: '12px',
        height: '12px',
        borderRadius: '50%',
        display: 'inline-block',
        marginRight: '8px',
        border: '1px solid var(--color-border)',
      },
    },
  };
});

const updatePipelineStage = selectedStage => {
  const currentStageId = assignedPipelineStage.value?.id;
  const newStageId = selectedStage?.id;

  // If clicking the same stage, deselect it (set to null)
  const stageIdToUpdate = currentStageId === newStageId ? null : newStageId;

  store
    .dispatch('contacts/update', {
      id: props.selectedContact.id,
      pipeline_stage_id: stageIdToUpdate,
    })
    .then(() => {
      useAlert(t('PIPELINE_MGMT.NOTIFICATIONS.UPDATE_SUCCESS'));
    })
    .catch(() => {
      useAlert(t('PIPELINE_MGMT.NOTIFICATIONS.UPDATE_ERROR'));
    });
};

onMounted(() => {
  store.dispatch('pipelineStages/get');
});
</script>

<template>
  <div class="px-6 py-6 border-b border-n-slate-3 dark:border-n-slate-1">
    <div class="flex flex-col gap-2">
      <span class="text-sm font-medium text-n-slate-12">
        {{ t('SIDEBAR.PIPELINE_STAGES') }}
      </span>
      <MultiselectDropdown
        :options="pipelineStagesList"
        :selected-item="assignedPipelineStage"
        :multiselector-title="$t('PIPELINE_MGMT.MULTI_SELECTOR.TITLE')"
        :multiselector-placeholder="
          $t('PIPELINE_MGMT.MULTI_SELECTOR.PLACEHOLDER')
        "
        :no-search-result="$t('PIPELINE_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS')"
        :input-placeholder="
          $t('PIPELINE_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER')
        "
        @select="updatePipelineStage"
      />
    </div>
  </div>
</template>
