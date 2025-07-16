class Query {
  String billsQuery = r'''
  query BillsData{
  
    payments {
        data {
            id
            amount
            payed_at
            invoice_id
            payment_method 
        }
    }
    supplies  {
      data {
        id
        full_address
        type
        code
        contract_id
      }
    }
    invoices {
      data {
        id
        description
        created_at
        code
        total_amount
        contract_id
        supply_id
        external_pdf_url
        expire_at
        status
        consumption
        date
    }
  }
  paymentSchedules {
    data {
        id
        amount
        date
        invoice_id
        title
    }
  }
}
''';

  String customersQuery = r'''
  query CustomersData{

    customers {
        data{
            id
            email
            first_name
            last_name
            phone
            tax_code
            code
        }
    }
}
''';

  String contractsQuery = r'''
  query ContractsData{
    contracts {
      data {
        id
        code
        typology
        start_date
        end_date
        invoice_full_address
      }
    }
}
''';

  String suppliesAndContractsQuery = r'''
  query SuppliesAndContracts{
  supplies {
    data {
        id
        full_address
        type
        code
        contract_id
    }
  }
  contracts {
      data {
        id
        code
        typology
        start_date
        end_date
        invoice_full_address
      }
    }
}
''';

  String suppliesQuery = r'''
  query Supplies{
  supplies {
    data {
        id
        full_address
        type
        code
        contract_id
    }
  }
}
''';


  String youtubeUrlsQuery = r'''
  query YoutubeUrl{
    youtubeUrls {
      url
      title
    }
  }
''';

  String zendeskQuery = r'''
  query ZendeskUrls{
  zendesk {
    ios
    android
  }
}
''';


  String loginQuery = r'''
  query Login($email: String!, $password: String!, $device_id: String) {
  
  login(email: $email, password: $password, device_id: $device_id) {
    user {
      id
      name
      email
    }
    token
  }
}
''';

  String logoutMutation = r'''
  mutation Logout {
    logout {
        status
    }
}

''';

  String selfReadingMutation = r'''
  mutation SelfReading($supply_id: String!, $value: String!, $readingDate: Date!) {
  
  selfReading(supply_id: $supply_id, value: $value, readingDate: $readingDate) {
     status
     reading_id
  }
}
''';

  String selfReadingsQuery = r'''
  query SelfReadings($supply_id: String!) {
  
  readings(supply_id: $supply_id) {
     data {
        id
        value
        read_at
        created_at
     }
  }
}
''';

  String createStripePaymentRequestQuery= r'''
  query CreateStripePaymentRequest($payment_schedule_id: String!) {
    createStripePaymentRequest(payment_schedule_id: $payment_schedule_id) {
        payment_request_id
        client_secret
        publishable_key
    }
}
''';

  String createPaypalPaymentRequestQuery= r'''
  query createPaypalPaymentRequest($payment_schedule_id: String!) {
    createPaypalPaymentRequest(payment_schedule_id:$payment_schedule_id) {
        approve_url
    }
}
''';

  String updateStripePaymentRequestMutation= r'''
  mutation UpdateStripePaymentRequest($payment_schedule_id: String!, $payment_request_id: String!, $status: String!) {
    updateStripePaymentRequest(payment_schedule_id: $payment_schedule_id, payment_request_id: $payment_request_id, status: $status) {
        payment_request_id
        payment_intent_id
        status
    }
}
''';

  String resetPasswordMutation= r'''
  mutation ResetPasswordLink($email: String!) {
    resetPassword(email:$email) {
        status
    }
}
''';
}
