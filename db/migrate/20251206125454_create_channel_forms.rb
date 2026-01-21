class CreateChannelForms < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_forms do |t|
      t.integer :account_id, null: false
      t.string :form_token
      t.string :hmac_token
      t.boolean :pre_chat_form_enabled, default: true
      t.jsonb :pre_chat_form_options, default: {}
      t.boolean :hmac_mandatory, default: false
      t.text :allowed_domains, default: ''
      t.integer :feature_flags, default: 7, null: false
      t.string :form_url
      t.string :form_title
      t.string :form_description
      t.string :form_color, default: '#1f93ff'
      t.integer :reply_time, default: 0
      t.boolean :continuity_via_email, default: true, null: false

      t.timestamps
    end

    add_index :channel_forms, :form_token, unique: true
    add_index :channel_forms, :hmac_token, unique: true
    add_index :channel_forms, :account_id
  end
end
