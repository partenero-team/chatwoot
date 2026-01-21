# loading installation configs
GlobalConfig.clear_cache
ConfigLoader.new.process

## Seeds productions
if Rails.env.production?
  # Setup Onboarding flow
  Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
end

## Seeds for Local Development
unless Rails.env.production?

  # Enables creating additional accounts from dashboard
  installation_config = InstallationConfig.find_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
  installation_config.value = true
  installation_config.save!
  GlobalConfig.clear_cache

  account = Account.create!(
    name: 'Acme Inc'
  )

  secondary_account = Account.create!(
    name: 'Acme Org'
  )

  user = User.find_or_initialize_by(email: 'john@acme.inc') do |u|
    u.name = 'John'
    u.password = 'Password1!'
    u.type = 'SuperAdmin'
    u.skip_confirmation!
  end
  user.save!

  AccountUser.create!(
    account_id: account.id,
    user_id: user.id,
    role: :administrator
  )

  AccountUser.create!(
    account_id: secondary_account.id,
    user_id: user.id,
    role: :administrator
  )

  web_widget = Channel::WebWidget.create!(account: account, website_url: 'https://acme.inc')

  inbox = Inbox.create!(channel: web_widget, account: account, name: 'Acme Support')
  InboxMember.create!(user: user, inbox: inbox)

  contact_inbox = ContactInboxWithContactBuilder.new(
    source_id: user.id,
    inbox: inbox,
    hmac_verified: true,
    contact_attributes: { name: 'jane', email: 'jane@example.com', phone_number: '+2320000' }
  ).perform

  conversation = Conversation.create!(
    account: account,
    inbox: inbox,
    status: :open,
    assignee: user,
    contact: contact_inbox.contact,
    contact_inbox: contact_inbox,
    additional_attributes: {}
  )

  # sample email collect
  Seeders::MessageSeeder.create_sample_email_collect_message conversation

  Message.create!(content: 'Hello', account: account, inbox: inbox, conversation: conversation, sender: contact_inbox.contact,
                  message_type: :incoming)

  # Enable SLA feature for the account (Enterprise feature)
  if defined?(ChatwootApp) && ChatwootApp.enterprise?
    account.enable_features!('sla')

    # Create an SLA policy
    sla_policy = SlaPolicy.create!(
      account: account,
      name: 'Premium Support SLA',
      description: 'SLA for premium customers with fast response times',
      first_response_time_threshold: 3600, # 1 hour in seconds
      next_response_time_threshold: 1800, # 30 minutes in seconds
      resolution_time_threshold: 86_400, # 24 hours in seconds
      only_during_business_hours: false
    )

    # Apply SLA to conversation
    conversation.update!(sla_policy: sla_policy)

    # Create applied_sla (this should be created automatically, but we'll ensure it exists)
    AppliedSla.find_or_create_by!(
      account: account,
      conversation: conversation,
      sla_policy: sla_policy
    )

    # Create a first reply message (this will set first_reply_created_at)
    first_reply_time = conversation.created_at + 30.minutes
    Message.create!(
      content: 'Thank you for contacting us. How can I help you today?',
      account: account,
      inbox: inbox,
      conversation: conversation,
      sender: user,
      message_type: :outgoing,
      created_at: first_reply_time
    )
    conversation.update_column(:first_reply_created_at, first_reply_time)

    # Set waiting_since to show next response time (set it to 1 hour after first reply)
    # This simulates a customer message after the first reply
    waiting_since_time = first_reply_time + 1.hour
    conversation.update_column(:waiting_since, waiting_since_time)

    # Create a follow-up customer message
    Message.create!(
      content: 'I have another question',
      account: account,
      inbox: inbox,
      conversation: conversation,
      sender: contact_inbox.contact,
      message_type: :incoming,
      created_at: waiting_since_time
    )

    # Create a second agent reply (this will clear waiting_since)
    second_reply_time = waiting_since_time + 15.minutes # Within SLA (15 min < 30 min threshold)
    Message.create!(
      content: 'Sure, what would you like to know?',
      account: account,
      inbox: inbox,
      conversation: conversation,
      sender: user,
      message_type: :outgoing,
      created_at: second_reply_time
    )
    conversation.update_column(:waiting_since, nil)
  end

  # sample location message
  #
  location_message = Message.new(content: 'location', account: account, inbox: inbox, sender: contact_inbox.contact, conversation: conversation,
                                 message_type: :incoming)
  location_message.attachments.new(
    account_id: account.id,
    file_type: 'location',
    coordinates_lat: 37.7893768,
    coordinates_long: -122.3895553,
    fallback_title: 'Bay Bridge, San Francisco, CA, USA'
  )
  location_message.save!

  # sample card
  Seeders::MessageSeeder.create_sample_cards_message conversation
  # input select
  Seeders::MessageSeeder.create_sample_input_select_message conversation
  # form
  Seeders::MessageSeeder.create_sample_form_message conversation
  # articles
  Seeders::MessageSeeder.create_sample_articles_message conversation
  # csat
  Seeders::MessageSeeder.create_sample_csat_collect_message conversation

  CannedResponse.create!(account: account, short_code: 'start', content: 'Hello welcome to chatwoot.')

  # Create a new conversation with SLA data for testing
  if defined?(ChatwootApp) && ChatwootApp.enterprise?
    # Ensure SLA feature is enabled
    account.enable_features!('sla') unless account.feature_enabled?('sla')

    # Create or find an SLA policy
    sla_policy = SlaPolicy.find_or_create_by!(
      account: account,
      name: 'Premium Support SLA'
    ) do |policy|
      policy.description = 'SLA for premium customers with fast response times'
      policy.first_response_time_threshold = 3600 # 1 hour in seconds
      policy.next_response_time_threshold = 1800 # 30 minutes in seconds
      policy.resolution_time_threshold = 86_400 # 24 hours in seconds
      policy.only_during_business_hours = false
    end

    # Create a new contact for the SLA conversation
    sla_contact = account.contacts.find_or_create_by!(email: 'sla-customer@example.com') do |contact|
      contact.name = 'SLA Customer'
      contact.phone_number = '+1234567890'
    end

    # Create contact inbox
    sla_contact_inbox = inbox.contact_inboxes.find_or_create_by!(contact: sla_contact) do |ci|
      ci.source_id = SecureRandom.hex
    end

    # Create the conversation with SLA (only if it doesn't exist)
    sla_conversation = Conversation.find_or_initialize_by(
      account: account,
      contact: sla_contact,
      sla_policy: sla_policy
    ) do |conv|
      conv.inbox = inbox
      conv.status = :open
      conv.assignee = user
      conv.contact_inbox = sla_contact_inbox
      conv.additional_attributes = {}
    end

    # Only create messages if this is a new conversation
    if sla_conversation.new_record?
      sla_conversation.save!

      # Create initial customer message
      Message.create!(
        content: 'I need help with my premium account',
        account: account,
        inbox: inbox,
        conversation: sla_conversation,
        sender: sla_contact,
        message_type: :incoming,
        created_at: sla_conversation.created_at
      )

      # Create first reply (30 minutes after conversation start - within SLA)
      first_reply_time = sla_conversation.created_at + 30.minutes
      Message.create!(
        content: 'Hello! Thank you for contacting premium support. I\'ll be happy to help you.',
        account: account,
        inbox: inbox,
        conversation: sla_conversation,
        sender: user,
        message_type: :outgoing,
        created_at: first_reply_time
      )
      sla_conversation.update_column(:first_reply_created_at, first_reply_time)

      # Customer sends a follow-up message (1 hour after first reply)
      waiting_since_time = first_reply_time + 1.hour
      Message.create!(
        content: 'Actually, I have another question about billing',
        account: account,
        inbox: inbox,
        conversation: sla_conversation,
        sender: sla_contact,
        message_type: :incoming,
        created_at: waiting_since_time
      )
      sla_conversation.update_column(:waiting_since, waiting_since_time)

      # Agent responds quickly (15 minutes later - within SLA for next response)
      second_reply_time = waiting_since_time + 15.minutes
      Message.create!(
        content: 'Of course! I can help you with billing questions. What would you like to know?',
        account: account,
        inbox: inbox,
        conversation: sla_conversation,
        sender: user,
        message_type: :outgoing,
        created_at: second_reply_time
      )
      sla_conversation.update_column(:waiting_since, nil)

      # Customer sends another message
      third_customer_message_time = second_reply_time + 2.hours
      Message.create!(
        content: 'When will my subscription renew?',
        account: account,
        inbox: inbox,
        conversation: sla_conversation,
        sender: sla_contact,
        message_type: :incoming,
        created_at: third_customer_message_time
      )
      sla_conversation.update_column(:waiting_since, third_customer_message_time)

      # Agent responds (35 minutes later - exceeds SLA for next response, shows 🟡)
      third_reply_time = third_customer_message_time + 35.minutes
      Message.create!(
        content: 'Your subscription will renew on the 15th of next month.',
        account: account,
        inbox: inbox,
        conversation: sla_conversation,
        sender: user,
        message_type: :outgoing,
        created_at: third_reply_time
      )
      sla_conversation.update_column(:waiting_since, nil)

      # Resolve the conversation (20 hours after start - within SLA for resolution)
      resolution_time = sla_conversation.created_at + 20.hours
      sla_conversation.update_column(:status, :resolved)
      sla_conversation.update_column(:updated_at, resolution_time)
    end
  end
end
