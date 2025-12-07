import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import SMSCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/SMSCampaign/SMSCampaignForm.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['close']);
const dialogRef = ref(null);

const store = useStore();
const { t } = useI18n();

onMounted(() => {
  dialogRef.value?.open();
});

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', campaignDetails);

    // tracking this here instead of the store to track the type of campaign
    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONE_OFF,
    });
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.SMS.CREATE.FORM.API.ERROR_MESSAGE');
    useAlert(errorMessage);
    throw error;
  }
};

const handleSubmit = async campaigns => {
  // campaigns can be a single object or an array (for sequences)
  const campaignsList = Array.isArray(campaigns) ? campaigns : [campaigns];
  let successCount = 0;

  try {
    for (const campaign of campaignsList) {
      await addCampaign(campaign);
      successCount++;
    }

    useAlert(t('CAMPAIGN.SMS.CREATE.FORM.API.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    // If some succeeded and one failed, we should probably stay open or alert differently
    // For now, standard alert is shown in addCampaign
  }
};

const handleClose = () => emit('close');
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CAMPAIGN.SMS.CREATE.TITLE')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <SMSCampaignForm @submit="handleSubmit" @cancel="handleClose" />
  </Dialog>
</template>
