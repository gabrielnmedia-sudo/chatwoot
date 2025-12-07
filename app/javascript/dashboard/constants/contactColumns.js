export const CONTACT_COLUMNS = [
  { key: 'name', label: 'Name', sortable: true },
  { key: 'email', label: 'Email', sortable: true },
  { key: 'phone_number', label: 'Phone Number', sortable: true },
  { key: 'company_name', label: 'Company', sortable: true },
  { key: 'city', label: 'City', sortable: true },
  { key: 'country', label: 'Country', sortable: true },
  { key: 'tags', label: 'Tags', sortable: false },
  { key: 'last_activity_at', label: 'Last Activity', sortable: true },
];

export const DEFAULT_VISIBLE_COLUMNS = [
  'name',
  'email',
  'phone_number',
  'company_name',
  'tags',
  'last_activity_at',
];
