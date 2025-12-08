json.payload do
  json.array! @data_imports do |data_import|
    json.partial! 'api/v1/accounts/data_imports/data_import', data_import: data_import
  end
end

json.meta do
  json.count @data_imports.total_count
  json.current_page @data_imports.current_page
  json.total_pages @data_imports.total_pages
end
