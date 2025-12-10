class Twilio::OneoffSmsCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Twilio SMS' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    # marks campaign completed so that other jobs won't pick it up
    campaign.completed!

    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    process_audience(audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience_labels)
    # 1. Parse Throttling Constraints
    trigger_rules = campaign.trigger_rules || {}
    daily_limit = trigger_rules['daily_limit'].to_i
    daily_limit = 10_000 if daily_limit.zero? # Default to a high number if no limit
    
    window_start_str = trigger_rules['window_start'] || '00:00'
    window_end_str = trigger_rules['window_end'] || '23:59'

    # Prepare Base Schedule (Start Date)
    base_scheduled_at = campaign.scheduled_at || Time.current

    campaign.account.contacts.tagged_with(audience_labels, any: true).each_with_index do |contact, index|
      next if contact.phone_number.blank?

      # 2. Calculate Day Offset based on Daily Limit
      # e.g. Limit 100. Index 0-99 -> Day 0. Index 100-199 -> Day 1.
      day_offset = index / daily_limit
      
      # 3. Calculate Target Date
      target_date = base_scheduled_at + day_offset.days
      
      # 4. Apply Window
      # We just set the time to the window_start for simplicity of the "batch" start.
      # Or we could distribute them evenly within the window. 
      # User requested "3pm to 5pm". 
      # Simplest approach: Schedule them ALL at the start of the window (Sidekiq will just process them as fast as it can).
      # If we want to be fancy, we spread them out. 
      # Let's start with scheduling at Window Start for that day.
      
      start_hour, start_minute = window_start_str.split(':').map(&:to_i)
      target_timestamp = target_date.change(hour: start_hour, min: start_minute)
      
      # Ensure we don't schedule in the past if the window passed for "Today".
      # If target_timestamp < Time.current, we might want to push to tomorrow?
      # But standard behavior is "execute immediately if in past", which is fine for "Today's batch".
      
      # 5. Schedule Job
      ::Campaigns::SmsMessageJob.set(wait_until: target_timestamp).perform_later(
        campaign.id,
        contact.id,
        campaign.inbox.id
      )
      
    rescue StandardError => e
      Rails.logger.error("[Twilio Campaign #{campaign.id}] Failed to schedule contact #{contact.id}: #{e.message}")
    end
  end

  def find_or_create_conversation(contact_inbox)
    # Deprecated in Service: Logic moved to Job
  end

  def create_message(conversation, contact)
    # Deprecated in Service: Logic moved to Job
  end

  def params(contact_inbox)
    # Deprecated in Service: Logic moved to Job
  end
end
