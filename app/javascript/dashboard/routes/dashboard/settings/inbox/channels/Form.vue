<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../../index';
import NextButton from 'dashboard/components-next/button/Button.vue';
import PageHeader from '../../SettingsSubPageHeader.vue';
import { WIDGET_BUILDER_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

export default {
  components: {
    PageHeader,
    NextButton,
    Editor,
  },
  data() {
    return {
      inboxName: '',
      channelFormUrl: '',
      channelFormColor: '#009CE0',
      channelFormTitle: '',
      channelFormDescription: '',
      formDescriptionEditorMenuOptions: WIDGET_BUILDER_EDITOR_MENU_OPTIONS,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    textAreaChannels() {
      if (
        this.isATwilioChannel ||
        this.isATwitterInbox ||
        this.isAFacebookInbox
      )
        return true;
      return false;
    },
  },
  methods: {
    async createChannel() {
      try {
        const form = await this.$store.dispatch('inboxes/createFormChannel', {
          name: this.inboxName?.trim(),
          greeting_enabled: false,
          greeting_message: '',
          channel: {
            type: 'form',
            form_url: this.channelFormUrl,
            form_color: this.channelFormColor,
            form_title: this.channelFormTitle,
            form_description: this.channelFormDescription,
          },
        });
        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: form.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.FORM_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.FORM_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.FORM_CHANNEL.DESC')"
    />
    <woot-loading-state
      v-if="uiFlags.isCreating"
      :message="$t('INBOX_MGMT.ADD.FORM_CHANNEL.LOADING_MESSAGE')"
    />
    <form
      v-if="!uiFlags.isCreating"
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel"
    >
      <div class="w-full">
        <label>
          {{ $t('INBOX_MGMT.ADD.FORM_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.FORM_NAME.PLACEHOLDER')"
          />
        </label>
      </div>
      <div class="w-full">
        <label>
          {{ $t('INBOX_MGMT.ADD.FORM_CHANNEL.CHANNEL_DOMAIN.LABEL') }}
          <input
            v-model="channelFormUrl"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.FORM_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER')
            "
          />
        </label>
      </div>

      <div class="w-full">
        <label>
          {{ $t('INBOX_MGMT.ADD.FORM_CHANNEL.FORM_COLOR.LABEL') }}
          <woot-color-picker v-model="channelFormColor" />
        </label>
      </div>

      <div class="w-full">
        <label>
          {{ $t('INBOX_MGMT.ADD.FORM_CHANNEL.CHANNEL_FORM_TITLE.LABEL') }}
          <input
            v-model="channelFormTitle"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.FORM_CHANNEL.CHANNEL_FORM_TITLE.PLACEHOLDER')
            "
          />
        </label>
      </div>
      <Editor
        v-model="channelFormDescription"
        :label="
          $t('INBOX_MGMT.ADD.FORM_CHANNEL.CHANNEL_FORM_DESCRIPTION.LABEL')
        "
        :placeholder="
          $t('INBOX_MGMT.ADD.FORM_CHANNEL.CHANNEL_FORM_DESCRIPTION.PLACEHOLDER')
        "
        :max-length="255"
        :enabled-menu-options="formDescriptionEditorMenuOptions"
        class="mb-4"
      />

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2 mt-4">
        <div class="w-full">
          <NextButton
            type="submit"
            :is-loading="uiFlags.isCreating"
            :disabled="!channelFormUrl || !inboxName"
            solid
            blue
            :label="$t('INBOX_MGMT.ADD.FORM_CHANNEL.SUBMIT_BUTTON')"
          />
        </div>
      </div>
    </form>
  </div>
</template>
