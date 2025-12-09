class Api::V1::Twilio::VoiceController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:create], raise: false
  skip_before_action :check_subscription, only: [:create], raise: false
  skip_before_action :set_current_user, only: [:create], raise: false

  def create
    Rails.logger.info "TWILIO_VOICE: HIT! Hardcoded mode."
    
    response = Twilio::TwiML::VoiceResponse.new do |r|
      # Hardcoded fallback for debugging
      r.dial(caller_id: ENV['TWILIO_PHONE_NUMBER']) do |d|
        d.number('+14254354112')
      end
    end

    render xml: response.to_s
  end
  
  private
  
  def process_call(r)
    # Disabled for debugging
  end
end
