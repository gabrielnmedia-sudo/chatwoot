class Api::V1::Twilio::VoiceController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:create], raise: false
  skip_before_action :check_subscription, only: [:create], raise: false
  skip_before_action :set_current_user, only: [:create], raise: false
  skip_before_action :verify_authenticity_token, only: [:create], raise: false

  def create
    Rails.logger.info "TWILIO_VOICE: HIT! Incoming Request. Params: #{params.to_unsafe_h}"

    response = Twilio::TwiML::VoiceResponse.new do |r|
      # AUDIO CHECKPOINT 1: Authentication Success
      r.say(message: 'Connecting your call.')

      begin
        process_call(r)
      rescue StandardError => e
        Rails.logger.error "TWILIO_VOICE: Error processing call: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # DEBUG MODE: Speak the exact error to the user
        r.say(message: "System Error: #{e.message}")
      end
    end

    render xml: response.to_s
  end

  private

  def process_call(r)
    caller_id = ENV['TWILIO_PHONE_NUMBER']

    if params['inbox_id'].present?
      begin
        inbox = Inbox.find_by(id: params['inbox_id'])
        if inbox&.channel_type == 'Channel::TwilioSms'
          channel = inbox.channel
          if channel.phone_number.present?
            caller_id = channel.phone_number
          elsif channel.messaging_service_sid.present?
             client = Twilio::REST::Client.new(ENV['TWILIO_API_KEY_SID'], ENV['TWILIO_API_KEY_SECRET'], ENV['TWILIO_ACCOUNT_SID'])
             phone_numbers = client.messaging.v1.services(channel.messaging_service_sid).phone_numbers.list(limit: 1)
             caller_id = phone_numbers.first.phone_number if phone_numbers.any?
          end
        end
      rescue StandardError => e
        Rails.logger.error "TWILIO_VOICE: Lookup Failed (Safety Fallback): #{e.message}"
        # Silently fail back to default number
      end
    end

    if params['To'].present?
      r.dial(caller_id: caller_id) do |d|
        d.number(params['To'])
      end
    else
      r.say(message: 'Invalid phone number.')
    end
  end
end
