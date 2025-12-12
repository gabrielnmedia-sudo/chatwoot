<script setup>
import { ref, shallowRef, onMounted, onBeforeUnmount, computed } from 'vue';
import { useStore } from 'vuex';
import { Device } from '@twilio/voice-sdk';

const props = defineProps({
  phoneNumber: {
    type: String,
    default: '',
  },
  inboxId: {
    type: [Number, String],
    default: null,
  },
  contactId: {
    type: [Number, String],
    default: null,
  },
});

defineEmits(['close']);

const store = useStore();
const status = ref('initializing'); // initializing, ready, connecting, open, closed
const muted = ref(false);
const call = shallowRef(null);
const device = shallowRef(null);
const error = ref(null);

const currentUser = computed(() => store.getters.getCurrentUser);

const getToken = async () => {
  try {
    const { data } = await store.dispatch('accounts/getTwilioToken');
    return data.token;
  } catch (err) {
    error.value = 'Failed to get access token';
    return null;
  }
};

const setupDevice = async () => {
  status.value = 'initializing';
  const token = await getToken();
  if (!token) return;

  try {
    // Initialize Device
    device.value = new Device(token, {
      logLevel: 1,
      codecPreferences: ['opus', 'pcmu'],
    });

    // Register Event Listeners
    device.value.on('registered', () => {
      status.value = 'ready';
    });

    device.value.on('error', err => {
      error.value = err.message;
    });

    // For v2+, we explicitly register
    device.value.register();
    // Fallback if 'registered' takes too long or isn't needed for outbound only
    setTimeout(() => {
      if (status.value === 'initializing') status.value = 'ready';
    }, 1000);
  } catch (err) {
    error.value = 'Device Setup Failed';
  }
};

const createOutboundConversation = async () => {
  let inboxId = props.inboxId;

  // Resolve Inbox if missing
  if (!inboxId) {
    const inboxes = store.getters['inboxes/getTwilioInboxes'];
    if (inboxes.length > 0) {
      inboxId = inboxes[0].id;
    }
  }

  // If we still don't have an inbox or contact, we can't create a conversation
  if (!inboxId || !props.contactId) {
    return;
  }

  try {
    await store.dispatch('contactConversations/create', {
      params: {
        inboxId: inboxId,
        contactId: props.contactId,
        message: {
          content: `Called by ${currentUser.value.name}`,
          is_private: true,
        },
      },
    });
  } catch (err) {
    // Ignore error
  }
};

const makeCall = async () => {
  if (!device.value) return;

  status.value = 'connecting';
  error.value = null;

  // Log the call in conversation history (Best Effort)
  createOutboundConversation();

  try {
    const callParams = {
      params: {
        To: props.phoneNumber,
        inbox_id: props.inboxId,
      },
    };

    // This ALERTS if permission is denied
    call.value = await device.value.connect(callParams);

    // Call Event Listeners
    call.value.on('accept', () => {
      status.value = 'open';
    });

    call.value.on('disconnect', () => {
      status.value = 'closed';
      call.value = null;
    });

    call.value.on('error', err => {
      error.value = err.message;
      status.value = 'closed';
    });
  } catch (err) {
    // This is where Permission Denied errors go
    error.value = 'Failed to connect: ' + err.message;
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
  }
  status.value = 'closed';
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
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template -->
  <div
    class="fixed bottom-4 right-4 z-50 w-72 bg-white rounded-lg shadow-xl border border-slate-200 p-4 dark:bg-slate-800 dark:border-slate-700"
  >
    <div class="flex justify-between items-center mb-4">
      <h3 class="text-sm font-medium text-slate-900 dark:text-slate-100">
        Calling {{ phoneNumber }}
      </h3>
      <button
        class="text-slate-400 hover:text-slate-500"
        @click="$emit('close')"
      >
        <span class="sr-only">Close</span>
        &times;
      </button>
    </div>

    <div class="text-center mb-6">
      <!-- Status Display -->
      <div v-if="status === 'initializing'" class="text-slate-500">
        Initializing Device...
      </div>

      <div v-else-if="status === 'ready'" class="text-green-600 font-bold">
        Ready to Call
      </div>

      <div
        v-if="status === 'connecting'"
        class="text-yellow-500 text-xl font-semibold"
      >
        Calling...
      </div>

      <div
        v-if="status === 'open'"
        class="text-green-500 text-xl font-semibold"
      >
        Connected 00:00
      </div>

      <div
        v-if="status === 'closed'"
        class="text-red-500 text-xl font-semibold"
      >
        Ended
      </div>

      <!-- Error Message -->
      <div v-if="error" class="text-xs text-red-500 mt-2 bg-red-50 p-2 rounded">
        {{ error }}
      </div>
    </div>

    <!-- Actions -->
    <div class="flex justify-center gap-4">
      <!-- Start Call Button (Fix for Permission Issue) -->
      <button
        v-if="status === 'ready' || status === 'closed'"
        class="bg-green-500 hover:bg-green-600 text-white rounded-full p-4 shadow-lg transition-transform hover:scale-105"
        @click="makeCall"
      >
        <fluent-icon icon="call" size="24" />
      </button>

      <!-- In-Call Controls -->
      <template v-if="status === 'connecting' || status === 'open'">
        <button
          class="p-3 rounded-full transition-colors"
          :class="[
            muted
              ? 'bg-slate-200 text-slate-700'
              : 'bg-slate-100 text-slate-600 hover:bg-slate-200',
          ]"
          @click="toggleMute"
        >
          <fluent-icon :icon="muted ? 'mic-off' : 'mic'" size="20" />
        </button>

        <button
          class="p-3 rounded-full bg-red-500 text-white hover:bg-red-600 transition-colors"
          @click="hangup"
        >
          <fluent-icon icon="call-end" size="20" />
        </button>
      </template>
    </div>
  </div>
</template>
