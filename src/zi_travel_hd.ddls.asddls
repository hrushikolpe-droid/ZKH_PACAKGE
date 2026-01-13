@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'oot view for travel'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zi_travel_hd as select from ztravel_hd
association [0..1] to /DMO/I_Agency            as _agency   on $projection.AgencyId = _agency.AgencyID
  association [0..1] to /DMO/I_Customer          as _customer on $projection.CustomerId = _customer.CustomerID
  association [0..1] to I_Currency               as _currency on $projection.CurrencyCode = _currency.Currency
  association [1..1] to /DMO/I_Overall_Status_VH as _status   on $projection.OverallStatus = _status.OverallStatus
{
  key travel_id       as TravelId,
      agency_id       as AgencyId,
      customer_id     as CustomerId,
      begin_date      as BeginDate,
      end_date        as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee     as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price     as TotalPrice,
      currency_code   as CurrencyCode,
      description     as Description,
      overall_status  as OverallStatus,
      @Semantics.user.createdBy: true
      created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at as LastChangedAt,
   
      _agency,
      _customer,
      _currency,
      _status

}
