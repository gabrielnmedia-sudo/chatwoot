class Api::V1::Twilio::VoiceController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:create], raise: false
  skip_before_action :check_subscription, only: [:create], raise: false
  skip_before_action :set_current_user, only: [:create], raise: false

  def create
    Rails.logger.info "TWILIO_VOICE: Incoming Request. Params: #{params.to_unsafe_h}"

    response = Twilio::TwiML::VoiceResponse.new do |r|
      begin
        process_call(r)
      rescue StandardError => e
        Rails.logger.error "TWILIO_VOICE: Error processing call: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        r.say(message: 'Sorry, an error occurred while connecting your call.')
      end
    end

    render xml: response.to_s
  end

  private

  def process_call(r)
    caller_id = ENV['TWILIO_PHONE_NUMBER']

    if params['inbox_id'].present?
      inbox = Inbox.find_by(id: params['inbox_id'])
      if inbox&.channel_type == 'Channel::TwilioSms'
        channel = inbox.channel
        if channel.phone_number.present?
          caller_id = channel.phone_number
        elsif channel.messaging_service_sid.present?
          begin
            client = Twilio::REST::Client.new(ENV['TWILIO_API_KEY_SID'], ENV['TWILIO_API_KEY_SECRET'], ENV['TWILIO_ACCOUNT_SID'])
            phone_numbers = client.messaging.v1.services(channel.messaging_service_sid).phone_numbers.list(limit: 1)
            caller_id = phone_numbers.first.phone_number if phone_numbers.any?
          rescue StandardError => e
            Rails.logger.error "TWILIO_VOICE: Failed to fetch Messaging Service number: #{e.message}"
            # Fallback to default caller_id
          end
        end
      end
    end

    if params['To'].present?
      dial = Twilio::TwiML::VoiceResponse::Dial.new(caller_id: caller_id)
      dial.number(params['To'])
      r.append(dial)
    else
      r.say(message: 'Invalid phone number.')
    end
  end
end
