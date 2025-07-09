#!/bin/bash

export HOME=/tmp

# set -x

function booking () {
    local body=$(echo "$1" | jq -r .body)
    local reservationNumber=$(echo "$body" | jq -r  .reservationNumber)
    local email=$(echo "$body" | jq -r  .email)
    local data=$(GetBookingByReservationNumber "$reservationNumber" "$email" )
    # data=$(GetBookingInfoByReservationNumber "$reservationNumber")
    
    jq -n --argjson data "$data"  '{
        statusCode: 200,
        body: ($data | tostring),
        headers: {
            "Content-Type": "application/json"
        }
    }'
}

# Get Booking info from a parsed job JSON object
GetBookingInfo () {
    local info=${1}
    # mapfile -t  args < <(echo "$info"\
    #     | jq -r  '.pnr, .email')
    # GetBookingByReservationNumber  "${args[@]}" \
    # | jq
    pnr=$(echo "$info" | jq -r '.pnr')
    email=$(echo "$info" | jq -r '.email')
    GetBookingByReservationNumber "$pnr" "$email" | jq
}

# Given a PNR, fethes the Booking email from ddb and 
# retrive airline Booking info
GetBookingInfoByReservationNumber () {
    local reservationNumber=${1}
    local job
    job=$(GetJobByReservationNumber "$reservationNumber")
    if [[ $? -ne 0 ]]; then
        echo "Error: $job" >&2
        return 1
    fi
    GetBookingInfo "$job"
}


GetJobByReservationNumber() {
  local pnr="$1"
  local table="flygo-flygo-booking-ryanair"
  local region="eu-south-1"
  local profile="flygo"

  awscurl \
    --service dynamodb \
    --region "$region" \
    --profile "$profile" \
    -X POST \
    -H "Content-Type: application/x-amz-json-1.0" \
    -H "X-Amz-Target: DynamoDB_20120810.Query" \
    -d "{
      \"TableName\": \"$table\",
      \"IndexName\": \"StatusPNRIndex\",
      \"KeyConditionExpression\": \"#s = :s AND #p = :p\",
      \"ExpressionAttributeNames\": {
        \"#s\": \"status\",
        \"#p\": \"pnr\"
      },
      \"ExpressionAttributeValues\": {
        \":s\": {\"S\": \"success\"},
        \":p\": {\"S\": \"$pnr\"}
      },
      \"ProjectionExpression\": \"pnr, email, Id, createdAt, authToken\",
      \"Limit\": 1,
      \"ScanIndexForward\": false
    }" https://dynamodb."$region".amazonaws.com/ |
    jq -r '.Items[0] | {
      pnr: .pnr.S,
      id: .Id.S,
      email: .email.S,
      timestamp: .createdAt.S,
      sessionToken: .authToken.S
    }'
}

function GetBookingByReservationNumber () {
    local reservationNumber=${1}
    local email=${2}

    if [[ -z "$reservationNumber" ]]; then 
        echo "Reservation number is required" >&2
        return 1
    else
        shift
    fi

    if [[ -z "$email" ]]; then
        echo "Email is required" >&2
        return 1
    else
        shift
    fi

    http-cli \
        --method POST \
        --url 'https://www.ryanair.com/api/bookingfa/it-it/graphql' \
        --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36' \
        --data $'{"query":"query GetBookingByReservationNumber($bookingInfo: GetBookingByReservationNumberInputType\u0021) {\\n  getBookingByReservationNumber(bookingInfo: $bookingInfo) {\\n    addons {\\n      ...AddonFrag\\n    }\\n    carHire {\\n      ...CarHireFrag\\n    }\\n    contacts {\\n      ...ContactsFrag\\n    }\\n    extras {\\n      ...ExtrasOrFeesFrag\\n    }\\n    groundTransfer {\\n      ...GroundTransferFrag\\n    }\\n    hotels {\\n      ...HotelsFrag\\n    }\\n    info {\\n      ...InfoFrag\\n    }\\n    journeys {\\n      ...JourneysFrag\\n    }\\n    passengers {\\n      ...PassengersFrag\\n    }\\n    payments {\\n      ...PaymentInfoFrag\\n    }\\n    fees {\\n      ...ExtrasOrFeesFrag\\n    }\\n    serverTimeUTC\\n    sessionToken\\n    tripId\\n  }\\n}\\n\\n\\nfragment AddonFrag on AddOnResponseModelType {\\n  carParkName\\n  code\\n  currLater\\n  currNow\\n  dropOffLocation\\n  end\\n  isSingleOffer\\n  itemId\\n  loc\\n  name\\n  pax\\n  paxNum\\n  pickUpLocation\\n  provider\\n  providerCode\\n  qty\\n  refNo\\n  sold\\n  src\\n  start\\n  status\\n  total\\n  type\\n}\\n\\nfragment CarHireFrag on CarHireResponseModelType {\\n  carSupplierConfirmationId\\n  carType\\n  confirmationId\\n  currencyCode\\n  insurance\\n  pickupDateTime\\n  pickupLocation\\n  returnDateTime\\n  returnLocation\\n  serviceProvider\\n  sold\\n  status\\n  totalPrice\\n}\\n\\nfragment PassengerNameFrag on PassengerNameResponseModelType {\\n  first\\n  last\\n  middle\\n  suffix\\n  title\\n}\\n\\nfragment ContactsFrag on ContactResponseModelType {\\n  address\\n  city\\n  country\\n  cultureCode\\n  email\\n  fax\\n  homePhone\\n  name {\\n    ...PassengerNameFrag\\n  }\\n  otherPhone\\n  postalCode\\n  provinceState\\n  type\\n  workPhone\\n}\\n\\nfragment ExtrasOrFeesFrag on BookingExtraResponseModelType {\\n  amt\\n  code\\n  includedSsrs\\n  isPartOfBundle\\n  isSeatChange\\n  journeyNum\\n  percentageDiscount\\n  qty\\n  segmentNum\\n  sold\\n  total\\n  totalDiscount\\n  totalWithoutDiscount\\n  type\\n  vat\\n}\\n\\nfragment GroundTransferFrag on GroundTransferResponseModelType {\\n  confirmationId\\n  currencyCode\\n  dropoffDateTime\\n  dropoffLocation\\n  flightBookingId\\n  isSold\\n  pickupDateTime\\n  pickupLocation\\n  pnr\\n  status\\n  totalPrice\\n}\\n\\nfragment HotelsFrag on HotelsResponseModelType {\\n  status\\n}\\n\\nfragment InfoFrag on BookingInfoResponseModelType {\\n  allSeatsAutoAllocated\\n  balanceDue\\n  bookingAgent\\n  bookingId\\n  createdUtcDate\\n  curr\\n  currPrecision\\n  domestic\\n  holdDateTime\\n  isConnectingFlight\\n  isBuyOneGetOneDiscounted\\n  isHoldable\\n  isPrime\\n  modifiedUtcDate\\n  pnr\\n  status\\n  locationCode\\n  locationCodeGroup\\n  sourceOrganization\\n  companyName\\n}\\n\\nfragment JourneyChangeFrag on JourneyChangeInfoResponseModelType {\\n  freeMove\\n  isChangeable\\n  isChanged\\n  reasonCode\\n}\\n\\nfragment FaresFrag on BookingFareResponseModelType {\\n  amt\\n  code\\n  disc\\n  fareKey\\n  fat\\n  includedSsrs\\n  percentageDiscount\\n  qty\\n  sold\\n  total\\n  totalDiscount\\n  totalWithoutDiscount\\n  type\\n  vat\\n}\\n\\nfragment FatsFrag on BookingFatResponseModelType {\\n  amount\\n  code\\n  total\\n  vat\\n  description\\n  qty\\n}\\n\\nfragment SeatRowDeltaFrag on PaxSeatRowDeltaResponseModelType {\\n  rowDistance\\n  segmentNum\\n}\\n\\nfragment SegmentsFrag on SegmentModelResponseModelType {\\n  aircraft\\n  arrive\\n  arriveUTC\\n  depart\\n  departUTC\\n  dest\\n  duration\\n  flown\\n  flt\\n  isCancelled\\n  isDomestic\\n  orig\\n  segmentNum\\n  vatRate\\n}\\n\\nfragment ZoneDiscountFrag on BookingZoneDiscountResponseModelType {\\n  code\\n  pct\\n  total\\n  zone\\n}\\n\\nfragment JourneysFrag on BookingJourneyResponseModelType {\\n  arrive\\n  arriveUTC\\n  changeInfo {\\n    ...JourneyChangeFrag\\n  }\\n  checkInCloseUtcDate\\n  checkInFreeAllocateOpenUtcDate\\n  checkInOpenUtcDate\\n  depart\\n  departUTC\\n  dest\\n  destCountry\\n  duration\\n  fareClass\\n  fareOption\\n  fares {\\n    ...FaresFrag\\n  }\\n  fareType\\n  fats {\\n    ...FatsFrag\\n  }\\n  flt\\n  infSsrs {\\n    ...ExtrasOrFeesFrag\\n  }\\n  isRescheduledJourneyWithFreeMove\\n  setaSsrs {\\n    ...ExtrasOrFeesFrag\\n  }\\n  journeyNum\\n  maxPaxSeatRowDistance {\\n    ...SeatRowDeltaFrag\\n  }\\n  mobilebp\\n  orig\\n  origCountry\\n  seatsLeft\\n  segments {\\n    ...SegmentsFrag\\n  }\\n  zoneDiscount {\\n    ...ZoneDiscountFrag\\n  }\\n}\\n\\nfragment ResidentInfoFrag on PassengerResidentInfoResponseModelType {\\n  community\\n  dateOfBirth\\n  dob\\n  docNum\\n  docType\\n  hasLargeFamilyDiscount\\n  hasResidentDiscount\\n  largeFamilyCert\\n  municipality\\n  saraValidationCode\\n}\\n\\nfragment SegmentCheckinFrag on PassengerSegmentCheckinResponseModelType {\\n  journeyNum\\n  segmentNum\\n  status\\n}\\n\\nfragment TravelDocumentFrag on TravelDocumentResponseModelType {\\n  countryOfIssue\\n  dateOfBirth\\n  dOB\\n  docNumber\\n  docType\\n  expiryDate\\n  nationality\\n  specialVisaDetails {\\n    countryOfIssue\\n    docNumber\\n    docType\\n  }\\n}\\n\\nfragment PassengerWithInfantTravelDocumentsFrag on PassengerWithInfantTravelDocumentResponseModelType {\\n  num\\n  travelDocument {\\n    ...TravelDocumentFrag\\n  }\\n  infantTravelDocument {\\n    ...TravelDocumentFrag\\n  }\\n}\\n\\nfragment PassengersFrag on PassengerResponseModelType {\\n  dateOfBirth\\n  doB\\n  ins\\n  inf {\\n    dateOfBirth\\n    dob\\n    first\\n    last\\n    middle\\n    suffix\\n    title\\n  }\\n  name {\\n    ...PassengerNameFrag\\n  }\\n  nationality\\n  paxFees {\\n    ...ExtrasOrFeesFrag\\n  }\\n  paxNum\\n  residentInfo {\\n    ...ResidentInfoFrag\\n  }\\n  segCheckin {\\n    ...SegmentCheckinFrag\\n  }\\n  segFees {\\n    ...ExtrasOrFeesFrag\\n  }\\n  segPrm {\\n    ...ExtrasOrFeesFrag\\n  }\\n  segSeats {\\n    ...ExtrasOrFeesFrag\\n  }\\n  segSsrs {\\n    ...ExtrasOrFeesFrag\\n  }\\n  travelDocuments {\\n    ...PassengerWithInfantTravelDocumentsFrag\\n  }\\n  type\\n}\\n\\nfragment PaymentInfoFrag on PaymentInfoResponseModelType {\\n  accName\\n  accNum\\n  amt\\n  code\\n  currency\\n  dccAmt\\n  dccApplicable\\n  dccCurrency\\n  dccRate\\n  discount\\n  isReward\\n  status\\n  type\\n  createdDate\\n  invoiceNumber\\n}\\n\\n","variables":{"bookingInfo":{"reservationNumber":"'"$reservationNumber"'","emailAddress":"'"$email"'"}}}' \
        $@
}