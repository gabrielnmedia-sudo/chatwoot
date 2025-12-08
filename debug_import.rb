require 'csv'
require 'fileutils'

# Setup
account = Account.first
unless account
  puts "No account found. Creating one..."
  account = Account.create!(name: 'Test Account')
end

puts "Using Account: #{account.name} (#{account.id})"

# Create sample CSV
csv_content = <<~CSV
  name,email,phone_number,identifier,city,country
  Test User,testVal@example.com,+1234567890,test_id_1,New York,US
  Jane Doe,janeVal@example.com,+1987654321,jane_id_1,London,UK
CSV

file_path = Rails.root.join('tmp', 'debug_import.csv')
File.write(file_path, csv_content)

puts "Created sample CSV at #{file_path}"

# Create DataImport
data_import = DataImport.create!(
  account: account,
  data_type: 'contacts',
  status: :pending
)

puts "Created DataImport: #{data_import.id}"

data_import.import_file.attach(
  io: File.open(file_path),
  filename: 'debug_import.csv',
  content_type: 'text/csv'
)

puts "Attached file to DataImport"

# Run Job
puts "Running DataImportJob..."
begin
  DataImportJob.perform_now(data_import)
  data_import.reload
  puts "Job finished."
  puts "Status: #{data_import.status}"
  puts "Processed: #{data_import.processed_records}"
  puts "Total: #{data_import.total_records}"
  
  if data_import.status == 'failed'
    puts "Failed Records CSV:"
    if data_import.failed_records.attached?
      puts data_import.failed_records.download
    else
      puts "No failed records file attached."
    end
  elsif data_import.status == 'completed' && data_import.processed_records.to_i < data_import.total_records.to_i
     puts "Some records failed:"
     if data_import.failed_records.attached?
       puts data_import.failed_records.download
     end
  end

  # Check contacts
  contact1 = Contact.find_by(email: 'testval@example.com')
  if contact1
    puts "Found contact 1: #{contact1.name} - #{contact1.email}"
  else
    puts "Contact 1 NOT FOUND"
  end

rescue => e
  puts "Job Crashed: #{e.message}"
  puts e.backtrace
end
