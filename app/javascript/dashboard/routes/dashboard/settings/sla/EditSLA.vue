<script>
import { useAlert } from 'dashboard/composables';
import SlaForm from './SlaForm.vue';

export default {
  components: {
    SlaForm,
  },
  props: {
    selectedSla: {
      type: Object,
      required: true,
    },
  },
  emits: ['close'],
  methods: {
    onClose() {
      this.$emit('close');
    },
    async updateSLA(payload) {
      try {
        await this.$store.dispatch('sla/update', {
          id: this.selectedSla.id,
          ...payload,
        });
        useAlert(this.$t('SLA.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('SLA.EDIT.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('SLA.EDIT.TITLE')"
      :header-content="$t('SLA.EDIT.DESC')"
    />
    <SlaForm
      :selected-response="selectedSla"
      :submit-label="$t('SLA.FORM.EDIT')"
      @submit-sla="updateSLA"
      @close="onClose"
    />
  </div>
</template>