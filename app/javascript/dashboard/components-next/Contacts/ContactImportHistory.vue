<template>
  <div class="flex flex-col h-full overflow-y-auto bg-white border-l border-slate-50 w-80 dark:bg-slate-900 dark:border-slate-800/50">
    <div class="px-6 py-4 flex items-center justify-between border-b border-slate-50 dark:border-slate-800/50">
      <h3 class="text-base font-medium text-slate-900 dark:text-slate-100">
        Import History
      </h3>
      <button 
        class="text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 transition-colors"
        @click="$emit('close')"
      >
        <span class="i-lucide-x w-5 h-5"></span>
      </button>
    </div>
    <div class="p-6 pt-2">
      <p class="text-sm text-slate-500 dark:text-slate-400">
        View the status of your recent contact imports.
      </p>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center p-8">
      <spinner />
    </div>

    <div v-else-if="imports.length === 0" class="p-6 text-center text-slate-500">
      No imports found.
    </div>

    <div v-else class="flex flex-col">
      <div
        v-for="dataImport in imports"
        :key="dataImport.id"
        class="px-6 py-4 border-b border-slate-50 hover:bg-slate-50 dark:border-slate-800/50 dark:hover:bg-slate-800/50 transition-colors"
      >
        <div class="flex items-center justify-between mb-2">
          <span
            class="text-xs font-medium px-2 py-0.5 rounded-full"
            :class="statusClass(dataImport.status)"
          >
            {{ formatStatus(dataImport.status) }}
          </span>
          <span class="text-xs text-slate-400">
            {{ formatTime(dataImport.created_at) }}
          </span>
        </div>
        
        <!-- Active Import State (Processing) -->
        <div v-if="isActive(dataImport.status)" class="mb-2">
           <div class="flex justify-between text-xs text-slate-600 dark:text-slate-300 mb-1">
             <span>Processed</span>
             <span>{{ dataImport.processed_records }} / {{ dataImport.total_records }}</span>
           </div>
           
           <div class="w-full bg-slate-100 rounded-full h-1.5 dark:bg-slate-800 overflow-hidden">
             <div 
               class="bg-woot-500 h-1.5 rounded-full transition-all duration-500"
               :style="{ width: progressPercentage(dataImport) + '%' }"
             ></div>
           </div>
        </div>

        <!-- Completed/Failed State -->
        <div v-else class="flex justify-between items-center text-xs">
           <span class="text-slate-600 dark:text-slate-400">
             {{ dataImport.total_records }} contacts
           </span>
           
           <a 
             v-if="dataImport.file_url" 
             :href="dataImport.file_url" 
             target="_blank" 
             class="text-slate-400 hover:text-woot-500 dark:text-slate-500 dark:hover:text-woot-400 transition-colors"
             title="Download CSV"
           >
             <span class="i-lucide-download w-4 h-4"></span>
           </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import { formatDistanceToNow } from 'date-fns';

export default {
  name: 'ContactImportHistory',
  components: {
    Spinner,
  },
  emits: ['close'],
  data() {
    return {
      imports: [],
      isLoading: true,
      pollInterval: null,
    };
  },
  mounted() {
    this.fetchImports();
    this.pollInterval = setInterval(this.fetchImports, 5000);
  },
  beforeDestroy() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
    }
  },
  methods: {
    async fetchImports() {
      try {
        const response = await DataImportsAPI.get();
        // Assuming API returns data in response.data.payload or similar, 
        // adjusting based on typical Chatwoot API response
        this.imports = response.data.payload || response.data; 
      } catch (error) {
        console.error('Failed to fetch imports', error);
      } finally {
        this.isLoading = false;
      }
    },
    isActive(status) {
      return status === 'processing' || status === 'pending';
    },
    formatStatus(status) {
      if (!status) return 'Pending';
      return status.charAt(0).toUpperCase() + status.slice(1);
    },
    statusClass(status) {
      switch (status) {
        case 'completed':
          return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
        case 'failed':
          return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
        case 'processing':
          return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400';
        default:
          return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400';
      }
    },
    formatTime(time) {
      return formatDistanceToNow(new Date(time), { addSuffix: true });
    },
    progressPercentage(dataImport) {
       if (dataImport.total_records === 0) return 0;
       return Math.round((dataImport.processed_records / dataImport.total_records) * 100);
    }
  },
};
</script>
