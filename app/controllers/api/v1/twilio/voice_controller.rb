class Api::V1::Twilio::VoiceController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:create]
  skip_before_action :check_subscription, only: [:create]

  def create
    response = Twilio::TwiML::VoiceResponse.new do |r|
      if params['To'].present?
        # Wrap the phone number in <Number>, which causes Twilio to dial it
        dial = Twilio::TwiML::VoiceResponse::Dial.new(caller_id: ENV['TWILIO_PHONE_NUMBER'])
        dial.number(params['To'])
        r.append(dial)
      else
        r.say(message: 'Invalid phone number.')
      end
    end

    render xml: response.to_s
  end
end
