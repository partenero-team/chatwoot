# == Schema Information
#
# Table name: channel_forms
#
#  id                    :bigint           not null, primary key
#  allowed_domains       :text             default("")
#  continuity_via_email  :boolean          default(TRUE), not null
#  feature_flags         :integer          default(7), not null
#  form_color            :string           default("#1f93ff")
#  form_description      :string
#  form_title            :string
#  form_token            :string
#  form_url              :string
#  hmac_mandatory        :boolean          default(FALSE)
#  hmac_token            :string
#  pre_chat_form_enabled :boolean          default(FALSE)
#  pre_chat_form_options :jsonb
#  reply_time            :integer          default("in_a_few_minutes")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_channel_forms_on_account_id  (account_id)
#  index_channel_forms_on_form_token  (form_token) UNIQUE
#  index_channel_forms_on_hmac_token  (hmac_token) UNIQUE
#

class Channel::Form < ApplicationRecord
  include Channelable
  include FlagShihTzu

  self.table_name = 'channel_forms'
  EDITABLE_ATTRS = [:form_url, :form_color, :form_title, :form_description, :reply_time, :pre_chat_form_enabled,
                    :continuity_via_email, :hmac_mandatory, :allowed_domains,
                    { pre_chat_form_options: [:pre_chat_message, :require_email,
                                              { pre_chat_fields:
                                                [:field_type, :label, :placeholder, :name, :enabled, :type, :enabled, :required,
                                                 :locale, { values: [] }, :regex_pattern, :regex_cue] }] },
                    { selected_feature_flags: [] }].freeze

  after_initialize :set_default_pre_chat_form_enabled
  before_validation :validate_pre_chat_options
  validates :form_url, presence: true
  validates :form_color, presence: true

  has_secure_token :form_token
  has_secure_token :hmac_token

  has_flags 1 => :attachments,
            2 => :emoji_picker,
            3 => :end_conversation,
            4 => :use_inbox_avatar_for_bot,
            :column => 'feature_flags',
            :check_for_column => false

  enum reply_time: { in_a_few_minutes: 0, in_a_few_hours: 1, in_a_day: 2 }

  attr_accessor :selected_feature_flags

  def name
    'Form'
  end

  def public_form_url
    base_url = ENV.fetch('FRONTEND_URL', '')
    "#{base_url}/widget?form_token=#{form_token}"
  end

  def form_script
    base_url = ENV.fetch('FRONTEND_URL', '')
    "
<!-- Chatwoot Form Script -->
<!-- Copy and paste this code before the closing </body> tag of your website -->
<script>
  (function(d,t) {
    var BASE_URL=\"#{base_url}\";
    var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
    g.src=BASE_URL+\"/packs/js/sdk.js\";
    g.async = true;
    s.parentNode.insertBefore(g,s);
    g.onload=function(){
      window.chatwootSDK.run({
        websiteToken: '#{form_token}',
        baseUrl: BASE_URL
      })
    }
  })(document,\"script\");
</script>
    ".strip
  end

  def validate_pre_chat_options
    return if pre_chat_form_options.with_indifferent_access['pre_chat_fields'].present?

    self.pre_chat_form_options = {
      pre_chat_message: 'Please fill out the form below to start a conversation.',
      pre_chat_fields: [
        {
          'field_type': 'standard', 'label': 'Email Address', 'name': 'emailAddress', 'type': 'email', 'required': true, 'enabled': false
        },
        {
          'field_type': 'standard', 'label': 'Full Name', 'name': 'fullName', 'type': 'text', 'required': false, 'enabled': false
        },
        {
          'field_type': 'standard', 'label': 'Phone Number', 'name': 'phoneNumber', 'type': 'text', 'required': false, 'enabled': false
        }
      ]
    }
  end

  def set_default_pre_chat_form_enabled
    self.pre_chat_form_enabled = true if new_record? && pre_chat_form_enabled.nil?
  end

  def create_contact_inbox(additional_attributes = {})
    ::ContactInboxWithContactBuilder.new({
                                           inbox: inbox,
                                           contact_attributes: { additional_attributes: additional_attributes }
                                         }).perform
  end
end
