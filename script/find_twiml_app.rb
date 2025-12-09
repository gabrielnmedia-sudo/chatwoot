# script/find_twiml_app.rb
begin
  client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  apps = client.applications.list(limit: 20)

  puts "\n--- Found TwiML Apps ---"
  if apps.empty?
    puts "No apps found."
  else
    apps.each do |app|
      puts "Name: #{app.friendly_name}"
      puts "SID:  #{app.sid}"
      puts "Voice URL: #{app.voice_url}"
      puts "------------------------"
    end
  end
rescue Twilio::REST::RestError => e
  puts "Error fetching apps: #{e.message}"
  puts "Check if TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN are set correctly in .env"
end
