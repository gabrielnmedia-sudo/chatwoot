<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import validations, { getStageTitleErrorMessage } from './validations';
import { useVuelidate } from '@vuelidate/core';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    selectedResponse: {
      type: Object,
      default: () => {},
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      name: '',
      color: '',
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'pipelineStages/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('PIPELINE_MGMT.EDIT.TITLE')} - ${
        this.selectedResponse.name
      }`;
    },
    stageTitleErrorMessage() {
      const errorMessage = getStageTitleErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
  },
  mounted() {
    this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    setFormValues() {
      this.name = this.selectedResponse.name;
      this.color = this.selectedResponse.color;
    },
    editStage() {
      this.$store
        .dispatch('pipelineStages/update', {
          id: this.selectedResponse.id,
          color: this.color,
          name: this.name,
        })
        .then(() => {
          useAlert(this.$t('PIPELINE_MGMT.EDIT.API.SUCCESS_MESSAGE'));
          setTimeout(() => this.onClose(), 10);
        })
        .catch(() => {
          useAlert(this.$t('PIPELINE_MGMT.EDIT.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="pageTitle" />
    <form class="flex flex-wrap mx-0" @submit.prevent="editStage">
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
          :label="$t('PIPELINE_MGMT.FORM.EDIT')"
          :disabled="v$.name.$invalid || uiFlags.isUpdating"
          :is-loading="uiFlags.isUpdating"
        />
      </div>
    </form>
  </div>
</template>
