class ApiConstants {
  static const String baseUrl = 'http://localhost/newversionami/newversionami/api';

  // Auth
  static const String login = '$baseUrl/login.php';

  // Interprètes
  static const String getInterpretes = '$baseUrl/get_interpretes.php';
  static const String addInterprete = '$baseUrl/add_interprete.php';
  static const String updateInterprete = '$baseUrl/update_interprete.php';
  static const String deleteInterprete = '$baseUrl/delete_interprete.php';

  // Missions (actives — llx_missionsplanet_mission)
  static const String getMissionsDataTable = '$baseUrl/get_missions_datatable.php';
  static const String getMissionsByInterpreter = '$baseUrl/get_missions_by_interpreter.php';
  static const String getTabMissions = '$baseUrl/get_tab_mission_par_interpreters.php';
  static const String addMission = '$baseUrl/add_mission_interpreter.php';
  static const String updateMission = '$baseUrl/update_mission_interpreter.php';
  static const String deleteMission = '$baseUrl/delete_mission_interpreter.php';

  // Clients
  static const String getClients = '$baseUrl/get_clients.php';
  static const String addClient = '$baseUrl/add_client.php';
  static const String updateClient = '$baseUrl/update_client.php';
  static const String deleteClient = '$baseUrl/delete_client.php';

  // Contacts
  static const String getContacts = '$baseUrl/get_contacts.php';
  static const String addContact = '$baseUrl/add_contact.php';
  static const String updateContact = '$baseUrl/update_contact.php';
  static const String deleteContact = '$baseUrl/delete_contact.php';

  // Facturation client
  static const String getClientInvoices = '$baseUrl/get_client_invoices.php';
  static const String getClientInvoiceLines = '$baseUrl/get_client_invoice_lines.php';
  static const String updateClientInvoiceLines = '$baseUrl/update_client_invoice_lines.php';
  static const String updateClientInvoiceStatus = '$baseUrl/update_client_invoice_status.php';
  static const String reserveInvoiceNumber = '$baseUrl/reserve_client_invoice_number.php';
  static const String logClientBilling = '$baseUrl/log_client_billing.php';

  // Brouillons
  static const String getInvoiceDrafts = '$baseUrl/get_invoice_drafts.php';
  static const String getInvoiceDraftLines = '$baseUrl/get_invoice_draft_lines.php';
  static const String saveInvoiceDraft = '$baseUrl/save_invoice_draft.php';
  static const String saveInvoiceDraftLines = '$baseUrl/save_invoice_draft_lines.php';
  static const String deleteInvoiceDraft = '$baseUrl/delete_invoice_draft.php';

  // Devis
  static const String getQuotes = '$baseUrl/get_quotes.php';
  static const String getQuote = '$baseUrl/get_quote.php';
  static const String createQuoteFromMission = '$baseUrl/create_quote_from_mission.php';
  static const String convertQuoteToInvoice = '$baseUrl/convert_quote_to_invoice.php';
  static const String updateQuote = '$baseUrl/update_quote.php';

  // Référentiels
  static const String getLanguages = '$baseUrl/get_languages.php';
  static const String getCountries = '$baseUrl/get_countries.php';
  static const String getDepartments = '$baseUrl/get_departments.php';
  static const String getCompanyInfo = '$baseUrl/get_company_info.php';
  static const String updateCompanyInfo = '$baseUrl/update_company_info.php';
  static const String getCompanyBankAccounts = '$baseUrl/get_company_bank_accounts.php';
  static const String getClientPaymentTerms = '$baseUrl/get_client_payment_terms.php';

  // Administration
  static const String getUsers = '$baseUrl/admin/get_users.php';
  static const String addUser = '$baseUrl/admin/add_user.php';
  static const String updateUser = '$baseUrl/admin/update_user.php';
  static const String deleteUser = '$baseUrl/admin/delete_user.php';
}
