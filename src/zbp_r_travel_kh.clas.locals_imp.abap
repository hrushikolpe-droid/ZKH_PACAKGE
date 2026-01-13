CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS: BEGIN OF travel_status,
                 open     TYPE c LENGTH 1 VALUE 'O' , "Open
                 accepted TYPE c LENGTH 1 VALUE 'A' , "Accepted
                 rejected TYPE c LENGTH 1 VALUE 'X' , "Rejected
               END OF travel_status .
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS DeductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~DeductDiscount RESULT result.

    METHODS reCaclTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~reCaclTotalPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.

    METHODS setStatusToOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setStatusToOpen.

    METHODS setTravelNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~setTravelNumber.

    METHODS validateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateAgency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDateRange FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDateRange.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
          ENTITY Travel
          FIELDS ( OverallStatus )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels)
          FAILED failed.

    result = VALUE #(  FOR travel IN travels ( %tky = travel-%tky
                                               %field-BookingFee = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                           THEN if_abap_behv=>fc-f-read_only
                                                                           ELSE if_abap_behv=>fc-f-unrestricted  )
                                               %action-acceptTravel = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                           ELSE if_abap_behv=>fc-o-enabled  )
                                               %action-rejectTravel = COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                           ELSE if_abap_behv=>fc-o-enabled  )
                                               %action-DeductDiscount = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                           ELSE if_abap_behv=>fc-o-enabled  )

  ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.


    DATA: update_requested TYPE abap_bool,
          update_granted   TYPE abap_bool,
          delete_requested TYPE abap_bool,
          delete_granted   TYPE abap_bool.


    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
         ENTITY Travel
         FIELDS ( BookingFee )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         FAILED failed.

    update_requested = COND #( WHEN requested_authorizations-%update EQ if_abap_behv=>mk-on
                                 OR requested_authorizations-%action-Edit EQ if_abap_behv=>mk-on
                                 THEN abap_true
                                 ELSE abap_false ).

    delete_requested = COND #( WHEN requested_authorizations-%delete EQ if_abap_behv=>mk-on
                                THEN abap_true
                                ELSE abap_false ).

    " CHECK update_requested EQ abap_true.

    DATA(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    LOOP AT travels INTO DATA(travel)
         WHERE AgencyID EQ '000001'.

      IF lv_technical_name  EQ 'CB9980000286' AND travel-AgencyID NE '000001'.
        update_granted = abap_true.
        delete_granted = abap_true.
      ELSE.
        update_granted = abap_false.
        delete_granted = abap_false.
        APPEND VALUE #( %tky        = travel-%tky
                        %msg        = NEW /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                                   agency_id = travel-AgencyID
                                                                   severity  =  if_abap_behv_message=>severity-error )
                        %element-AgencyID =  if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      APPEND VALUE #( LET upd_auth = COND #( WHEN update_granted EQ abap_true
                                             THEN if_abap_behv=>auth-allowed
                                             ELSE if_abap_behv=>auth-unauthorized )
                      del_auth = COND #( WHEN delete_granted EQ abap_true
                                             THEN if_abap_behv=>auth-allowed
                                             ELSE if_abap_behv=>auth-unauthorized )
                      IN
                      %tky         = travel-%tky
                      %update      = upd_auth
                      %action-Edit = upd_auth
                      %delete      = del_auth ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_global_authorizations.

    DATA(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    IF requested_authorizations-%create EQ if_abap_behv=>mk-on.

      IF lv_technical_name  EQ 'CB9980000286'.
        result-%create          = if_abap_behv=>auth-allowed.
      ELSE.
        result-%create          = if_abap_behv=>auth-unauthorized.
        APPEND VALUE #( %msg    = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                          severity =  if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDIF.

    IF requested_authorizations-%update EQ if_abap_behv=>mk-on OR
       requested_authorizations-%action-Edit EQ if_abap_behv=>mk-on.

      IF lv_technical_name  EQ 'CB9980000286'.
        result-%update          = if_abap_behv=>auth-allowed .
        result-%action-edit     = if_abap_behv=>auth-allowed.
      ELSE.
        result-%update          = if_abap_behv=>auth-unauthorized.
        result-%action-edit     = if_abap_behv=>auth-unauthorized.
        APPEND VALUE #( %msg    = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                           severity =  if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.


    ENDIF.

    IF requested_authorizations-%delete EQ if_abap_behv=>mk-on.

      IF lv_technical_name  EQ 'CB9980000286'.
        result-%delete          = if_abap_behv=>auth-allowed.
      ELSE.
        result-%delete          = if_abap_behv=>auth-unauthorized.
        APPEND VALUE #( %msg    = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                           severity =  if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDIF.


  ENDMETHOD.

  METHOD acceptTravel.
* EML - Entity Manipulation Language

    MODIFY ENTITIES OF z_r_travel_kh IN LOCAL MODE
         ENTITY Travel
         UPDATE
         FIELDS ( OverallStatus )
         WITH VALUE #( FOR ls_key IN keys ( %tky          = ls_key-%tky
                                            OverallStatus = travel_status-accepted ) ).

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
         ENTITY Travel
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky ) ).

  ENDMETHOD.

  METHOD DeductDiscount.

*    DATA travels_for_update TYPE TABLE FOR UPDATE z_r_travel_kh.
*
*    DATA(keys_valid_discount) = keys.
*
*    LOOP AT keys_valid_discount ASSIGNING FIELD-SYMBOL(<key_valid_discount>).
*
*      IF <key_valid_discount>-%param-discount_percent IS INITIAL
*      OR <key_valid_discount>-%param-discount_percent > 100
*      OR <key_valid_discount>-%param-discount_percent <= 0.
*
*        APPEND VALUE #( %tky  =  <key_valid_discount>-%tky ) TO failed-travel.
*        APPEND VALUE #( %tky  = <key_valid_discount>-%tky
*                        %msg  = NEW /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>discount_invalid
*                                                            severity  =  if_abap_behv_message=>severity-error )
*                        %op-%action-deductDiscount =  if_abap_behv=>mk-on ) TO reported-travel.
*
*        DATA(lv_error) = abap_true.
*      ENDIF.
*    ENDLOOP.
*
*    CHECK lv_error NE  abap_true.
*
*    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
*         ENTITY Travel
*         FIELDS ( BookingFee )
*         WITH CORRESPONDING #( keys )
*         RESULT DATA(travels).
*
*    DATA percentage TYPE decfloat16.
*
*    LOOP AT travels INTO DATA(ls_travel).
*
*      DATA(discount_percentage) = keys[ KEY id %tky = ls_travel-%tky ]-%param-discount_percent .
*      percentage = discount_percentage / 100.
*      DATA(reduced_fee) = ls_travel-BookingFee * ( 1 - percentage ).
*
*      APPEND VALUE #( %tky = ls_travel-%tky
*                      BookingFee = reduced_fee   ) TO travels_for_update.
*    ENDLOOP.
*
*
*    MODIFY ENTITIES OF z_r_travel_kh IN LOCAL MODE
*       ENTITY Travel
*       UPDATE
*       FIELDS ( BookingFee )
*       WITH travels_for_update.
*
*    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
*            ENTITY Travel
*            FIELDS ( BookingFee )
*            WITH CORRESPONDING #( keys )
*            RESULT DATA(travels_with_discount).
*
*    result = VALUE #( FOR travel IN travels_with_discount ( %tky = travel-%tky
*                                                            %param = travel ) ).

  ENDMETHOD.

  METHOD reCaclTotalPrice.

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
           ENTITY Travel
           FIELDS ( BookingFee CurrencyCode )
           WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    DELETE travels WHERE CurrencyCode IS INITIAL.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      CLEAR <travel>-TotalPrice.

      SELECT SINGLE FROM /dmo/booking
        FIELDS flight_price
        WHERE currency_code EQ @<travel>-CurrencyCode
        INTO @DATA(lv_flight_price).

      IF sy-subrc EQ 0.
        <travel>-TotalPrice += lv_flight_price.
      ENDIF.

      <travel>-TotalPrice += <travel>-BookingFee.

    ENDLOOP.

    MODIFY ENTITIES OF z_r_travel_kh IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TotalPrice )
    WITH CORRESPONDING #(  travels ).



  ENDMETHOD.

  METHOD rejectTravel.

* EML - Entity Manipulation Language

    MODIFY ENTITIES OF z_r_travel_kh IN LOCAL MODE
         ENTITY Travel
         UPDATE
         FIELDS ( OverallStatus )
         WITH VALUE #( FOR ls_key IN keys ( %tky          = ls_key-%tky
                                            OverallStatus = travel_status-rejected ) ).

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
         ENTITY Travel
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky ) ).

  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF z_r_travel_kh IN LOCAL MODE
        ENTITY Travel
        EXECUTE reCaclTotalPrice
       FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD setStatusToOpen.

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
           ENTITY Travel
           FIELDS ( OverallStatus )
           WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    DELETE travels WHERE OverallStatus IS NOT INITIAL.

    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF z_r_travel_kh IN LOCAL MODE
   ENTITY Travel
   UPDATE FIELDS ( OverallStatus )
   WITH VALUE #(  FOR travel IN travels  INDEX INTO i
                      ( %tky        = travel-%tky
                      OverallStatus = travel_status-open ) ).

  ENDMETHOD.

  METHOD setTravelNumber.

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
          ENTITY Travel
          FIELDS ( TravelID )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels).

    DELETE travels WHERE TravelID IS NOT INITIAL.

    CHECK travels IS NOT INITIAL.

    SELECT SINGLE FROM ztravel_kh
    FIELDS MAX( travel_id )
    INTO @DATA(lv_max_travel_id).

    MODIFY ENTITIES OF z_r_travel_kh IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TravelID )
    WITH VALUE #(  FOR travel IN travels  INDEX INTO i
                       ( %tky   = travel-%tky
                       TravelID = lv_max_travel_id + 1 ) ).


  ENDMETHOD.

  METHOD validateAgency.

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
             ENTITY Travel
             FIELDS ( AgencyID )
             WITH CORRESPONDING #( keys )
             RESULT DATA(travels).

    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY client agency_id .

    agencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.

    IF agencies IS NOT INITIAL.
      SELECT FROM /dmo/agency AS ddbb
      INNER JOIN @agencies AS http_req ON ddbb~agency_id EQ http_req~agency_id
      FIELDS ddbb~agency_id
      INTO TABLE @DATA(valid_agencies).

    ENDIF.

    LOOP AT travels INTO DATA(travel).

      IF travel-AgencyID IS INITIAL.
        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_AGENCY'
                        %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                           severity =  if_abap_behv_message=>severity-error )
                        %element-AgencyID =  if_abap_behv=>mk-on
                        ) TO reported-travel.
      ELSEIF travel-AgencyID IS NOT INITIAL AND NOT line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).
        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_AGENCY'
                        %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>agency_unkown
                                                           severity =  if_abap_behv_message=>severity-error )
                        %element-AgencyID =  if_abap_behv=>mk-on
                        ) TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
             ENTITY Travel
             FIELDS ( CustomerID )
             WITH CORRESPONDING #( keys )
             RESULT DATA(travels).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY client customer_id.

    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.
      SELECT FROM /dmo/customer AS ddbb
      INNER JOIN @customers AS http_req ON ddbb~customer_id EQ http_req~customer_id
      FIELDS ddbb~customer_id
      INTO TABLE @DATA(valid_customers).

    ENDIF.

    LOOP AT travels INTO DATA(travel).

      IF travel-CustomerID IS INITIAL.
        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                                   severity =  if_abap_behv_message=>severity-error )
                      %element-CustomerID =  if_abap_behv=>mk-on
                      ) TO reported-travel.
      ELSEIF travel-CustomerID IS NOT INITIAL AND NOT line_exists( valid_customers[ customer_id = travel-CustomerID ] ).
        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>customer_unkown
                                                                   severity =  if_abap_behv_message=>severity-error )
                        %element-CustomerID =  if_abap_behv=>mk-on
                       ) TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateDateRange.

    READ ENTITIES OF z_r_travel_kh IN LOCAL MODE
             ENTITY Travel
             FIELDS ( BeginDate
                      EndDate )
             WITH CORRESPONDING #( keys )
             RESULT DATA(travels).
*
*    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY client customer_id.
*
*    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).
*    DELETE customers WHERE customer_id IS INITIAL.
*
*    IF customers IS NOT INITIAL.
*      SELECT FROM /dmo/customer AS ddbb
*      INNER JOIN @customers AS http_req ON ddbb~customer_id EQ http_req~customer_id
*      FIELDS ddbb~customer_id
*      INTO TABLE @DATA(valid_customers).
*
*    ENDIF.

    LOOP AT travels INTO DATA(travel).

      IF travel-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                   severity =  if_abap_behv_message=>severity-error )
                        %element-BeginDate =  if_abap_behv=>mk-on
                        ) TO reported-travel.

      ENDIF.

      IF travel-EndDate IS INITIAL.
        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_end_date
                                                                   severity =  if_abap_behv_message=>severity-error )
                        %element-EndDate =  if_abap_behv=>mk-on
                        ) TO reported-travel.

      ENDIF.

      IF travel-EndDate < travel-BeginDate AND travel-BeginDate IS NOT  INITIAL
                                           AND travel-EndDate IS NOT  INITIAL.
        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg        = NEW /dmo/cm_flight_messages( textid     = /dmo/cm_flight_messages=>enter_begin_date
                                                                   begin_date = travel-BeginDate
                                                                   end_date   = travel-EndDate
                                                                   severity   =  if_abap_behv_message=>severity-error )
                        %element-BeginDate =  if_abap_behv=>mk-on
                        %element-EndDate =  if_abap_behv=>mk-on
                        ) TO reported-travel.

      ENDIF.

      IF travel-BeginDate < cl_abap_context_info=>get_system_date(  ) AND travel-BeginDate IS NOT  INITIAL.
        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg        = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                   severity =  if_abap_behv_message=>severity-error )
                        %element-BeginDate =  if_abap_behv=>mk-on
                         ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
