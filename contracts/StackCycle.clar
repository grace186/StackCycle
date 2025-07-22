;; ------------------------------------------------------------
;; Contract: StackCycle
;; Description: Reward-based recycling verification system on Stacks
;; Author: Thankgod Isaac + ChatGPT
;; License: MIT
;; ------------------------------------------------------------

(define-constant admin tx-sender)

;; --- Product Types ---
(define-map product-types
  (buff 32)
  {
    name: (string-ascii 30),
    reward: uint,
    active: bool
  }
)

;; --- Centers ---
(define-map centers
  principal
  bool
)

;; --- User Points & Claim Tracking ---
(define-map user-points
  principal
  uint
)

(define-map rewards-claimed
  principal
  uint
)

;; --- User History: list of past recycled types ---
(define-map user-history
  {user: principal, index: uint}
  {
    type-id: (buff 32),
    quantity: uint,
    reward: uint,
    timestamp: uint
  }
)

;; Track how many submissions a user has
(define-map user-submissions-count
  principal
  uint
)

;; Reward threshold (adjustable)
(define-data-var reward-threshold uint u100)

;; ----------------------------
;; ERROR CODES
;; ----------------------------
;; u401 - Unauthorized
;; u402 - Not enough points
;; u403 - Not an approved center
;; u404 - Product type not found
;; u405 - No reward to claim
;; u406 - STX transfer failed
;; u407 - Invalid quantity
;; u408 - Arithmetic overflow
;; u409 - Product type disabled

;; ----------------------------
;; ADMIN FUNCTIONS
;; ----------------------------

(define-public (register-center (center principal))
  (begin
    (asserts! (is-eq tx-sender admin) (err u401))
    (map-set centers center true)
    (ok true)
  )
)

(define-public (disable-center (center principal))
  (begin
    (asserts! (is-eq tx-sender admin) (err u401))
    (map-delete centers center)
    (ok true)
  )
)

(define-public (add-product-type (type-id (buff 32)) (name (string-ascii 30)) (reward uint))
  (begin
    (asserts! (is-eq tx-sender admin) (err u401))
    (map-set product-types type-id {name: name, reward: reward, active: true})
    (ok true)
  )
)

(define-public (disable-product-type (type-id (buff 32)))
  (begin
    (asserts! (is-eq tx-sender admin) (err u401))
    (let ((p (map-get? product-types type-id)))
      (match p
        data 
          (begin
            (map-set product-types type-id (merge data {active: false}))
            (ok true)
          )
        (err u404)
      )
    )
  )
)

(define-public (set-reward-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender admin) (err u401))
    (var-set reward-threshold new-threshold)
    (ok new-threshold)
  )
)

;; ----------------------------
;; CORE LOGIC
;; ----------------------------

(define-public (submit-recycle (user principal) (type-id (buff 32)) (quantity uint))
  (begin
    (asserts! (default-to false (map-get? centers tx-sender)) (err u403))
    (asserts! (> quantity u0) (err u407))

    (let (
      (type-data (map-get? product-types type-id))
    )
      (match type-data
        type-info 
          (begin
            (asserts! (get active type-info) (err u409))
            (let (
              (total-reward (* quantity (get reward type-info)))
              (old-points (default-to u0 (map-get? user-points user)))
              (new-points (+ old-points total-reward))
              (count (default-to u0 (map-get? user-submissions-count user)))
              (timestamp stacks-block-height)
            )
              (asserts! (>= new-points old-points) (err u408))

              ;; Record points
              (map-set user-points user new-points)

              ;; Store history
              (map-set user-history {user: user, index: count}
                {
                  type-id: type-id,
                  quantity: quantity,
                  reward: total-reward,
                  timestamp: timestamp
                }
              )

              ;; Increment user submission count
              (map-set user-submissions-count user (+ count u1))

              (ok new-points)
            )
          )
        (err u404)
      )
    )
  )
)

(define-public (claim-reward)
  (let (
    (points (default-to u0 (map-get? user-points tx-sender)))
    (claimed (default-to u0 (map-get? rewards-claimed tx-sender)))
    (unclaimed (- points claimed))
    (threshold (var-get reward-threshold))
  )
    (asserts! (>= unclaimed threshold) (err u402))
    (let (
      (reward-amount (/ unclaimed u10))
    )
      (asserts! (> reward-amount u0) (err u405))
      (match (as-contract (stx-transfer? reward-amount (as-contract tx-sender) tx-sender))
        success (begin
          (map-set rewards-claimed tx-sender (+ claimed unclaimed))
          (ok reward-amount)
        )
        error (err u406)
      )
    )
  )
)

;; ----------------------------
;; READ-ONLY HELPERS
;; ----------------------------

(define-read-only (get-user-points (user principal))
  (default-to u0 (map-get? user-points user))
)

(define-read-only (get-product-type (type-id (buff 32)))
  (map-get? product-types type-id)
)

(define-read-only (is-center? (center principal))
  (is-some (map-get? centers center))
)

(define-read-only (get-claimed (user principal))
  (default-to u0 (map-get? rewards-claimed user))
)

(define-read-only (get-user-submissions (user principal))
  (default-to u0 (map-get? user-submissions-count user))
)

(define-read-only (get-user-history (user principal) (index uint))
  (map-get? user-history {user: user, index: index})
)

(define-read-only (get-reward-threshold)
  (var-get reward-threshold)
)

(define-read-only (get-unclaimed-points (user principal))
  (let (
    (points (default-to u0 (map-get? user-points user)))
    (claimed (default-to u0 (map-get? rewards-claimed user)))
  )
    (- points claimed)
  )
)