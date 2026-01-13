@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection view'
@Search.searchable: true
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity Z_C_TRAVEL_KH  provider contract transactional_query
  as projection on Z_R_TRAVEL_KH
{
  key TravelUUID,
      TravelID,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Search.ranking: #HIGH
      @ObjectModel.text.element: [ 'AgencyName' ]
      AgencyID,
      _Agency.Name              as AgencyName,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Search.ranking: #HIGH
      @ObjectModel.text.element: [ 'CustomerName' ]
      CustomerID,
      _Customer.last_name       as CustomerName,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      //@Semantics.amount.currencyCode: 'CurrencyCode'
      //virtual PriceWithVAT : /dmo/total_price,
      CurrencyCode,
      Description,
      @ObjectModel.text.element: [ 'OverallStatusText' ]
      OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized,
      //_OverallStatus._Text[1:Language = $session.system_language].Text as OverallStatusText,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      /* Associations */
      _Agency,
      _Currency,
      _Customer,
      _OverallStatus
}
