;; Decentralized Energy Trading Platform
;; Enables peer-to-peer energy trading between producers and consumers

;; Error codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-DUPLICATE-PRODUCER-REGISTRATION (err u101))
(define-constant ERR-DUPLICATE-CONSUMER-REGISTRATION (err u102))
(define-constant ERR-PRODUCER-NOT-FOUND (err u103))
(define-constant ERR-CONSUMER-NOT-FOUND (err u104))
(define-constant ERR-ENERGY-OFFER-NOT-FOUND (err u105))
(define-constant ERR-INSUFFICIENT-ENERGY-UNITS (err u106))
(define-constant ERR-INSUFFICIENT-BALANCE (err u107))
(define-constant ERR-INVALID-OFFER-PRICE (err u108))
(define-constant ERR-INVALID-ENERGY-AMOUNT (err u109))
(define-constant ERR-INVALID-EXPIRATION (err u110))
(define-constant ERR-OFFER-EXPIRED (err u111))
(define-constant ERR-SELF-TRADING (err u112))

;; Data variables
(define-data-var platform-admin principal tx-sender)
(define-data-var transaction-fee-percent uint u1) ;; 1% fee
(define-data-var platform-revenue uint u0)
(define-data-var energy-trade-volume uint u0)
(define-data-var registered-producer-count uint u0)
(define-data-var registered-consumer-count uint u0)

;; Data maps
(define-map energy-producers
    principal
    {
        energy-available: uint,
        energy-sold: uint,
        reputation-score: uint,
        earnings: uint,
        active-offers: uint,
        certification-level: uint
    }
)

(define-map energy-consumers
    principal
    {
        energy-purchased: uint,
        spending: uint,
        last-purchase-time: uint,
        consumer-tier: uint
    }
)

(define-map energy-offers
    {producer: principal, offer-id: uint}
    {
        energy-amount: uint,
        price-per-unit: uint,
        expiration-time: uint,
        is-active: bool,
        energy-type: (string-ascii 20),
        carbon-offset: uint
    }
)

(define-map trade-history
    {transaction-id: uint}
    {
        seller: principal,
        buyer: principal,
        energy-amount: uint,
        total-cost: uint,
        timestamp: uint,
        energy-type: (string-ascii 20)
    }
)

(define-data-var transaction-counter uint u0)

;; Public functions

;; Register as energy producer
(define-public (register-producer)
    (let
        ((producer-address tx-sender))
        (asserts! (is-none (map-get? energy-producers producer-address)) (err ERR-DUPLICATE-PRODUCER-REGISTRATION))
        (map-set energy-producers
            producer-address
            {
                energy-available: u0,
                energy-sold: u0,
                reputation-score: u50, ;; Starting at neutral reputation
                earnings: u0,
                active-offers: u0,
                certification-level: u1
            }
        )
        (var-set registered-producer-count (+ (var-get registered-producer-count) u1))
        (ok true)
    )
)

;; Register as energy consumer
(define-public (register-consumer)
    (let
        ((consumer-address tx-sender))
        (asserts! (is-none (map-get? energy-consumers consumer-address)) (err ERR-DUPLICATE-CONSUMER-REGISTRATION))
        (map-set energy-consumers
            consumer-address
            {
                energy-purchased: u0,
                spending: u0,
                last-purchase-time: (unwrap-panic (get-block-info? time u0)),
                consumer-tier: u1
            }
        )
        (var-set registered-consumer-count (+ (var-get registered-consumer-count) u1))
        (ok true)
    )
)

;; Add generated energy to producer's account
(define-public (add-generated-energy (energy-units uint))
    (let
        ((producer-address tx-sender)
         (producer-data (unwrap! (map-get? energy-producers producer-address) (err ERR-PRODUCER-NOT-FOUND))))
        
        (asserts! (> energy-units u0) (err ERR-INVALID-ENERGY-AMOUNT))
        
        (map-set energy-producers
            producer-address
            (merge producer-data {
                energy-available: (+ (get energy-available producer-data) energy-units)
            })
        )
        (ok energy-units)
    )
)

;; Create energy offer
(define-public (create-energy-offer 
                (energy-amount uint) 
                (price-per-unit uint) 
                (expiration-time uint)
                (energy-type (string-ascii 20))
                (carbon-offset uint))
    (let
        ((producer-address tx-sender)
         (producer-data (unwrap! (map-get? energy-producers producer-address) (err ERR-PRODUCER-NOT-FOUND))))
        
        (asserts! (>= (get energy-available producer-data) energy-amount) (err ERR-INSUFFICIENT-ENERGY-UNITS))
        (asserts! (> energy-amount u0) (err ERR-INVALID-ENERGY-AMOUNT))
        (asserts! (> price-per-unit u0) (err ERR-INVALID-OFFER-PRICE))
        (asserts! (> expiration-time (unwrap-panic (get-block-info? time u0))) (err ERR-INVALID-EXPIRATION))
        
        (let
            ((next-offer-id (+ (get active-offers producer-data) u1)))
            
            ;; Create the offer
            (map-set energy-offers
                {producer: producer-address, offer-id: next-offer-id}
                {
                    energy-amount: energy-amount,
                    price-per-unit: price-per-unit,
                    expiration-time: expiration-time,
                    is-active: true,
                    energy-type: energy-type,
                    carbon-offset: carbon-offset
                }
            )
            
            ;; Update producer's available energy and active offers
            (map-set energy-producers
                producer-address
                (merge producer-data {
                    energy-available: (- (get energy-available producer-data) energy-amount),
                    active-offers: next-offer-id
                })
            )
            
            (ok next-offer-id)
        )
    )
)

;; Cancel an active energy offer
(define-public (cancel-energy-offer (offer-id uint))
    (let
        ((producer-address tx-sender)
         (producer-data (unwrap! (map-get? energy-producers producer-address) (err ERR-PRODUCER-NOT-FOUND)))
         (offer-data (unwrap! (map-get? energy-offers {producer: producer-address, offer-id: offer-id}) (err ERR-ENERGY-OFFER-NOT-FOUND))))
        
        (asserts! (get is-active offer-data) (err ERR-ENERGY-OFFER-NOT-FOUND))
        
        ;; Return energy to available balance
        (map-set energy-producers
            producer-address
            (merge producer-data {
                energy-available: (+ (get energy-available producer-data) (get energy-amount offer-data))
            })
        )
        
        ;; Mark offer as inactive
        (map-set energy-offers
            {producer: producer-address, offer-id: offer-id}
            (merge offer-data {
                is-active: false
            })
        )
        
        (ok true)
    )
)

;; Private functions

;; Calculate new reputation score
(define-private (calculate-new-reputation (current-reputation uint) (positive-feedback uint))
    (let
        ((max-reputation u100))
        (if (>= (+ current-reputation positive-feedback) max-reputation)
            max-reputation
            (+ current-reputation positive-feedback)
        )
    )
)

;; Read-only functions

;; Get producer profile
(define-read-only (get-producer-profile (producer-address principal))
    (map-get? energy-producers producer-address)
)

;; Get consumer profile
(define-read-only (get-consumer-profile (consumer-address principal))
    (map-get? energy-consumers consumer-address)
)

;; Get offer details
(define-read-only (get-offer-details (producer-address principal) (offer-id uint))
    (map-get? energy-offers {producer: producer-address, offer-id: offer-id})
)

;; Get transaction details
(define-read-only (get-transaction-details (transaction-id uint))
    (map-get? trade-history {transaction-id: transaction-id})
)

;; Get platform metrics
(define-read-only (get-platform-metrics)
    {
        producer-count: (var-get registered-producer-count),
        consumer-count: (var-get registered-consumer-count),
        total-energy-traded: (var-get energy-trade-volume),
        platform-revenue: (var-get platform-revenue),
        transaction-fee-percent: (var-get transaction-fee-percent)
    }
)

;; Administrative functions

;; Update transaction fee (only administrator)
(define-public (update-transaction-fee (new-fee-percent uint))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-admin)) (err ERR-UNAUTHORIZED-ACCESS))
        (asserts! (<= new-fee-percent u10) (err ERR-INVALID-OFFER-PRICE)) ;; Max 10% fee
        (var-set transaction-fee-percent new-fee-percent)
        (ok true)
    )
)

;; Transfer platform administration
(define-public (transfer-admin-control (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-admin)) (err ERR-UNAUTHORIZED-ACCESS))
        (asserts! (not (is-eq new-admin (var-get platform-admin))) (err ERR-UNAUTHORIZED-ACCESS))
        (var-set platform-admin new-admin)
        (ok true)
    )
)