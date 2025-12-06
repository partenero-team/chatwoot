<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { format, fromUnixTime } from 'date-fns';

const props = defineProps({
  slaName: {
    type: String,
    required: true,
  },
  conversationId: {
    type: Number,
    required: true,
  },
  conversation: {
    type: Object,
    required: true,
  },
  slaEvents: {
    type: Array,
    default: () => [],
  },
  appliedSla: {
    type: Object,
    required: true,
  },
});
const { t } = useI18n();
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import CardLabels from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue';
import SLAViewDetails from './SLAViewDetails.vue';
import SLATimeColumn from './SLATimeColumn.vue';

const conversationLabels = computed(() => {
  return props.conversation.labels
    ? props.conversation.labels.split(',').map(item => item.trim())
    : [];
});

const routerParams = computed(() => ({
  name: 'inbox_conversation',
  params: { conversation_id: props.conversationId },
}));

// Calculate real times and SLA times
const firstResponseTimeData = computed(() => {
  const slaAppliedAt = props.appliedSla.created_at;
  const slaThreshold = props.appliedSla.sla_first_response_time_threshold;

  if (!slaThreshold) {
    return { slaTime: null, realTime: null };
  }

  const slaTime = slaThreshold;
  let realTime = null;

  if (props.conversation.first_reply_created_at) {
    realTime = props.conversation.first_reply_created_at - slaAppliedAt;
  }

  return { slaTime, realTime };
});

const nextResponseTimeData = computed(() => {
  const slaThreshold = props.appliedSla.sla_next_response_time_threshold;

  if (!slaThreshold) {
    return { slaTime: null, realTime: null };
  }

  const slaTime = slaThreshold;
  let realTime = null;

  // For next response time, we need to find when the agent responded after waiting_since
  // This is more complex - we'd need message data. For now, we'll show the SLA time
  // and mark real time as null if waiting_since exists but no response yet
  if (props.conversation.waiting_since) {
    // If still waiting, real time is not available yet
    // If there's a response after waiting_since, we'd need message timestamps
    // For MVP, we'll show -- for real time if waiting_since exists
    realTime = null;
  }

  return { slaTime, realTime };
});

const resolutionTimeData = computed(() => {
  const slaAppliedAt = props.appliedSla.created_at;
  const slaThreshold = props.appliedSla.sla_resolution_time_threshold;

  if (!slaThreshold) {
    return { slaTime: null, realTime: null };
  }

  const slaTime = slaThreshold;
  let realTime = null;

  if (
    props.conversation.status === 'resolved' &&
    props.conversation.updated_at
  ) {
    realTime = props.conversation.updated_at - slaAppliedAt;
  }

  return { slaTime, realTime };
});

const formatSlaStartTime = timestamp => {
  if (!timestamp) return '--';
  return format(fromUnixTime(timestamp), 'MMM dd, yyyy, hh:mm a');
};
</script>

<template>
  <div
    class="grid items-center content-center w-full h-16 grid-cols-12 gap-4 px-6 py-0 border-b last:border-b-0 last:rounded-b-xl border-n-weak"
  >
    <div
      class="flex items-center gap-2 col-span-2 px-0 py-2 text-sm tracking-[0.5] text-n-slate-12 rtl:text-right"
    >
      <router-link :to="routerParams" class="text-n-slate-12 hover:underline">
        {{ `#${conversationId}` }}
      </router-link>
      <span class="text-n-slate-11">
        {{ $t('SLA_REPORTS.WITH') }}
      </span>
      <span class="capitalize truncate text-n-slate-12">{{
        conversation.contact.name
      }}</span>
      <CardLabels
        v-if="conversationLabels.length"
        class="w-[60%]"
        :conversation-id="conversationId"
        :conversation-labels="conversationLabels"
      />
    </div>
    <div
      class="flex items-center capitalize py-2 px-0 text-sm tracking-[0.5] text-n-slate-12 text-left rtl:text-right col-span-1"
    >
      {{ slaName }}
    </div>
    <div class="flex items-center col-span-1 gap-2">
      <UserAvatarWithName
        v-if="conversation.assignee"
        :user="conversation.assignee"
      />
      <span v-else class="text-n-slate-11">{{
        t('SLA_REPORTS.TABLE.NO_AGENT')
      }}</span>
    </div>
    <div
      class="flex items-center py-2 px-0 text-xs tracking-[0.5] text-n-slate-12 text-left rtl:text-right col-span-1"
    >
      {{ formatSlaStartTime(appliedSla.created_at) }}
    </div>
    <div class="col-span-2">
      <SLATimeColumn
        :sla-time="firstResponseTimeData.slaTime"
        :real-time="firstResponseTimeData.realTime"
      />
    </div>
    <div class="col-span-2">
      <SLATimeColumn
        :sla-time="nextResponseTimeData.slaTime"
        :real-time="nextResponseTimeData.realTime"
      />
    </div>
    <div class="col-span-2">
      <SLATimeColumn
        :sla-time="resolutionTimeData.slaTime"
        :real-time="resolutionTimeData.realTime"
      />
    </div>
    <SLAViewDetails :sla-events="slaEvents" />
  </div>
</template>
