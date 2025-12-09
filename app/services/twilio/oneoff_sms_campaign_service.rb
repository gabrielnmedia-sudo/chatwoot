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
    campaign.account.contacts.tagged_with(audience_labels, any: true).each do |contact|
      next if contact.phone_number.blank?

      contact_inbox = contact.contact_inboxes.find_by(inbox: campaign.inbox)
      next unless contact_inbox

      conversation = find_or_create_conversation(contact_inbox)
      create_message(conversation, contact)
    rescue StandardError => e
      Rails.logger.error("[Twilio Campaign #{campaign.id}] Failed to process contact #{contact.id}: #{e.message}")
    end
  end

  def find_or_create_conversation(contact_inbox)
    conversation = contact_inbox.conversations.open.first
    return conversation if conversation

    ::Conversation.create!(
      params(contact_inbox).merge(
        additional_attributes: { campaign_id: campaign.id }
      )
    )
  end

  def create_message(conversation, contact)
    content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)
    conversation.messages.create!(
      message_type: :outgoing,
      content: content,
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      additional_attributes: { campaign_id: campaign.id }
    )
  end

  def params(contact_inbox)
    {
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      campaign_id: campaign.id
    }
  end
end
