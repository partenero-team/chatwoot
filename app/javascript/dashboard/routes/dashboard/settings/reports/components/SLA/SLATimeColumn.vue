<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { convertSecondsToTimeUnit } from '@chatwoot/utils';

const props = defineProps({
  slaTime: {
    type: Number,
    default: null,
  },
  realTime: {
    type: Number,
    default: null,
  },
});

const { t } = useI18n();

const displaySlaTime = computed(() => {
  if (!props.slaTime) return '--';
  const { time, unit } = convertSecondsToTimeUnit(props.slaTime, {
    minute: 'm',
    hour: 'h',
    day: 'd',
  });
  return `${time}${unit}`;
});

const displayRealTime = computed(() => {
  if (props.realTime === null || props.realTime === undefined) return '--';
  const { time, unit } = convertSecondsToTimeUnit(props.realTime, {
    minute: 'm',
    hour: 'h',
    day: 'd',
  });
  return `${time}${unit}`;
});

const statusIndicator = computed(() => {
  if (
    props.realTime === null ||
    props.realTime === undefined ||
    !props.slaTime
  ) {
    return null;
  }
  return props.realTime <= props.slaTime ? '🟢' : '🟡';
});
</script>

<template>
  <div class="flex flex-col gap-1 text-sm">
    <div class="flex items-center gap-2">
      <span class="text-n-slate-11">{{
        t('SLA_REPORTS.TABLE.SLA_TIME_LABEL')
      }}</span>
      <span class="text-n-slate-12">{{ displaySlaTime }}</span>
    </div>
    <div class="flex items-center gap-2">
      <span class="text-n-slate-11">{{
        t('SLA_REPORTS.TABLE.REAL_TIME_LABEL')
      }}</span>
      <span class="text-n-slate-12">{{ displayRealTime }}</span>
      <span v-if="statusIndicator" class="text-base">{{
        statusIndicator
      }}</span>
    </div>
  </div>
</template>
