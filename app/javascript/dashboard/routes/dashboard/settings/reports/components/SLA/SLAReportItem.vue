<script setup>
import { computed } from 'vue';
import { format, fromUnixTime, intervalToDuration } from 'date-fns';

import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import CardLabels from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue';
import SLAViewDetails from './SLAViewDetails.vue';

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
    default: () => ({}),
  },
});

const { SLA_MISS_TYPES } = wootConstants;

const conversationLabels = computed(() => {
  return props.conversation.labels
    ? props.conversation.labels.split(',').map(item => item.trim())
    : [];
});

const routerParams = computed(() => ({
  name: 'inbox_conversation',
  params: { conversation_id: props.conversationId },
}));

const formatDuration = seconds => {
  if (!seconds || seconds < 0) return '--';

  const duration = intervalToDuration({
    start: 0,
    end: seconds * 1000,
  });

  const parts = [];
  if (duration.days) parts.push(`${duration.days}d`);
  if (duration.hours) parts.push(`${duration.hours}h`);
  if (duration.minutes) parts.push(`${duration.minutes}m`);
  if (!parts.length && duration.seconds) parts.push(`${duration.seconds}s`);

  return parts.join(' ') || '0s';
};

const formatThreshold = threshold =>
  threshold ? formatDuration(threshold) : '--';

const formatSlaStartTime = computed(() => {
  return props.appliedSla.created_at
    ? format(
        fromUnixTime(props.appliedSla.created_at),
        'MMM dd, yyyy, HH:mm'
      )
    : '--';
});

const getEventByType = type =>
  props.slaEvents.find(e => e.event_type === type);

const calculateFRRealTime = (event, threshold) => {

  const frCreatedAt = createdAt = event ? event.created_at : props.conversation.first_reply_created_at;

  if (!frCreatedAt) {
    return { time: '--', dot: null, textClass: '' };
  }

  const realSeconds = frCreatedAt - props.appliedSla.created_at;
  const time = formatDuration(realSeconds);

  if (!threshold) {
    return { time, dot: null, textClass: '' };
  }

  const diff = realSeconds - threshold;

  return buildReturnValue(diff, time);  
};

const calculateResolutionTime = (event, threshold) => {

  const rtCreatedAt = createdAt = event ? event.created_at : props.conversation.updated_at;
  const slaAppliedAt = props.appliedSla.created_at;
  const status = props.conversation.status;

  if (!rtCreatedAt || !slaAppliedAt || status !== 'resolved') {
    return { time: '--', dot: null, textClass: '' };
  }
  
  const realSeconds = rtCreatedAt - slaAppliedAt;
  const time = formatDuration(realSeconds);

  if (!threshold) {
    return { time, dot: null, textClass: '' };
  }

  const diff = realSeconds - threshold;

  return buildReturnValue(diff, time);

};

const buildReturnValue = (diff, time) => {
  if (diff <= 0) {
    return { time, dot: 'bg-green-600', textClass: 'text-green-600' };
  }

  if (diff <= threshold * 0.2) {
    return { time, dot: 'bg-yellow-600', textClass: 'text-yellow-600' };
  }

  return { time, dot: 'bg-red-600', textClass: 'text-red-600' };
};

const frt = computed(() =>
  calculateFRRealTime(
    getEventByType(SLA_MISS_TYPES.FRT),
    props.appliedSla.sla_first_response_time_threshold
  )
);

// const nrt = computed(() =>
//   calculateRealTime(
//     getEventByType(SLA_MISS_TYPES.NRT),
//     props.appliedSla.sla_next_response_time_threshold
//   )
// );

const rt = computed(() =>
  calculateResolutionTime(
    getEventByType(SLA_MISS_TYPES.RT),
    props.appliedSla.sla_resolution_time_threshold
  )
);
</script>

<template>
  <div
    class="grid grid-cols-[3fr_1.5fr_1.5fr_1.5fr_2fr_2fr] gap-x-6 px-10 py-6 items-center text-sm border-b border-n-weak last:border-b-0"
  >
    <!-- Conversation -->
    <div class="flex items-center gap-2 min-w-0 self-center">
      <router-link
        :to="routerParams"
        class="text-n-slate-12 hover:underline flex-shrink-0"
      >
        #{{ conversationId }}
      </router-link>
      <span class="text-n-slate-11 flex-shrink-0">with</span>
      <span class="truncate text-n-slate-12 min-w-0">
        {{ conversation.contact.name }}
      </span>
      <CardLabels
        v-if="conversationLabels.length"
        class="flex-shrink-0"
        :conversation-id="conversationId"
        :conversation-labels="conversationLabels"
      />
    </div>

    <!-- Policy -->
    <div class="truncate self-center text-center" :title="slaName">
      {{ slaName }}
    </div>

    <!-- Agent (FIX DEFINITIVO) -->
    <div class="flex items-center min-w-[120px] self-center" :class="conversation.assignee ? '' : 'justify-center'">
      <UserAvatarWithName
        v-if="conversation.assignee"
        :user="conversation.assignee"
      />
      <span v-else class="text-n-slate-11">---</span>
    </div>

    <!-- SLA Start -->
    <div class="text-xs text-n-slate-11 self-center text-center">
      {{ formatSlaStartTime }}
    </div>

    <!-- FRT -->
    <div class="flex flex-col gap-0.5 text-xs self-center">
      <div class="flex items-center gap-2">
        <span class="text-n-slate-11">SLA:</span>
        <span class="font-medium">{{
          formatThreshold(appliedSla.sla_first_response_time_threshold)
        }}</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="text-n-slate-11">Real:</span>
        <span class="font-medium" :class="frt.textClass">{{ frt.time }}</span>
        <span
          v-if="frt.dot"
          class="w-2 h-2 rounded-full flex-shrink-0"
          :class="frt.dot"
        ></span>
      </div>
    </div>

    <!-- NRT 
    <div class="flex flex-col gap-0.5 text-xs self-center">
      <div class="flex items-center gap-2">
        <span class="text-n-slate-11">SLA:</span>
        <span class="font-medium">{{
          formatThreshold(appliedSla.sla_next_response_time_threshold)
        }}</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="text-n-slate-11">Real:</span>
        <span class="font-medium" :class="nrt.textClass">{{ nrt.time }}</span>
        <span
          v-if="nrt.dot"
          class="w-2 h-2 rounded-full flex-shrink-0"
          :class="nrt.dot"
        ></span>
      </div>
    </div>
    -->
    <!-- RT -->
    <div class="flex flex-col gap-0.5 text-xs self-center">
      <div class="flex items-center gap-2">
        <span class="text-n-slate-11">SLA:</span>
        <span class="font-medium">{{
          formatThreshold(appliedSla.sla_resolution_time_threshold)
        }}</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="text-n-slate-11">Real:</span>
        <span class="font-medium" :class="rt.textClass">{{ rt.time }}</span>
        <span
          v-if="rt.dot"
          class="w-2 h-2 rounded-full flex-shrink-0"
          :class="rt.dot"
        ></span>
      </div>
    </div>

    <!-- <SLAViewDetails :sla-events="slaEvents" /> -->
  </div>
</template>
