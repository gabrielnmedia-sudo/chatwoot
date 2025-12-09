<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { Device } from '@twilio/voice-sdk';
// import { useStartNewConversation } from 'dashboard/composables/useStartNewConversation';

const props = defineProps({
  phoneNumber: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const status = ref('idle'); // idle, connecting, open, closed
const muted = ref(false);
const call = ref(null);
const device = ref(null);
const error = ref(null);

// const { createConversation } = useStartNewConversation();

const getToken = async () => {
  try {
    const { data } = await store.dispatch('accounts/getTwilioToken');
    return data.token;
  } catch (err) {
    error.value = 'Failed to get access token';
    console.error(err);
    return null;
  }
};

const setupDevice = async () => {
  const token = await getToken();
  if (!token) return;

  try {
    device.value = new Device(token, {
      logLevel: 1,
      codecPreferences: ['opus', 'pcmu'],
    });

    device.value.on('ready', () => {
      console.log('Twilio.Device Ready!');
      makeCall();
    });

    device.value.on('error', (err) => {
      console.error('Twilio.Device Error:', err);
      error.value = err.message || 'Device error';
      status.value = 'closed';
    });

  } catch (err) {
    console.error('Device setup failed', err);
    error.value = 'Failed to initialize calling device';
  }
};

const makeCall = async () => {
  if (!device.value || status.value === 'open') return;
  
  status.value = 'connecting';
  error.value = null;

  try {
    const callParams = {
      params: {
        To: props.phoneNumber,
        // Agent identity is handled by the token generation on backend
      },
    };

    call.value = await device.value.connect(callParams);

    call.value.on('accept', () => {
      status.value = 'open';
      console.log('Call accepted');
    });

    call.value.on('disconnect', () => {
      status.value = 'closed';
      call.value = null;
      console.log('Call disconnected');
    });

    call.value.on('error', (err) => {
      console.error('Call error:', err);
      error.value = 'Call failed';
      status.value = 'closed';
    });

  } catch (err) {
    console.error('Failed to make call', err);
    error.value = 'Failed to connect call';
    status.value = 'closed';
  }
};

const toggleMute = () => {
  if (!call.value) return;
  muted.value = !muted.value;
  call.value.mute(muted.value);
};

const hangup = () => {
  if (call.value) {
    call.value.disconnect();
  } else {
    emit('close');
  }
};

onMounted(() => {
  setupDevice();
});

onBeforeUnmount(() => {
  if (device.value) {
    device.value.destroy();
  }
});

</script>

<template>
  <div class="fixed bottom-4 right-4 z-50 w-72 bg-white rounded-lg shadow-xl border border-slate-200 p-4 dark:bg-slate-800 dark:border-slate-700">
    <div class="flex justify-between items-center mb-4">
      <h3 class="text-sm font-medium text-slate-900 dark:text-slate-100">
        Calling {{ phoneNumber }}
      </h3>
      <button @click="$emit('close')" class="text-slate-400 hover:text-slate-500">
        <span class="sr-only">Close</span>
        &times;
      </button>
    </div>

    <div class="text-center mb-6">
      <div class="text-2xl font-semibold mb-2" :class="{
        'text-yellow-500': status === 'connecting',
        'text-green-500': status === 'open',
        'text-red-500': status === 'closed',
      }">
        {{ status === 'open' ? 'Connected' : (status === 'connecting' ? 'Calling...' : 'Ended') }}
      </div>
      <div v-if="error" class="text-xs text-red-500 mt-2">
        {{ error }}
      </div>
    </div>

    <div class="flex justify-center gap-4">
      <button 
        @click="toggleMute" 
        :class="[
          'p-3 rounded-full transition-colors',
          muted ? 'bg-slate-200 text-slate-700' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
        ]"
        :disabled="status !== 'open'"
      >
        <fluent-icon :icon="muted ? 'mic-off' : 'mic'" size="20" />
      </button>
      
      <button 
        @click="hangup"
        class="p-3 rounded-full bg-red-500 text-white hover:bg-red-600 transition-colors"
      >
        <fluent-icon icon="call-end" size="20" />
      </button>
    </div>
  </div>
</template>
