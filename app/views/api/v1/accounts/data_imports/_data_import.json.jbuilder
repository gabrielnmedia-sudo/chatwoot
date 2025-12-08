json.id data_import.id
json.status data_import.status
json.total_records data_import.total_records
json.processed_records data_import.processed_records
json.created_at data_import.created_at
json.updated_at data_import.updated_at
json.file_url url_for(data_import.import_file) if data_import.import_file.attached?
