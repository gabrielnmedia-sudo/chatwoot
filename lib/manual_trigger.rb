class ManualTrigger
  def self.execute(inbox_id)
    inbox = Inbox.find(inbox_id)
    # Logic to manually trigger inbox processing
    # (Placeholder based on user's previous request context)
    Rails.logger.info "Manually triggering processing for Inbox #{inbox_id}"
  end
end
