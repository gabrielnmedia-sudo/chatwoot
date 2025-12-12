<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, minValue } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { addDays } from 'date-fns';

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

// Helpers for formatted date strings
const todayDate = () => new Date().toISOString().slice(0, 10);

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

const createEmptySequence = (isFirst = false) => ({
  message: '',
  // Step 1 is the base. Steps > 1 are "Days After" relative to previous step.
  delayDays: isFirst ? 0 : 1,
});

const initialState = {
  title: '',
  inboxId: null,
  selectedAudience: [],
  // Global Schedule Settings
  startDate: todayDate(),
  windowStart: '09:00',
  windowEnd: '17:00',
  dailyLimit: 1500,
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
  startDate: { required },
  windowStart: { required },
  windowEnd: { required },
  dailyLimit: { required, minValue: minValue(1) },
  sequences: {
    required,
    $each: {
      message: { required, minLength: minLength(1) },
      delayDays: {
        requiredIf: (value, object) => object.delayDays !== undefined,
        minValue: minValue(0),
      },
    },
  },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

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
  startDate: v$.value.startDate.$error ? 'Start Date is required' : '',
  windowStart: v$.value.windowStart.$error ? 'Window Start is required' : '',
  windowEnd: v$.value.windowEnd.$error ? 'Window End is required' : '',
  dailyLimit: v$.value.dailyLimit.$error ? 'Valid Daily Limit is required' : '',
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
  
  // Calculate the Base Scheduled At (Day 1 Start)
  // We use the startDate + windowStart
  // This is technically the "Earliest" the campaign can start.
  const baseScheduledAt = new Date(`${state.startDate}T${state.windowStart}:00`);

  state.sequences.forEach((sequence, index) => {
    const titleSuffix = index === 0 ? '' : ` - Step ${index + 1}`;
    
    // For the Payload, we send:
    // 1. scheduled_at (Calculated base time)
    // 2. trigger_rules (The constraints)
    // The Backend Service will parse trigger_rules to distribute the messages.
    
    // For Multi-Step:
    // We treating each step as a separate campaign for now in the payload?
    // User wants "Days After".
    // If Step 2 is 2 days after, we should shift its `scheduled_at` by 2 days.
    
    let stepScheduledAt = new Date(baseScheduledAt);
    if (index > 0) {
      // Add Delay Days to the base
      let totalDelay = 0;
      // Sum up delays of previous steps + this step?
      // Logic: "Days After" usually means relative to previous.
      // Let's assume relative to PREVIOUS step for simplicity in UI, 
      // but simplistic calculation here:
      // We need to keep a running tally if we want relative.
      // For now let's just use the sequence's delayDays relative to the START if index > 0?
      // The previous code did relative. let's stick to relative.
    }
    
    // Actually, to support the Backend Throttling Service effectively, 
    // we should probably just send the `trigger_rules` and let the backend 
    // handle the "execution" time. 
    // BUT, the backend `OneoffSmsCampaignService` expects a specific `scheduled_at` to wake up.
    
    // Let's compute the "Wake Up Time" for this Step.
    // Step 0: Wake up at StartDate @ WindowStart
    // Step 1 (2 days later): Wake up at (StartDate + 2) @ WindowStart
    
    // Running Tally calculation
    // Reset base for calculation
    let currentWakeUp = new Date(baseScheduledAt);
    
    for (let i = 0; i <= index; i++) {
      if (i > 0) {
        currentWakeUp = addDays(currentWakeUp, parseInt(state.sequences[i].delayDays || 0, 10));
        // Reset time to windowStart just in case
        currentWakeUp = combineDateAndTime(currentWakeUp, state.windowStart);
      }
    }

    campaigns.push({
      title: `${state.title}${titleSuffix}`,
      message: sequence.message,
      inbox_id: state.inboxId,
      scheduled_at: currentWakeUp.toISOString(),
      audience: state.selectedAudience?.map(id => ({
        id,
        type: 'Label',
      })),
      trigger_rules: {
        window_start: state.windowStart,
        window_end: state.windowEnd,
        daily_limit: state.dailyLimit,
      },
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

    <!-- Throttling Settings -->
    <div class="p-4 rounded-lg bg-n-alpha-1 border border-n-weak flex flex-col gap-4">
      <h3 class="text-sm font-medium text-n-slate-12">Scheduling Strategy</h3>
      
      <!-- Start Date -->
      <Input
        v-model="state.startDate"
        label="Start Date"
        type="date"
        :min="todayDate()"
        :message="formErrors.startDate"
        :message-type="formErrors.startDate ? 'error' : 'info'"
      />

      <!-- Sending Window -->
      <div class="flex gap-4">
        <Input
          v-model="state.windowStart"
          label="Send Times (Start)"
          type="time"
          class="flex-1"
          :message="formErrors.windowStart"
          :message-type="formErrors.windowStart ? 'error' : 'info'"
        />
        <Input
          v-model="state.windowEnd"
          label="Send Times (End)"
          type="time"
          class="flex-1"
          :message="formErrors.windowEnd"
          :message-type="formErrors.windowEnd ? 'error' : 'info'"
        />
      </div>

       <!-- Daily Limit -->
      <Input
        v-model="state.dailyLimit"
        label="Global Tenant Limit (Max Messages/Day)"
        type="number"
        min="1"
        placeholder="1500"
        :message="formErrors.dailyLimit"
        :message-type="formErrors.dailyLimit ? 'error' : 'info'"
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

        <!-- Step Specific Delay controls -->
        <div v-if="index > 0" class="flex gap-2 items-center">
           <span class="text-sm text-n-slate-11">Send</span>
           <Input
            v-model="sequence.delayDays"
            type="number"
            min="1"
            placeholder="1"
            class="w-24"
            :message="getSequenceErrorMessage(index, 'delayDays')"
            :message-type="getSequenceErrorMessage(index, 'delayDays') ? 'error' : 'info'"
          />
           <span class="text-sm text-n-slate-11">days after previous step</span>
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
