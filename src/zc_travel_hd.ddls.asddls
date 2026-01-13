@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity zc_travel_hd   provider contract transactional_query
  as projection on zi_travel_hd
{
   key TravelId,
      @ObjectModel.text.element: [ 'agencyName' ]
      AgencyId,
      _agency.Name       as agencyName,
      @ObjectModel.text.element: [ 'customerName' ]
      CustomerId,
      _customer.LastName as customerName,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      @ObjectModel.text.element: [ 'OverallStatusText' ]
      OverallStatus,
      _status._Text.Text as OverallStatusText : localized,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      /* Associations */
      _agency,
      
      _currency,
      _customer,
      _status

}
