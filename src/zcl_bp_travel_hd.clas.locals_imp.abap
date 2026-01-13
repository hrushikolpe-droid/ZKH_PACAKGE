CLASS lhc_ZI_TRAVEL_hd DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZI_TRAVEL_hd RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ZI_TRAVEL_hd RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZI_TRAVEL_hd RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE ZI_TRAVEL_hd.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION ZI_TRAVEL_hd~acceptTravel RESULT result.

    METHODS copyTravel FOR MODIFY
      IMPORTING keys FOR ACTION ZI_TRAVEL_hd~copyTravel.

    METHODS recalcTotPrice FOR MODIFY
      IMPORTING keys FOR ACTION ZI_TRAVEL_hd~recalcTotPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION ZI_TRAVEL_hd~rejectTravel RESULT result.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZI_TRAVEL_hd~validateCustomer.

    METHODS validateDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZI_TRAVEL_hd~validateDate.

ENDCLASS.

CLASS lhc_ZI_TRAVEL_hd IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
  DATA(lt_entities) = entities.
    DELETE lt_entities WHERE TravelId IS NOT INITIAL.

    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
*         ignore_buffer     =
            nr_range_nr       = '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines( lt_entities ) )
*         subobject         =
*         toyear            =
          IMPORTING
            number            = DATA(lv_latest_num)
            returncode        = DATA(lv_code)
            returned_quantity = DATA(lv_quantity)
        ).
      CATCH cx_nr_object_not_found.
      CATCH cx_number_ranges INTO DATA(lo_error).
        LOOP AT lt_entities INTO DATA(wa_entities).

          APPEND VALUE #( %cid = wa_entities-%cid
                          %key = wa_entities-%key )
           TO failed-zi_travel_hd.

        ENDLOOP.

        LOOP AT lt_entities INTO wa_entities.

          APPEND VALUE #( %cid = wa_entities-%cid
                          %key = wa_entities-%key
                          %msg = lo_error )
          TO reported-zi_travel_hd.

        ENDLOOP.
    ENDTRY.

    DATA(lv_curr_num)   =  lv_latest_num - lv_quantity.

    CHECK lv_quantity = lines( lt_entities ).

    LOOP AT lt_entities INTO wa_entities.
      lv_curr_num += 1.

*      ls_travel_entity-%cid = wa_entities-%cid.
*      ls_travel_entity-TravelId = lv_curr_num.
*
*      APPEND ls_travel_entity TO mapped-zi_travel_lekhansh.
*
      APPEND VALUE #( %cid = wa_entities-%cid
                      travelId = lv_curr_num )
      TO mapped-zi_travel_hd.

    ENDLOOP.
  ENDMETHOD.

  METHOD acceptTravel.

  MODIFY ENTITIES OF zi_travel_hd IN LOCAL MODE
    ENTITY zi_travel_hd
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky OverallStatus = 'A' ) )
    REPORTED DATA(it_reported).

    READ ENTITIES OF zi_travel_hd IN LOCAL MODE
    ENTITY zi_travel_hd
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(it_result).

    result = VALUE #( FOR ls_result IN it_result ( %tky = ls_result-%tky
                                                   %param = ls_result  ) ).

  ENDMETHOD.

  METHOD copyTravel.


   DATA : it_travel       TYPE TABLE FOR CREATE zi_travel_hd.
*           //it_booking_cba  TYPE TABLE FOR CREATE zi_travel_lekhansh\_booking,
*           //it_booksupp_cba TYPE TABLE FOR CREATE zi_booking_lekhansh\_bookingsuppl.


    READ TABLE keys ASSIGNING FIELD-SYMBOL(<fs_without_cid>) WITH KEY %cid = ' '.
    CHECK <fs_without_cid> IS NOT ASSIGNED.


    READ ENTITIES OF zi_travel_hd
    IN LOCAL MODE
    ENTITY zi_travel_hd
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(it_travel_r).

*    READ ENTITIES OF zi_travel_hd IN LOCAL MODE
*    ENTITY zi_travel_lekhansh BY \_booking
*    ALL FIELDS WITH CORRESPONDING #( it_travel_r )
*    RESULT DATA(it_booking_r).


*    READ ENTITIES OF zi_travel_lekhansh IN LOCAL MODE
*    ENTITY zi_travel_lekhansh BY \_booking
*    ALL FIELDS WITH CORRESPONDING #( it_booking_r )
*    RESULT DATA(it_booksupp_r).


    LOOP AT it_travel_r ASSIGNING FIELD-SYMBOL(<ls_travel_r>).

      APPEND INITIAL LINE TO it_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      <ls_travel>-%cid = keys[ KEY entity TravelId = <ls_travel_r>-TravelId ]-%cid.
      <ls_travel>-%data = CORRESPONDING #( <ls_travel_r> EXCEPT TravelId ).

      <ls_travel>-BeginDate = cl_abap_context_info=>get_system_date( ).
      <ls_travel>-EndDate = cl_abap_context_info=>get_system_date( ) + 30.
      <ls_travel>-OverallStatus = 'O'.


*      APPEND INITIAL LINE TO it_booking_cba ASSIGNING FIELD-SYMBOL(<ls_booking>).
*      <ls_booking>-%cid_ref = <ls_travel>-%cid.
*
**  filling the booking
*
*      LOOP AT it_booking_r ASSIGNING FIELD-SYMBOL(<ls_booking_r>)
*      USING KEY entity
*      WHERE  TravelId = <ls_travel_r>-TravelId.
*
*
*        APPEND INITIAL LINE TO <ls_booking>-%target ASSIGNING FIELD-SYMBOL(<ls_booking_n>).
*        <ls_booking_n>-%cid = <ls_travel>-%cid && <ls_booking_r>-BookingId.
*        <ls_booking_n>-%data = CORRESPONDING #( <ls_booking_r> EXCEPT TravelId ).
*        <ls_booking_n>-BookingStatus = 'N'.
*
*        APPEND INITIAL LINE TO it_booksupp_cba ASSIGNING FIELD-SYMBOL(<ls_booksupp>).
*        <ls_booksupp>-%cid_ref = <ls_booking_n>-%cid.
*
** filling booking suppliments
*
*        LOOP AT it_booksupp_cba ASSIGNING FIELD-SYMBOL(<ls_booksupp_r>)
*        USING KEY entity
*        WHERE TravelId =  <ls_travel>-TravelId AND
*        BookingId =  <ls_booking_r>-BookingId.
*
*          APPEND INITIAL LINE TO <ls_booking>-%target ASSIGNING FIELD-SYMBOL(<ls_booksupp_n>).
*          <ls_booksupp_n>-%cid = <ls_booking_n>-%cid && <ls_booksupp_r>-BookingId.
*          <ls_booksupp_n>-%data = CORRESPONDING #( <ls_booksupp_r> EXCEPT TravelId BookingId ).
*
*        ENDLOOP.
*      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zi_travel_hd IN LOCAL MODE
    ENTITY zi_travel_hd
    CREATE FIELDS
    ( AgencyId CustomerId BeginDate EndDate BookingFee TotalPrice CurrencyCode OverallStatus Description )
    WITH it_travel
*    ENTITY zi_travel_lekhansh
*    CREATE BY \_booking
*    FIELDS ( BookingId BookingDate CustomerId CarrierId ConnectionId FlightDate FlightPrice BookingStatus CurrencyCode  )
*    WITH it_booking_cba
*    ENTITY zi_booking_lekhansh
*    CREATE BY \_bookingsuppl
*    FIELDS ( BookingId BookingSupplementId CurrencyCode LastChangedAt Price SupplementId TravelId  )
*    WITH it_booksupp_cba
    MAPPED DATA(it_mapped).

    mapped-zi_travel_hd = it_mapped-zi_travel_hd.

  ENDMETHOD.

  METHOD recalcTotPrice.
  ENDMETHOD.

  METHOD rejectTravel.
  ENDMETHOD.

  METHOD validateCustomer.
  ENDMETHOD.

  METHOD validateDate.
  ENDMETHOD.

ENDCLASS.
