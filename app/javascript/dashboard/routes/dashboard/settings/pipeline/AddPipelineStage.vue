<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import validations, { getStageTitleErrorMessage } from './validations';
import { getRandomColor } from 'dashboard/helper/labelColor';
import { useVuelidate } from '@vuelidate/core';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      color: '#000',
      name: '',
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'pipelineStages/getUIFlags',
    }),
    stageTitleErrorMessage() {
      const errorMessage = getStageTitleErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
  },
  mounted() {
    this.color = getRandomColor();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addStage() {
      try {
        await this.$store.dispatch('pipelineStages/create', {
          color: this.color,
          name: this.name,
        });
        useAlert(this.$t('PIPELINE_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('PIPELINE_MGMT.ADD.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('PIPELINE_MGMT.ADD.TITLE')"
      :header-content="$t('PIPELINE_MGMT.ADD.DESC')"
    />
    <form class="flex flex-wrap mx-0" @submit.prevent="addStage">
      <woot-input
        v-model="name"
        :class="{ error: v$.name.$error }"
        class="w-full"
        :label="$t('PIPELINE_MGMT.FORM.NAME.LABEL')"
        :placeholder="$t('PIPELINE_MGMT.FORM.NAME.PLACEHOLDER')"
        :error="stageTitleErrorMessage"
        @input="v$.name.$touch"
        @blur="v$.name.$touch"
      />

      <div class="w-full">
        <label>
          {{ $t('PIPELINE_MGMT.FORM.COLOR.LABEL') }}
          <woot-color-picker v-model="color" />
        </label>
      </div>

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('PIPELINE_MGMT.FORM.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :label="$t('PIPELINE_MGMT.FORM.CREATE')"
          :disabled="v$.name.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
        />
      </div>
    </form>
  </div>
</template>
