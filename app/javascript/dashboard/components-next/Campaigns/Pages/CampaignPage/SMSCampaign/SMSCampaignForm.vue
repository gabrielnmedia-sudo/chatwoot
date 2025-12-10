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
  // For the first item we use scheduledDate + scheduledTime
  scheduledDate: isFirst ? '' : undefined,
  scheduledTime: isFirst ? '' : '09:00',
  // For others we use delayDays + scheduledTime
  delayDays: isFirst ? undefined : 1,
});

const initialState = {
  title: '',
  inboxId: null,
  selectedAudience: [],
  sequences: [createEmptySequence(true)],
};

const state = reactive({
  ...initialState,
  sequences: [createEmptySequence(true)],
});

const rules = {
  title: { required, minLength: minLength(1) },
  inboxId: { required },
  selectedAudience: { required },
  sequences: {
    required,
    $each: {
      message: { required, minLength: minLength(1) },
      scheduledDate: {
        requiredIf: (value, object) => object.scheduledDate !== undefined,
      },
      scheduledTime: { required },
      delayDays: {
        requiredIf: (value, object) => object.delayDays !== undefined,
        minValue: minValue(0),
      },
    },
  },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

// Helpers for formatted date strings
const todayDate = () => new Date().toISOString().slice(0, 10);
const currentDateTime = computed(() => todayDate());

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

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.SMS.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

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

// Combine date from one source and time from string "HH:MM"
const combineDateAndTime = (baseDateObj, timeString) => {
  const [hours, minutes] = timeString.split(':').map(Number);
  const newDate = new Date(baseDateObj);
  newDate.setHours(hours, minutes, 0, 0);
  return newDate;
};

const prepareCampaignDetails = () => {
  const campaigns = [];
  
  // Initialize with Step 0
  const firstSeq = state.sequences[0];
  // Parse YYYY-MM-DD + HH:MM
  let currentBaseDate = new Date(firstSeq.scheduledDate);
  // We need to offset for timezone if we just do new Date('YYYY-MM-DD') which might default to UTC
  // Better to construct explicitly or use the time part immediately
  // Actually, input type="date" returns YYYY-MM-DD.
  // We want to combine this with the local time.
  // Construct a date string compatible with constructor
  let currentScheduledAt = new Date(`${firstSeq.scheduledDate}T${firstSeq.scheduledTime}:00`);

  state.sequences.forEach((sequence, index) => {
    let targetDate;

    if (index === 0) {
      targetDate = currentScheduledAt;
    } else {
      // Add days to the PREVIOUS scheduled date's Day
      // Note: Logic says "X Days After". Usually implies "X days after previous message".
      // So we move the date forward by delayDays
      currentBaseDate = addDays(currentBaseDate, parseInt(sequence.delayDays || 0));
      // Then set the specific time for THAT day
      targetDate = combineDateAndTime(currentBaseDate, sequence.scheduledTime);
      // Update running trackers
      currentScheduledAt = targetDate;
    }

    const titleSuffix = index === 0 ? '' : ` - Step ${index + 1}`;

    campaigns.push({
      title: `${state.title}${titleSuffix}`,
      message: sequence.message,
      inbox_id: state.inboxId,
      scheduled_at: targetDate.toISOString(),
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

        <!-- First item uses separate Date + Time -->
        <div v-if="index === 0" class="flex gap-2">
           <Input
            v-model="sequence.scheduledDate"
            label="Start Date"
            type="date"
            :min="todayDate()"
            class="flex-1"
            :message="getSequenceErrorMessage(index, 'scheduledDate')"
            :message-type="getSequenceErrorMessage(index, 'scheduledDate') ? 'error' : 'info'"
          />
           <Input
            v-model="sequence.scheduledTime"
            label="Start Time"
            type="time"
            class="flex-1"
            :message="getSequenceErrorMessage(index, 'scheduledTime')"
            :message-type="getSequenceErrorMessage(index, 'scheduledTime') ? 'error' : 'info'"
          />
        </div>
        <!-- Subsequent items use Days Delay + Specific Time -->
        <div v-else class="flex gap-2 items-end">
           <Input
            v-model="sequence.delayDays"
            type="number"
            min="0"
            label="Days After"
            placeholder="1"
            class="w-32"
            :message="getSequenceErrorMessage(index, 'delayDays')"
            :message-type="getSequenceErrorMessage(index, 'delayDays') ? 'error' : 'info'"
          />
           <span class="text-sm font-medium text-n-slate-11 pb-3">days, at</span>
           <Input
            v-model="sequence.scheduledTime"
            type="time"
            label="Time"
            class="w-32"
            :message="getSequenceErrorMessage(index, 'scheduledTime')"
            :message-type="getSequenceErrorMessage(index, 'scheduledTime') ? 'error' : 'info'"
          />
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
