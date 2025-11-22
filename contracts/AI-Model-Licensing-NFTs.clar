
(define-non-fungible-token ai-model-license uint)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_PRICE (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u104))
(define-constant ERR_LICENSE_EXPIRED (err u105))
(define-constant ERR_INVALID_USAGE_TYPE (err u106))
(define-constant ERR_ROYALTY_TOO_HIGH (err u107))
(define-constant ERR_INVALID_QUANTITY (err u108))
(define-constant ERR_MAX_BULK_EXCEEDED (err u109))
(define-constant ERR_ALREADY_LISTED (err u110))
(define-constant ERR_NOT_LISTED (err u111))
(define-constant ERR_CANNOT_BUY_OWN_LISTING (err u112))

(define-data-var next-token-id uint u1)
(define-data-var platform-fee uint u250)
(define-data-var max-bulk-quantity uint u100)

(define-map model-metadata uint {
  name: (string-ascii 64),
  description: (string-ascii 256),
  model-hash: (string-ascii 64),
  creator: principal,
  royalty-percentage: uint,
  base-price: uint,
  usage-types: uint
})

(define-map license-terms uint {
  inference-only: bool,
  retraining-allowed: bool,
  commercial-use: bool,
  duration-blocks: uint,
  max-inferences: uint
})

(define-map active-licenses {
  token-id: uint,
  licensee: principal
} {
  start-block: uint,
  end-block: uint,
  usage-count: uint,
  rental-price: uint
})

(define-map royalty-balances principal uint)

(define-map bulk-discount-tiers uint {
  min-quantity: uint,
  discount-percentage: uint
})

(define-map marketplace-listings {
  token-id: uint,
  seller: principal
} {
  asking-price: uint,
  listed-at-block: uint
})

(define-public (mint-ai-model
  (name (string-ascii 64))
  (description (string-ascii 256))
  (model-hash (string-ascii 64))
  (royalty-percentage uint)
  (base-price uint)
  (usage-types uint)
  (inference-only bool)
  (retraining-allowed bool)
  (commercial-use bool)
  (duration-blocks uint)
  (max-inferences uint)
)
  (let (
    (token-id (var-get next-token-id))
    (recipient tx-sender)
  )
    (asserts! (<= royalty-percentage u1000) ERR_ROYALTY_TOO_HIGH)
    (asserts! (> base-price u0) ERR_INVALID_PRICE)
    (try! (nft-mint? ai-model-license token-id recipient))
    (map-set model-metadata token-id {
      name: name,
      description: description,
      model-hash: model-hash,
      creator: recipient,
      royalty-percentage: royalty-percentage,
      base-price: base-price,
      usage-types: usage-types
    })
    (map-set license-terms token-id {
      inference-only: inference-only,
      retraining-allowed: retraining-allowed,
      commercial-use: commercial-use,
      duration-blocks: duration-blocks,
      max-inferences: max-inferences
    })
    (var-set next-token-id (+ token-id u1))
    (ok token-id)
  )
)

(define-public (transfer-model (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_NOT_AUTHORIZED)
    (try! (nft-transfer? ai-model-license token-id sender recipient))
    (ok true)
  )
)

(define-public (rent-license
  (token-id uint)
  (rental-duration uint)
)
  (let (
    (model-data (unwrap! (map-get? model-metadata token-id) ERR_NOT_FOUND))
    (license-data (unwrap! (map-get? license-terms token-id) ERR_NOT_FOUND))
    (rental-price (* (get base-price model-data) rental-duration))
    (creator (get creator model-data))
    (royalty-amount (/ (* rental-price (get royalty-percentage model-data)) u10000))
    (platform-fee-amount (/ (* rental-price (var-get platform-fee)) u10000))
    (creator-amount (- rental-price (+ royalty-amount platform-fee-amount)))
    (current-block stacks-block-height)
    (end-block (+ current-block (get duration-blocks license-data)))
  )
    (asserts! (> rental-price u0) ERR_INVALID_PRICE)
    (try! (stx-transfer? rental-price tx-sender creator))
    (try! (stx-transfer? platform-fee-amount creator CONTRACT_OWNER))
    (map-set active-licenses
      { token-id: token-id, licensee: tx-sender }
      {
        start-block: current-block,
        end-block: end-block,
        usage-count: u0,
        rental-price: rental-price
      }
    )
    (map-set royalty-balances creator 
      (+ (default-to u0 (map-get? royalty-balances creator)) royalty-amount)
    )
    (ok true)
  )
)

(define-public (use-model (token-id uint))
  (let (
    (license-key { token-id: token-id, licensee: tx-sender })
    (license (unwrap! (map-get? active-licenses license-key) ERR_NOT_FOUND))
    (license-terms-data (unwrap! (map-get? license-terms token-id) ERR_NOT_FOUND))
    (current-block stacks-block-height)
    (new-usage-count (+ (get usage-count license) u1))
  )
    (asserts! (<= current-block (get end-block license)) ERR_LICENSE_EXPIRED)
    (asserts! (<= new-usage-count (get max-inferences license-terms-data)) ERR_INVALID_USAGE_TYPE)
    (map-set active-licenses license-key
      (merge license { usage-count: new-usage-count })
    )
    (ok new-usage-count)
  )
)

(define-public (extend-license (token-id uint) (additional-blocks uint))
  (let (
    (license-key { token-id: token-id, licensee: tx-sender })
    (license (unwrap! (map-get? active-licenses license-key) ERR_NOT_FOUND))
    (model-data (unwrap! (map-get? model-metadata token-id) ERR_NOT_FOUND))
    (extension-price (* (get base-price model-data) additional-blocks))
    (creator (get creator model-data))
    (new-end-block (+ (get end-block license) additional-blocks))
  )
    (try! (stx-transfer? extension-price tx-sender creator))
    (map-set active-licenses license-key
      (merge license { end-block: new-end-block })
    )
    (ok new-end-block)
  )
)

(define-public (withdraw-royalties)
  (let (
    (balance (default-to u0 (map-get? royalty-balances tx-sender)))
  )
    (asserts! (> balance u0) ERR_INSUFFICIENT_FUNDS)
    (try! (stx-transfer? balance (as-contract tx-sender) tx-sender))
    (map-delete royalty-balances tx-sender)
    (ok balance)
  )
)

(define-public (update-base-price (token-id uint) (new-price uint))
  (let (
    (model-data (unwrap! (map-get? model-metadata token-id) ERR_NOT_FOUND))
    (owner (unwrap! (nft-get-owner? ai-model-license token-id) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender owner) ERR_NOT_AUTHORIZED)
    (asserts! (> new-price u0) ERR_INVALID_PRICE)
    (map-set model-metadata token-id
      (merge model-data { base-price: new-price })
    )
    (ok true)
  )
)

(define-read-only (get-model-info (token-id uint))
  (map-get? model-metadata token-id)
)

(define-read-only (get-license-terms (token-id uint))
  (map-get? license-terms token-id)
)

(define-read-only (get-active-license (token-id uint) (licensee principal))
  (map-get? active-licenses { token-id: token-id, licensee: licensee })
)

(define-read-only (get-owner (token-id uint))
  (nft-get-owner? ai-model-license token-id)
)

(define-read-only (get-next-token-id)
  (var-get next-token-id)
)

(define-read-only (get-royalty-balance (creator principal))
  (default-to u0 (map-get? royalty-balances creator))
)

(define-read-only (is-license-active (token-id uint) (licensee principal))
  (match (map-get? active-licenses { token-id: token-id, licensee: licensee })
    license (>= (get end-block license) stacks-block-height)
    false
  )
)

(define-read-only (get-usage-count (token-id uint) (licensee principal))
  (match (map-get? active-licenses { token-id: token-id, licensee: licensee })
    license (get usage-count license)
    u0
  )
)

(define-private (calculate-bulk-discount (base-price uint) (quantity uint))
  (let (
    (tier-1 (default-to { min-quantity: u999999, discount-percentage: u0 } (map-get? bulk-discount-tiers u1)))
    (tier-2 (default-to { min-quantity: u999999, discount-percentage: u0 } (map-get? bulk-discount-tiers u2)))
    (tier-3 (default-to { min-quantity: u999999, discount-percentage: u0 } (map-get? bulk-discount-tiers u3)))
    (total-price (* base-price quantity))
  )
    (if (>= quantity (get min-quantity tier-3))
      (- total-price (/ (* total-price (get discount-percentage tier-3)) u10000))
      (if (>= quantity (get min-quantity tier-2))
        (- total-price (/ (* total-price (get discount-percentage tier-2)) u10000))
        (if (>= quantity (get min-quantity tier-1))
          (- total-price (/ (* total-price (get discount-percentage tier-1)) u10000))
          total-price
        )
      )
    )
  )
)

(define-public (set-bulk-discount-tier
  (tier-id uint)
  (min-quantity uint)
  (discount-percentage uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= discount-percentage u5000) ERR_INVALID_PRICE)
    (asserts! (> min-quantity u1) ERR_INVALID_QUANTITY)
    (map-set bulk-discount-tiers tier-id {
      min-quantity: min-quantity,
      discount-percentage: discount-percentage
    })
    (ok true)
  )
)

(define-public (bulk-rent-license
  (token-id uint)
  (rental-duration uint)
  (quantity uint)
)
  (let (
    (model-data (unwrap! (map-get? model-metadata token-id) ERR_NOT_FOUND))
    (license-data (unwrap! (map-get? license-terms token-id) ERR_NOT_FOUND))
    (base-rental-price (* (get base-price model-data) rental-duration))
    (discounted-price (calculate-bulk-discount base-rental-price quantity))
    (creator (get creator model-data))
    (royalty-amount (/ (* discounted-price (get royalty-percentage model-data)) u10000))
    (platform-fee-amount (/ (* discounted-price (var-get platform-fee)) u10000))
    (creator-amount (- discounted-price (+ royalty-amount platform-fee-amount)))
    (current-block stacks-block-height)
    (end-block (+ current-block (get duration-blocks license-data)))
  )
    (asserts! (> quantity u1) ERR_INVALID_QUANTITY)
    (asserts! (<= quantity (var-get max-bulk-quantity)) ERR_MAX_BULK_EXCEEDED)
    (asserts! (> discounted-price u0) ERR_INVALID_PRICE)
    (try! (stx-transfer? creator-amount tx-sender creator))
    (try! (stx-transfer? platform-fee-amount tx-sender CONTRACT_OWNER))
    (map-set active-licenses
      { token-id: token-id, licensee: tx-sender }
      {
        start-block: current-block,
        end-block: end-block,
        usage-count: u0,
        rental-price: discounted-price
      }
    )
    (map-set royalty-balances creator 
      (+ (default-to u0 (map-get? royalty-balances creator)) royalty-amount)
    )
    (ok { total-paid: discounted-price, quantity: quantity, savings: (- (* base-rental-price quantity) discounted-price) })
  )
)

(define-read-only (get-bulk-discount-tier (tier-id uint))
  (map-get? bulk-discount-tiers tier-id)
)

(define-read-only (calculate-bulk-price (token-id uint) (rental-duration uint) (quantity uint))
  (match (map-get? model-metadata token-id)
    model-data
      (let (
        (base-rental-price (* (get base-price model-data) rental-duration))
        (discounted-price (calculate-bulk-discount base-rental-price quantity))
      )
        (ok { 
          base-price: (* base-rental-price quantity),
          discounted-price: discounted-price,
          savings: (- (* base-rental-price quantity) discounted-price)
        })
      )
    ERR_NOT_FOUND
  )
)

(define-public (list-license-for-sale (token-id uint) (asking-price uint))
  (let (
    (license-key { token-id: token-id, licensee: tx-sender })
    (license (unwrap! (map-get? active-licenses license-key) ERR_NOT_FOUND))
    (listing-key { token-id: token-id, seller: tx-sender })
    (current-block stacks-block-height)
  )
    (asserts! (<= current-block (get end-block license)) ERR_LICENSE_EXPIRED)
    (asserts! (> asking-price u0) ERR_INVALID_PRICE)
    (asserts! (is-none (map-get? marketplace-listings listing-key)) ERR_ALREADY_LISTED)
    (map-set marketplace-listings listing-key {
      asking-price: asking-price,
      listed-at-block: current-block
    })
    (ok true)
  )
)

(define-public (delist-license (token-id uint))
  (let (
    (listing-key { token-id: token-id, seller: tx-sender })
  )
    (asserts! (is-some (map-get? marketplace-listings listing-key)) ERR_NOT_LISTED)
    (map-delete marketplace-listings listing-key)
    (ok true)
  )
)

(define-public (purchase-listed-license (token-id uint) (seller principal))
  (let (
    (listing-key { token-id: token-id, seller: seller })
    (listing (unwrap! (map-get? marketplace-listings listing-key) ERR_NOT_LISTED))
    (license-key { token-id: token-id, licensee: seller })
    (license (unwrap! (map-get? active-licenses license-key) ERR_NOT_FOUND))
    (asking-price (get asking-price listing))
    (current-block stacks-block-height)
    (model-data (unwrap! (map-get? model-metadata token-id) ERR_NOT_FOUND))
    (creator (get creator model-data))
    (royalty-amount (/ (* asking-price (get royalty-percentage model-data)) u10000))
    (platform-fee-amount (/ (* asking-price (var-get platform-fee)) u10000))
    (seller-amount (- asking-price (+ royalty-amount platform-fee-amount)))
  )
    (asserts! (not (is-eq tx-sender seller)) ERR_CANNOT_BUY_OWN_LISTING)
    (asserts! (<= current-block (get end-block license)) ERR_LICENSE_EXPIRED)
    (try! (stx-transfer? seller-amount tx-sender seller))
    (try! (stx-transfer? platform-fee-amount tx-sender CONTRACT_OWNER))
    (map-set royalty-balances creator
      (+ (default-to u0 (map-get? royalty-balances creator)) royalty-amount)
    )
    (map-delete marketplace-listings listing-key)
    (map-delete active-licenses license-key)
    (map-set active-licenses
      { token-id: token-id, licensee: tx-sender }
      license
    )
    (ok true)
  )
)

(define-read-only (get-listing (token-id uint) (seller principal))
  (map-get? marketplace-listings { token-id: token-id, seller: seller })
)

(define-read-only (is-listed (token-id uint) (seller principal))
  (is-some (map-get? marketplace-listings { token-id: token-id, seller: seller }))
)

