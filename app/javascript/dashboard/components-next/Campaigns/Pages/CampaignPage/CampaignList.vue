<script setup>
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';

import { useRouter, useRoute } from 'vue-router';

defineProps({
  campaigns: {
    type: Array,
    required: true,
  },
  isLiveChatType: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['edit', 'delete']);
const router = useRouter();
const route = useRoute();

const handleEdit = campaign => emit('edit', campaign);
const handleDelete = campaign => emit('delete', campaign);
const openDetails = campaign => {
  router.push({ name: 'campaigns_details', params: { ...route.params, campaignId: campaign.id } });
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <CampaignCard
      v-for="campaign in campaigns"
      :key="campaign.id"
      :title="campaign.title"
      :message="campaign.message"
      :is-enabled="campaign.enabled"
      :status="campaign.campaign_status"
      :sender="campaign.sender"
      :inbox="campaign.inbox"
      :scheduled-at="campaign.scheduled_at"
      :reply-rate="campaign.reply_rate"
      :is-live-chat-type="isLiveChatType"
      class="cursor-pointer hover:bg-n-alpha-1"
      @click="openDetails(campaign)"
      @edit="handleEdit(campaign)"
      @delete="handleDelete(campaign)"
    />
  </div>
</template>
