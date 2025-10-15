(define-constant contract-owner tx-sender)
(define-constant err-owner-only u100)
(define-constant err-not-member u101)
(define-constant err-insufficient-balance u102)
(define-constant err-group-not-found u103)
(define-constant err-already-member u104)
(define-constant err-invalid-amount u105)
(define-constant err-group-inactive u106)
(define-constant err-lock-period-not-met u107)

(define-data-var next-group-id uint u1)
(define-data-var inflation-rate uint u300)

(define-map savings-groups uint {
    name: (string-ascii 50),
    admin: principal,
    total-balance: uint,
    member-count: uint,
    active: bool,
    created-at: uint
})

(define-map group-members {group-id: uint, member: principal} {
    balance: uint,
    deposit-time: uint,
    active: bool,
    min-lock-period: uint,
    savings-goal: uint
})

(define-private (calculate-inflation-adjustment (principal-amount uint) (time-elapsed uint))
    (let ((annual-rate (var-get inflation-rate))
          (rate-per-block (/ annual-rate u52560)))
        (+ principal-amount (/ (* principal-amount rate-per-block time-elapsed) u10000))))

(define-public (create-savings-group (name (string-ascii 50)))
    (let ((group-id (var-get next-group-id)))
        (map-set savings-groups group-id {
            name: name,
            admin: tx-sender,
            total-balance: u0,
            member-count: u0,
            active: true,
            created-at: stacks-block-height
        })
        (var-set next-group-id (+ group-id u1))
        (print {event: "group-created", group-id: group-id, admin: tx-sender})
        (ok group-id)))

(define-public (join-group (group-id uint))
    (match (map-get? savings-groups group-id)
        group-data
        (if (and (get active group-data) (is-none (map-get? group-members {group-id: group-id, member: tx-sender})))
            (begin
                (map-set group-members {group-id: group-id, member: tx-sender} {
                    balance: u0,
                    deposit-time: stacks-block-height,
                    active: true,
                    min-lock-period: u0,
                    savings-goal: u0
                })
                (map-set savings-groups group-id
                    (merge group-data {member-count: (+ (get member-count group-data) u1)}))
                (print {event: "member-joined", group-id: group-id, member: tx-sender})
                (ok true))
            (if (get active group-data)
                (err err-already-member)
                (err err-group-inactive)))
        (err err-group-not-found)))

(define-public (deposit (group-id uint) (amount uint))
    (if (and (> amount u0) (is-some (map-get? savings-groups group-id)))
        (let ((group-data (unwrap-panic (map-get? savings-groups group-id)))
              (member-key {group-id: group-id, member: tx-sender}))
            (if (and (get active group-data) (is-some (map-get? group-members member-key)))
                (let ((member-data (unwrap-panic (map-get? group-members member-key))))
                    (if (get active member-data)
                        (begin
                            (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
                            (let ((new-balance (+ (get balance member-data) amount)))
                                (map-set group-members member-key
                                    (merge member-data {
                                        balance: new-balance,
                                        deposit-time: stacks-block-height
                                    }))
                                (map-set savings-groups group-id
                                    (merge group-data {total-balance: (+ (get total-balance group-data) amount)}))
                                (print {event: "deposit", group-id: group-id, member: tx-sender, amount: amount})
                                (ok new-balance)))
                        (err err-not-member)))
                (if (get active group-data)
                    (err err-not-member)
                    (err err-group-inactive))))
        (if (> amount u0)
            (err err-group-not-found)
            (err err-invalid-amount))))

(define-public (withdraw (group-id uint) (amount uint))
    (if (and (> amount u0) (is-some (map-get? savings-groups group-id)))
        (let ((group-data (unwrap-panic (map-get? savings-groups group-id)))
              (member-key {group-id: group-id, member: tx-sender}))
            (if (and (get active group-data) (is-some (map-get? group-members member-key)))
                (let ((member-data (unwrap-panic (map-get? group-members member-key))))
                    (if (get active member-data)
                        (let ((time-elapsed (- stacks-block-height (get deposit-time member-data)))
                              (current-balance (get balance member-data))
                              (adjusted-balance (calculate-inflation-adjustment current-balance time-elapsed)))
                            (if (>= time-elapsed (get min-lock-period member-data))
                                (if (<= amount adjusted-balance)
                                    (begin
                                        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
                                        (let ((remaining-balance (- current-balance amount)))
                                            (map-set group-members member-key
                                                (merge member-data {balance: remaining-balance}))
                                            (map-set savings-groups group-id
                                                (merge group-data {total-balance: (- (get total-balance group-data) amount)}))
                                            (print {event: "withdrawal", group-id: group-id, member: tx-sender, amount: amount})
                                            (ok remaining-balance)))
                                    (err err-insufficient-balance))
                                (err err-lock-period-not-met)))
                        (err err-not-member)))
                (if (get active group-data)
                    (err err-not-member)
                    (err err-group-inactive))))
        (if (> amount u0)
            (err err-group-not-found)
            (err err-invalid-amount))))

(define-public (leave-group (group-id uint))
    (let ((member-key {group-id: group-id, member: tx-sender}))
        (match (map-get? group-members member-key)
            member-data
            (if (get active member-data)
                (let ((time-elapsed (- stacks-block-height (get deposit-time member-data)))
                      (current-balance (get balance member-data))
                      (final-balance (calculate-inflation-adjustment current-balance time-elapsed)))
                    (if (> final-balance u0)
                        (try! (as-contract (stx-transfer? final-balance tx-sender tx-sender)))
                        true)
                    (map-set group-members member-key
                        (merge member-data {active: false, balance: u0}))
                    (match (map-get? savings-groups group-id)
                        group-data
                        (map-set savings-groups group-id
                            (merge group-data {
                                member-count: (- (get member-count group-data) u1),
                                total-balance: (- (get total-balance group-data) final-balance)
                            }))
                        true)
                    (print {event: "member-left", group-id: group-id, member: tx-sender, final-balance: final-balance})
                    (ok final-balance))
                (err err-not-member))
            (err err-not-member))))

(define-public (set-min-lock-period (group-id uint) (period uint))
    (let ((member-key {group-id: group-id, member: tx-sender}))
        (match (map-get? group-members member-key)
            member-data
            (if (get active member-data)
                (begin
                    (map-set group-members member-key
                        (merge member-data {min-lock-period: period}))
                    (print {event: "lock-period-set", group-id: group-id, member: tx-sender, period: period})
                    (ok period))
                (err err-not-member))
            (err err-not-member))))

(define-public (update-inflation-rate (new-rate uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (var-set inflation-rate new-rate)
            (print {event: "inflation-rate-updated", new-rate: new-rate})
            (ok new-rate))
        (err err-owner-only)))

(define-public (deactivate-group (group-id uint))
    (match (map-get? savings-groups group-id)
        group-data
        (if (is-eq tx-sender (get admin group-data))
            (begin
                (map-set savings-groups group-id (merge group-data {active: false}))
                (print {event: "group-deactivated", group-id: group-id})
                (ok true))
            (err err-owner-only))
        (err err-group-not-found)))

(define-read-only (get-group-info (group-id uint))
    (map-get? savings-groups group-id))

(define-read-only (get-member-info (group-id uint) (member principal))
    (match (map-get? group-members {group-id: group-id, member: member})
        member-data
        (let ((time-elapsed (- stacks-block-height (get deposit-time member-data)))
              (current-balance (get balance member-data))
              (adjusted-balance (calculate-inflation-adjustment current-balance time-elapsed)))
            (some {
                balance: current-balance,
                deposit-time: (get deposit-time member-data),
                inflation-adjusted-balance: adjusted-balance,
                active: (get active member-data)
            }))
        none))

(define-read-only (get-current-inflation-rate)
    (var-get inflation-rate))

(define-read-only (calculate-projected-balance (principal-amount uint) (blocks-ahead uint))
    (calculate-inflation-adjustment principal-amount blocks-ahead))

(define-read-only (get-group-stats (group-id uint))
    (match (map-get? savings-groups group-id)
        group-data
        (some {
            total-balance: (get total-balance group-data),
            member-count: (get member-count group-data),
            active: (get active group-data),
            inflation-rate: (var-get inflation-rate)
        })
        none))

(define-read-only (get-member-adjusted-balance (group-id uint) (member principal))
    (match (map-get? group-members {group-id: group-id, member: member})
        member-data
        (let ((time-elapsed (- stacks-block-height (get deposit-time member-data)))
              (current-balance (get balance member-data)))
            (calculate-inflation-adjustment current-balance time-elapsed))
        u0))

(define-public (set-savings-goal (group-id uint) (goal uint))
    (let ((member-key {group-id: group-id, member: tx-sender}))
        (match (map-get? group-members member-key)
            member-data
            (if (get active member-data)
                (begin
                    (map-set group-members member-key
                        (merge member-data {savings-goal: goal}))
                    (print {event: "savings-goal-set", group-id: group-id, member: tx-sender, goal: goal})
                    (ok goal))
                (err err-not-member))
            (err err-not-member))))

(define-read-only (get-savings-goal-progress (group-id uint) (member principal))
    (match (map-get? group-members {group-id: group-id, member: member})
        member-data
        (let ((time-elapsed (- stacks-block-height (get deposit-time member-data)))
              (current-balance (get balance member-data))
              (adjusted-balance (calculate-inflation-adjustment current-balance time-elapsed))
              (goal (get savings-goal member-data)))
            (if (> goal u0)
                (/ (* adjusted-balance u100) goal)
                u0))
        u0))
