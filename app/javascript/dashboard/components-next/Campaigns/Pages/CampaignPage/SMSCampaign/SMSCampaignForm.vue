<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, minValue } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { addMinutes, addHours, addDays } from 'date-fns';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getSMSInboxes'),
};

const DELAY_TYPES = {
  MINUTES: 'minutes',
  HOURS: 'hours',
  DAYS: 'days',
};

const createEmptySequence = (isFirst = false) => ({
  message: '',
  // For the first item we use scheduledAt, for others we use delay
  scheduledAt: isFirst ? null : undefined,
  delayValue: isFirst ? undefined : 0,
  delayType: isFirst ? undefined : DELAY_TYPES.HOURS,
});

const initialState = {
  title: '',
  inboxId: null,
  selectedAudience: [],
  sequences: [createEmptySequence(true)],
};

const state = reactive({
  ...initialState,
  sequences: [createEmptySequence(true)], // Reactive array needs explicit initialization in reactive() or reset
});

const rules = {
  title: { required, minLength: minLength(1) },
  inboxId: { required },
  selectedAudience: { required },
  sequences: {
    required,
    $each: {
      message: { required, minLength: minLength(1) },
      scheduledAt: {
        requiredIf: (value, object) => object.scheduledAt !== undefined,
      },
      delayValue: {
        requiredIf: (value, object) => object.delayValue !== undefined,
        minValue: minValue(0),
      },
    },
  },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

const currentDateTime = computed(() => {
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({
    value: item[valueKey],
    label: item[labelKey],
  })) ?? [];

const audienceList = computed(() =>
  mapToOptions(formState.labels.value, 'id', 'title')
);

const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);

const delayOptions = [
  { value: DELAY_TYPES.MINUTES, label: t('CAMPAIGN.SMS.CREATE.FORM.DELAY.MINUTES') },
  { value: DELAY_TYPES.HOURS, label: t('CAMPAIGN.SMS.CREATE.FORM.DELAY.HOURS') },
  { value: DELAY_TYPES.DAYS, label: t('CAMPAIGN.SMS.CREATE.FORM.DELAY.DAYS') },
];

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.SMS.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

// Helper for sequence errors
// Helper for sequence errors
const getSequenceErrorMessage = (index, field) => {
  if (!v$.value.sequences?.$each?.[index]) return '';
  const fieldModel = v$.value.sequences.$each[index][field];
  return fieldModel?.$error ? t('CAMPAIGN.SMS.CREATE.FORM.REQUIRED_ERROR') : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
}));

const isSubmitDisabled = computed(() => v$.value.$invalid);

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const addSequence = () => {
  state.sequences.push(createEmptySequence(false));
};

const removeSequence = index => {
  if (state.sequences.length > 1) {
    state.sequences.splice(index, 1);
  }
};

const resetState = () => {
  Object.assign(state, {
    ...initialState,
    sequences: [createEmptySequence(true)],
  });
  v$.value.$reset();
};

const handleCancel = () => emit('cancel');

const calculateScheduledAt = (baseDate, delayValue, delayType) => {
  const date = new Date(baseDate);
  if (!delayValue) return date;

  switch (delayType) {
    case DELAY_TYPES.MINUTES:
      return addMinutes(date, parseInt(delayValue));
    case DELAY_TYPES.HOURS:
      return addHours(date, parseInt(delayValue));
    case DELAY_TYPES.DAYS:
      return addDays(date, parseInt(delayValue));
    default:
      return date;
  }
};

const prepareCampaignDetails = () => {
  const campaigns = [];
  let currentScheduledAt = new Date(state.sequences[0].scheduledAt);

  state.sequences.forEach((sequence, index) => {
    // If it's not the first valid sequence, calculate time based on previous
    if (index > 0) {
      currentScheduledAt = calculateScheduledAt(
        currentScheduledAt,
        sequence.delayValue,
        sequence.delayType
      );
    }

    const titleSuffix = index === 0 ? '' : ` - Step ${index + 1}`;
    
    // Validate that we have a valid time (sanity check)
    if (isNaN(currentScheduledAt.getTime())) {
       // fallback or error handling if needed
    }

    campaigns.push({
      title: `${state.title}${titleSuffix}`,
      message: sequence.message,
      inbox_id: state.inboxId,
      scheduled_at: currentScheduledAt.toISOString(), // Send UTC ISO string
      audience: state.selectedAudience?.map(id => ({
        id,
        type: 'Label',
      })),
    });
  });

  return campaigns;
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareCampaignDetails());
  resetState();
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.title"
      :label="t('CAMPAIGN.SMS.CREATE.FORM.TITLE.LABEL')"
      :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.TITLE.PLACEHOLDER')"
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.SMS.CREATE.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label for="audience" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.SMS.CREATE.FORM.AUDIENCE.LABEL') }}
      </label>
      <TagMultiSelectComboBox
        v-model="state.selectedAudience"
        :options="audienceList"
        :label="t('CAMPAIGN.SMS.CREATE.FORM.AUDIENCE.LABEL')"
        :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.AUDIENCE.PLACEHOLDER')"
        :has-error="!!formErrors.audience"
        :message="formErrors.audience"
        class="[&>div>button]:bg-n-alpha-black2"
      />
    </div>

    <!-- Sequence List -->
    <div class="flex flex-col gap-4">
      <div 
        v-for="(sequence, index) in state.sequences" 
        :key="index"
        class="p-4 border border-n-weak rounded-lg bg-n-alpha-1 flex flex-col gap-3 relative"
      >
        <div class="flex justify-between items-center">
          <span class="text-sm font-semibold text-n-slate-12">
            {{ index === 0 ? t('CAMPAIGN.SMS.CREATE.FORM.MESSAGE.LABEL') : `${t('CAMPAIGN.SMS.CREATE.FORM.MESSAGE.LABEL')} ${index + 1}` }}
          </span>
          <Button
            v-if="index > 0"
            icon="i-lucide-trash"
            variant="ghost" 
            color="ruby" 
            size="sm"
            @click="removeSequence(index)"
            type="button"
          />
        </div>

        <TextArea
          v-model="sequence.message"
          :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.MESSAGE.PLACEHOLDER')"
          show-character-count
          :message="getSequenceErrorMessage(index, 'message')"
          :message-type="getSequenceErrorMessage(index, 'message') ? 'error' : 'info'"
        />

        <!-- First item uses absolute time, others use relative delay -->
        <div v-if="index === 0">
           <Input
            v-model="sequence.scheduledAt"
            :label="t('CAMPAIGN.SMS.CREATE.FORM.SCHEDULED_AT.LABEL')"
            type="datetime-local"
            :min="currentDateTime"
            :placeholder="t('CAMPAIGN.SMS.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')"
            :message="getSequenceErrorMessage(index, 'scheduledAt')"
            :message-type="getSequenceErrorMessage(index, 'scheduledAt') ? 'error' : 'info'"
          />
        </div>
        <div v-else class="flex gap-2 items-end">
           <Input
            v-model="sequence.delayValue"
            type="number"
            min="0"
            label="Delay"
            placeholder="0"
            class="w-24"
            :message="getSequenceErrorMessage(index, 'delayValue')"
            :message-type="getSequenceErrorMessage(index, 'delayValue') ? 'error' : 'info'"
          />
           <ComboBox
             v-model="sequence.delayType"
             :options="delayOptions"
             class="w-32 [&>div>button]:bg-n-alpha-black2"
           />
           <span class="text-xs text-n-slate-11 pb-3">after previous message</span>
        </div>
      </div>
      
      <Button
        variant="outline"
        color="slate"
        icon="i-lucide-plus"
        :label="t('CAMPAIGN.SMS.CREATE.FORM.ADD_MESSAGE')"
        @click="addSequence"
        type="button"
      />
    </div>

    <div class="flex items-center justify-between w-full gap-3 mt-2">
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('CAMPAIGN.SMS.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        :label="t('CAMPAIGN.SMS.CREATE.FORM.BUTTONS.CREATE')"
        class="w-full"
        type="submit"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
