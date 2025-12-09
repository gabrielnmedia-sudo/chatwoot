class Api::V1::Twilio::VoiceController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:create]
  skip_before_action :check_subscription, only: [:create]

  def create
    response = Twilio::TwiML::VoiceResponse.new do |r|
      caller_id = ENV['TWILIO_PHONE_NUMBER']

      if params['inbox_id'].present?
        inbox = Inbox.find_by(id: params['inbox_id'])
        if inbox&.channel_type == 'Channel::TwilioSms'
          channel = inbox.channel
          if channel.phone_number.present?
            caller_id = channel.phone_number
          elsif channel.messaging_service_sid.present?
            # Fetch a number from the scheduling pool
            # We use the first available number in the service
            begin
              client = Twilio::REST::Client.new(ENV['TWILIO_API_KEY_SID'], ENV['TWILIO_API_KEY_SECRET'], ENV['TWILIO_ACCOUNT_SID'])
              
              phone_numbers = client.messaging.v1.services(channel.messaging_service_sid).phone_numbers.list(limit: 1)
              caller_id = phone_numbers.first.phone_number if phone_numbers.any?
            rescue StandardError => e
              Rails.logger.error "Failed to fetch phone number from Messaging Service: #{e.message}"
            end
          end
        end
      end

      if params['To'].present?
        # Wrap the phone number in <Number>, which causes Twilio to dial it
        dial = Twilio::TwiML::VoiceResponse::Dial.new(caller_id: caller_id)
        dial.number(params['To'])
        r.append(dial)
      else
        r.say(message: 'Invalid phone number.')
      end
    end

    render xml: response.to_s
  end
end
