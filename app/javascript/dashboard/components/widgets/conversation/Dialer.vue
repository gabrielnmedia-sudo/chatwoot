<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { Device } from '@twilio/voice-sdk';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  phoneNumber: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const device = ref(null);
const call = ref(null);
const callStatus = ref('initializing'); // initializing, ready, calling, ringing, connected, disconnected, error
const isMuted = ref(false);
const errorMessage = ref('');

// Fetch token from backend
const fetchToken = async () => {
  try {
    const response = await axios.post(`/api/v1/accounts/${store.getters.getCurrentAccountId}/twilio/tokens`);
    return response.data.token;
  } catch (error) {
    console.error('Failed to fetch Twilio token', error);
    callStatus.value = 'error';
    errorMessage.value = t('DIALER.ERRORS.TOKEN_FETCH');
    return null;
  }
};

const initializeDevice = async () => {
  const token = await fetchToken();
  if (!token) return;

  try {
    device.value = new Device(token, {
      codecPreferences: ['opus', 'pcmu'],
      fakeLocalDTMF: true,
      enableRingingState: true,
    });

    device.value.on('ready', () => {
      callStatus.value = 'ready';
      makeCall(); // Auto-dial on open
    });

    device.value.on('error', (error) => {
      console.error('Twilio Device Error:', error);
      callStatus.value = 'error';
      errorMessage.value = error.message;
    });
  } catch (error) {
    console.error('Device Initialization Error:', error);
    callStatus.value = 'error';
  }
};

const makeCall = async () => {
  if (!device.value) return;

  callStatus.value = 'calling';
  
  const params = {
    To: props.phoneNumber,
  };

  try {
    call.value = await device.value.connect({ params });

    call.value.on('accept', () => {
      callStatus.value = 'connected';
    });

    call.value.on('disconnect', () => {
      callStatus.value = 'disconnected';
      setTimeout(() => emit('close'), 2000); // Close after 2s
    });

    call.value.on('cancel', () => {
      callStatus.value = 'disconnected';
      emit('close');
    });
    
    call.value.on('ringing', () => {
      callStatus.value = 'ringing';
    });

  } catch (error) {
    console.error('Call Connection Error:', error);
    callStatus.value = 'error';
  }
};

const toggleMute = () => {
  if (!call.value) return;
  if (isMuted.value) {
    call.value.mute(false);
    isMuted.value = false;
  } else {
    call.value.mute(true);
    isMuted.value = true;
  }
};

const hangup = () => {
  if (call.value) {
    call.value.disconnect();
  } else {
    emit('close');
  }
};

onMounted(() => {
  initializeDevice();
});

onBeforeUnmount(() => {
  if (device.value) {
    device.value.destroy();
  }
});
</script>

<template>
  <div class="fixed bottom-4 right-4 z-50 w-80 bg-white dark:bg-slate-900 rounded-lg shadow-xl border border-slate-200 dark:border-slate-800 p-4 flex flex-col gap-4">
    <!-- Header -->
    <div class="flex justify-between items-center border-b border-slate-100 dark:border-slate-800 pb-2">
      <h3 class="font-medium text-slate-800 dark:text-slate-100">{{ t('DIALER.TITLE') }}</h3>
      <button @click="$emit('close')" class="text-slate-400 hover:text-slate-600">
        <span class="sr-only">Close</span>
        &times;
      </button>
    </div>

    <!-- Status & Number -->
    <div class="flex flex-col items-center gap-2 py-4">
      <div class="w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center mb-2">
        <fluent-icon icon="person" size="32" class="text-slate-500" />
      </div>
      <span class="text-lg font-bold text-slate-900 dark:text-white">{{ phoneNumber }}</span>
      <span class="text-sm font-medium" :class="{
        'text-yellow-500': ['calling', 'ringing'].includes(callStatus),
        'text-green-500': callStatus === 'connected',
        'text-red-500': ['disconnected', 'error'].includes(callStatus),
        'text-slate-500': callStatus === 'ready' || callStatus === 'initializing'
      }">
        {{ callStatus === 'error' ? errorMessage : t(`DIALER.STATUS.${callStatus.toUpperCase()}`) }}
      </span>
    </div>

    <!-- Controls -->
    <div class="flex justify-center gap-4">
      <!-- Mute Button -->
      <Button
        v-if="callStatus === 'connected'"
        variant="ghost" 
        rounded="full" 
        size="lg"
        :color="isMuted ? 'amber' : 'slate'"
        :icon="isMuted ? 'i-lucide-mic-off' : 'i-lucide-mic'"
        @click="toggleMute"
      />
      
      <!-- Hangup Button -->
      <Button
        variant="solid" 
        rounded="full" 
        size="lg"
        color="red"
        icon="i-lucide-phone-off"
        @click="hangup"
      />
    </div>
  </div>
</template>
