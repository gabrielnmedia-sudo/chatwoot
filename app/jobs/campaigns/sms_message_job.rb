class Campaigns::SmsMessageJob < ApplicationJob
  queue_as :low_priority

  def perform(campaign_id, contact_id, inbox_id)
    campaign = Campaign.find(campaign_id)
    contact = Contact.find(contact_id)
    inbox = Inbox.find(inbox_id)

    # 1. Ensure Inbox Logic
    contact_inbox = contact.contact_inboxes.find_by(inbox: inbox)
    return unless contact_inbox

    # 2. Find or Create Conversation
    conversation = contact_inbox.conversations.open.first || ::Conversation.create!(
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: { campaign_id: campaign.id }
    )

    # 3. Check Global Tenant Limit (JIT Throttling)
    trigger_rules = campaign.trigger_rules || {}
    daily_limit = trigger_rules['daily_limit'].to_i
    
    if daily_limit > 0
      current_date = Time.current.to_date.to_s
      redis_key = "sms_limit:#{campaign.account_id}:#{current_date}"
      
      # Use $alfred (General Purpose Redis)
      count = $alfred.with { |conn| conn.incr(redis_key) }
      # Set expiry if new key (for 48 hours to be safe)
      $alfred.with { |conn| conn.expire(redis_key, 48.hours.to_i) } if count == 1

      if count > daily_limit
        # Limit Exceeded: Reschedule for Tomorrow
        Rails.logger.info("[Campaigns::SmsMessageJob] Daily Limit #{daily_limit} hit for Account #{campaign.account_id}. Rescheduling.")
        
        # Calculate Tomorrow's Window
        window_start_str = trigger_rules['window_start'] || '09:00'
        start_hour, start_minute = window_start_str.split(':').map(&:to_i)
        
        tomorrow = Time.current.tomorrow
        tomorrow_window = tomorrow.change(hour: start_hour, min: start_minute)
        
        # Reschedule
        self.class.set(wait_until: tomorrow_window).perform_later(campaign_id, contact_id, inbox_id)
        return
      end
    end

    # 4. Create/Send Message
    content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)
    
    conversation.messages.create!(
      message_type: :outgoing,
      content: content,
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      additional_attributes: { campaign_id: campaign.id }
    )
  rescue StandardError => e
    Rails.logger.error("[Campaigns::SmsMessageJob] Failed for Campaign #{campaign_id} / Contact #{contact_id}: #{e.message}")
  end
end
