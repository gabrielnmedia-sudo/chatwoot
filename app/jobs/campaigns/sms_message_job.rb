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

    # 3. Create/Send Message
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
