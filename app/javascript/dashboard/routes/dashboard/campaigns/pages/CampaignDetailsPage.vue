<script setup>
import { computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const campaignId = computed(() => route.params.campaignId);
const campaign = computed(() => store.getters['campaigns/getCampaign'](campaignId.value));
const uiFlags = computed(() => store.getters['campaigns/getUIFlags']);

onMounted(() => {
  store.dispatch('campaigns/get', { campaignId: campaignId.value });
});

const goBack = () => {
  router.go(-1);
};
</script>

<template>
  <div class="flex flex-col h-full overflow-hidden bg-n-alpha-1">
    <div class="flex items-center gap-2 px-8 py-6 border-b border-n-strong">
      <Button
        variant="ghost"
        icon="i-lucide-arrow-left"
        size="sm"
        @click="goBack"
      />
      <h1 class="text-xl font-medium text-n-slate-12">
        {{ campaign?.title || t('CAMPAIGN.DETAILS.LOADING') }}
      </h1>
    </div>

    <div v-if="uiFlags.isFetching" class="flex items-center justify-center flex-1">
      <Spinner />
    </div>

    <div v-else-if="campaign" class="flex-1 p-8 overflow-y-auto">
      <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
        <!-- Metrics Cards -->
        <div class="p-6 bg-white rounded-lg shadow-sm dark:bg-n-solid-2 border border-n-weak">
          <h3 class="text-sm font-medium text-n-slate-11">Total Sent</h3>
          <p class="mt-2 text-3xl font-semibold text-n-slate-12">{{ campaign.total_sent }}</p>
        </div>
        <div class="p-6 bg-white rounded-lg shadow-sm dark:bg-n-solid-2 border border-n-weak">
          <h3 class="text-sm font-medium text-n-slate-11">Replies</h3>
          <p class="mt-2 text-3xl font-semibold text-n-slate-12">{{ campaign.reply_count }}</p>
        </div>
        <div class="p-6 bg-white rounded-lg shadow-sm dark:bg-n-solid-2 border border-n-weak">
          <h3 class="text-sm font-medium text-n-slate-11">Reply Rate</h3>
          <p class="mt-2 text-3xl font-semibold text-n-slate-12">{{ campaign.reply_rate }}%</p>
        </div>

        <!-- Details -->
        <div class="col-span-1 md:col-span-3">
          <div class="p-6 bg-white rounded-lg shadow-sm dark:bg-n-solid-2 border border-n-weak">
            <h2 class="mb-4 text-lg font-medium text-n-slate-12">{{ t('CAMPAIGN.DETAILS.TITLE') }}</h2>
            <div class="space-y-4">
              <div>
                <label class="text-xs font-medium text-n-slate-11 uppercase">Message</label>
                <div class="mt-1 text-sm text-n-slate-12 whitespace-pre-wrap">{{ campaign.message }}</div>
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-11 uppercase">Inbox</label>
                <div class="mt-1 text-sm text-n-slate-12">{{ campaign.inbox?.name }}</div>
              </div>
              <div v-if="campaign.scheduled_at">
                <label class="text-xs font-medium text-n-slate-11 uppercase">Scheduled At</label>
                <div class="mt-1 text-sm text-n-slate-12">{{ new Date(campaign.scheduled_at * 1000).toLocaleString() }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
