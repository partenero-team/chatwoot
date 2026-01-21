<script setup>
import { computed } from 'vue';
import { format, fromUnixTime } from 'date-fns';
import ContactDetailsItem from './ContactDetailsItem.vue';

const props = defineProps({
  appliedSla: {
    type: Object,
    default: null,
  },
  conversation: {
    type: Object,
    default: () => ({}),
  },
});

const hasSla = computed(() => {
  if (!props.appliedSla || typeof props.appliedSla !== 'object') return false;
  return (
    props.appliedSla.created_at !== null &&
    props.appliedSla.created_at !== undefined
  );
});

const formatDateTime = timestamp => {
  if (!timestamp) return '--';
  return format(fromUnixTime(timestamp), 'MMM dd, yyyy, hh:mm a');
};

const slaStartedAt = computed(() => {
  if (!hasSla.value) return null;
  return props.appliedSla.created_at;
});

// First Response Time calculations
const firstResponseTimeData = computed(() => {
  if (!hasSla.value) return { slaTime: null, realTime: null, status: null };

  const slaAppliedAt = props.appliedSla.created_at;
  const slaThreshold = props.appliedSla.sla_first_response_time_threshold;

  if (!slaThreshold) {
    return { slaTime: null, realTime: null, status: null };
  }

  const slaTime = slaAppliedAt + slaThreshold;
  let realTime = null;

  if (props.conversation.first_reply_created_at) {
    realTime = props.conversation.first_reply_created_at;
  }

  let status = null;
  if (realTime) {
    status = realTime <= slaTime ? '🟢' : '🟡';
  }

  return { slaTime, realTime, status };
});

// Next Response Time calculations
const nextResponseTimeData = computed(() => {
  if (!hasSla.value) return { slaTime: null, realTime: null, status: null };

  const slaThreshold = props.appliedSla.sla_next_response_time_threshold;

  if (!slaThreshold) {
    return { slaTime: null, realTime: null, status: null };
  }

  // For next response time, we need waiting_since
  if (!props.conversation.waiting_since) {
    return { slaTime: null, realTime: null, status: null };
  }

  const slaTime = props.conversation.waiting_since + slaThreshold;
  // Real time would be when agent responded after waiting_since
  // This is complex without message data, so we'll show null for now
  const realTime = null;
  const status = null;

  return { slaTime, realTime, status };
});

// Resolution Time calculations
const resolutionTimeData = computed(() => {
  if (!hasSla.value) return { slaTime: null, realTime: null, status: null };

  const slaAppliedAt = props.appliedSla.created_at;
  const slaThreshold = props.appliedSla.sla_resolution_time_threshold;

  if (!slaThreshold) {
    return { slaTime: null, realTime: null, status: null };
  }

  const slaTime = slaAppliedAt + slaThreshold;
  let realTime = null;

  if (
    props.conversation.status === 'resolved' &&
    props.conversation.updated_at
  ) {
    realTime = props.conversation.updated_at;
  }

  let status = null;
  if (realTime) {
    status = realTime <= slaTime ? '🟢' : '🟡';
  }

  return { slaTime, realTime, status };
});
</script>

<template>
  <div v-if="hasSla" class="conversation--details">
    <ContactDetailsItem
      :title="$t('CONVERSATION_SIDEBAR.SLA.STARTED_AT')"
      :value="formatDateTime(slaStartedAt)"
    />

    <div v-if="firstResponseTimeData.slaTime" class="overflow-auto py-3 px-4">
      <div class="items-center flex justify-between mb-1.5">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('CONVERSATION_SIDEBAR.SLA.FIRST_RESPONSE_TIME') }}
        </span>
      </div>
      <div class="flex flex-col gap-1 text-sm">
        <div class="flex items-center gap-2">
          <span v-if="firstResponseTimeData.status" class="text-base">
            {{ firstResponseTimeData.status }}
          </span>
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.SLA.SLA_TIME') }}
          </span>
          <span class="text-n-slate-12">
            {{ formatDateTime(firstResponseTimeData.slaTime) }}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.SLA.REAL_TIME') }}
          </span>
          <span class="text-n-slate-12">
            {{ formatDateTime(firstResponseTimeData.realTime) }}
          </span>
        </div>
      </div>
    </div>

    <div v-if="nextResponseTimeData.slaTime" class="overflow-auto py-3 px-4">
      <div class="items-center flex justify-between mb-1.5">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('CONVERSATION_SIDEBAR.SLA.NEXT_RESPONSE_TIME') }}
        </span>
      </div>
      <div class="flex flex-col gap-1 text-sm">
        <div class="flex items-center gap-2">
          <span v-if="nextResponseTimeData.status" class="text-base">
            {{ nextResponseTimeData.status }}
          </span>
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.SLA.SLA_TIME') }}
          </span>
          <span class="text-n-slate-12">
            {{ formatDateTime(nextResponseTimeData.slaTime) }}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.SLA.REAL_TIME') }}
          </span>
          <span class="text-n-slate-12">
            {{ formatDateTime(nextResponseTimeData.realTime) }}
          </span>
        </div>
      </div>
    </div>

    <div v-if="resolutionTimeData.slaTime" class="overflow-auto py-3 px-4">
      <div class="items-center flex justify-between mb-1.5">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('CONVERSATION_SIDEBAR.SLA.RESOLUTION_TIME') }}
        </span>
      </div>
      <div class="flex flex-col gap-1 text-sm">
        <div class="flex items-center gap-2">
          <span v-if="resolutionTimeData.status" class="text-base">
            {{ resolutionTimeData.status }}
          </span>
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.SLA.SLA_TIME') }}
          </span>
          <span class="text-n-slate-12">
            {{ formatDateTime(resolutionTimeData.slaTime) }}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <span class="text-n-slate-11">
            {{ $t('CONVERSATION_SIDEBAR.SLA.REAL_TIME') }}
          </span>
          <span class="text-n-slate-12">
            {{ formatDateTime(resolutionTimeData.realTime) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
