class Api::V1::Accounts::Twilio::TokensController < Api::V1::Accounts::BaseController
  def create
    # Generate a random identity for the agent if not already consistent
    identity = current_user.id.to_s

    # Create Voice grant for your Twilio capability
    grant = Twilio::JWT::AccessToken::VoiceGrant.new
    grant.outgoing_application_sid = ENV['TWILIO_TWIML_APP_SID']
    grant.incoming_allow = true # Allow incoming calls to this client

    # Create an Access Token
    token = Twilio::JWT::AccessToken.new(
      ENV['TWILIO_ACCOUNT_SID'],
      ENV['TWILIO_API_KEY_SID'],
      ENV['TWILIO_API_KEY_SECRET'],
      [grant],
      identity: identity
    )

    render json: { token: token.to_jwt, identity: identity }
  end
end
