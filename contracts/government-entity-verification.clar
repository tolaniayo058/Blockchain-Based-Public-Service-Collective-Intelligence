;; Government Entity Verification Contract
;; Validates and manages government entities in the collective intelligence system

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ENTITY_NOT_FOUND (err u101))
(define-constant ERR_ENTITY_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Entity verification status
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_REJECTED u2)
(define-constant STATUS_SUSPENDED u3)

;; Data structures
(define-map government-entities
  { entity-id: uint }
  {
    name: (string-ascii 100),
    entity-type: (string-ascii 50),
    jurisdiction: (string-ascii 100),
    contact-info: (string-ascii 200),
    verification-status: uint,
    verified-at: uint,
    verified-by: principal
  }
)

(define-map entity-permissions
  { entity-id: uint }
  {
    can-create-proposals: bool,
    can-vote: bool,
    can-moderate: bool,
    permission-level: uint
  }
)

(define-data-var next-entity-id uint u1)

;; Register a new government entity
(define-public (register-entity
  (name (string-ascii 100))
  (entity-type (string-ascii 50))
  (jurisdiction (string-ascii 100))
  (contact-info (string-ascii 200)))
  (let ((entity-id (var-get next-entity-id)))
    (asserts! (is-none (map-get? government-entities { entity-id: entity-id })) ERR_ENTITY_ALREADY_EXISTS)
    (map-set government-entities
      { entity-id: entity-id }
      {
        name: name,
        entity-type: entity-type,
        jurisdiction: jurisdiction,
        contact-info: contact-info,
        verification-status: STATUS_PENDING,
        verified-at: u0,
        verified-by: CONTRACT_OWNER
      }
    )
    (var-set next-entity-id (+ entity-id u1))
    (ok entity-id)
  )
)

;; Verify an entity (only contract owner)
(define-public (verify-entity (entity-id uint) (status uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (or (is-eq status STATUS_VERIFIED) (is-eq status STATUS_REJECTED)) ERR_INVALID_STATUS)
    (match (map-get? government-entities { entity-id: entity-id })
      entity-data (begin
        (map-set government-entities
          { entity-id: entity-id }
          (merge entity-data {
            verification-status: status,
            verified-at: block-height,
            verified-by: tx-sender
          })
        )
        (if (is-eq status STATUS_VERIFIED)
          (map-set entity-permissions
            { entity-id: entity-id }
            {
              can-create-proposals: true,
              can-vote: true,
              can-moderate: false,
              permission-level: u1
            }
          )
          true
        )
        (ok true)
      )
      ERR_ENTITY_NOT_FOUND
    )
  )
)

;; Get entity information
(define-read-only (get-entity (entity-id uint))
  (map-get? government-entities { entity-id: entity-id })
)

;; Get entity permissions
(define-read-only (get-entity-permissions (entity-id uint))
  (map-get? entity-permissions { entity-id: entity-id })
)

;; Check if entity is verified
(define-read-only (is-entity-verified (entity-id uint))
  (match (map-get? government-entities { entity-id: entity-id })
    entity-data (is-eq (get verification-status entity-data) STATUS_VERIFIED)
    false
  )
)
