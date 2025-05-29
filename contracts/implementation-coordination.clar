;; Implementation Coordination Contract
;; Manages collective intelligence implementation

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_PROJECT_NOT_FOUND (err u401))
(define-constant ERR_INVALID_STATUS (err u402))
(define-constant ERR_RESOURCE_NOT_FOUND (err u403))

;; Project status
(define-constant STATUS_PLANNING u1)
(define-constant STATUS_IN_PROGRESS u2)
(define-constant STATUS_COMPLETED u3)
(define-constant STATUS_CANCELLED u4)

;; Resource types
(define-constant RESOURCE_HUMAN u1)
(define-constant RESOURCE_FINANCIAL u2)
(define-constant RESOURCE_TECHNICAL u3)
(define-constant RESOURCE_INFRASTRUCTURE u4)

;; Data structures
(define-map implementation-projects
  { project-id: uint }
  {
    title: (string-ascii 200),
    description: (string-ascii 1000),
    synthesis-id: uint,
    lead-entity: uint,
    status: uint,
    start-date: uint,
    target-completion: uint,
    actual-completion: uint,
    budget-allocated: uint,
    budget-used: uint
  }
)

(define-map project-participants
  { project-id: uint, participant: principal }
  {
    entity-id: uint,
    role: (string-ascii 50),
    contribution-type: (string-ascii 100),
    joined-at: uint,
    active: bool
  }
)

(define-map resource-allocations
  { project-id: uint, resource-id: uint }
  {
    resource-type: uint,
    description: (string-ascii 200),
    quantity: uint,
    allocated-by: principal,
    allocated-at: uint,
    utilized: bool
  }
)

(define-map project-milestones
  { project-id: uint, milestone-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 300),
    target-date: uint,
    completion-date: uint,
    completed: bool,
    responsible-entity: uint
  }
)

(define-map coordination-metrics
  { project-id: uint }
  {
    collaboration-score: uint,
    efficiency-rating: uint,
    stakeholder-satisfaction: uint,
    impact-assessment: uint,
    lessons-learned: (string-ascii 500)
  }
)

(define-data-var next-project-id uint u1)
(define-data-var next-resource-id uint u1)
(define-data-var next-milestone-id uint u1)

;; Create implementation project
(define-public (create-project
  (title (string-ascii 200))
  (description (string-ascii 1000))
  (synthesis-id uint)
  (lead-entity uint)
  (target-completion uint)
  (budget-allocated uint))
  (let ((project-id (var-get next-project-id)))
    (map-set implementation-projects
      { project-id: project-id }
      {
        title: title,
        description: description,
        synthesis-id: synthesis-id,
        lead-entity: lead-entity,
        status: STATUS_PLANNING,
        start-date: block-height,
        target-completion: target-completion,
        actual-completion: u0,
        budget-allocated: budget-allocated,
        budget-used: u0
      }
    )
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Add project participant
(define-public (add-participant
  (project-id uint)
  (participant principal)
  (entity-id uint)
  (role (string-ascii 50))
  (contribution-type (string-ascii 100)))
  (begin
    (map-set project-participants
      { project-id: project-id, participant: participant }
      {
        entity-id: entity-id,
        role: role,
        contribution-type: contribution-type,
        joined-at: block-height,
        active: true
      }
    )
    (ok true)
  )
)

;; Allocate resources
(define-public (allocate-resource
  (project-id uint)
  (resource-type uint)
  (description (string-ascii 200))
  (quantity uint))
  (let ((resource-id (var-get next-resource-id)))
    (map-set resource-allocations
      { project-id: project-id, resource-id: resource-id }
      {
        resource-type: resource-type,
        description: description,
        quantity: quantity,
        allocated-by: tx-sender,
        allocated-at: block-height,
        utilized: false
      }
    )
    (var-set next-resource-id (+ resource-id u1))
    (ok resource-id)
  )
)

;; Add project milestone
(define-public (add-milestone
  (project-id uint)
  (title (string-ascii 100))
  (description (string-ascii 300))
  (target-date uint)
  (responsible-entity uint))
  (let ((milestone-id (var-get next-milestone-id)))
    (map-set project-milestones
      { project-id: project-id, milestone-id: milestone-id }
      {
        title: title,
        description: description,
        target-date: target-date,
        completion-date: u0,
        completed: false,
        responsible-entity: responsible-entity
      }
    )
    (var-set next-milestone-id (+ milestone-id u1))
    (ok milestone-id)
  )
)

;; Update project status
(define-public (update-project-status (project-id uint) (new-status uint))
  (match (map-get? implementation-projects { project-id: project-id })
    project-data (begin
      (asserts! (or (is-eq new-status STATUS_PLANNING)
                   (is-eq new-status STATUS_IN_PROGRESS)
                   (is-eq new-status STATUS_COMPLETED)
                   (is-eq new-status STATUS_CANCELLED)) ERR_INVALID_STATUS)
      (map-set implementation-projects
        { project-id: project-id }
        (merge project-data {
          status: new-status,
          actual-completion: (if (is-eq new-status STATUS_COMPLETED) block-height (get actual-completion project-data))
        })
      )
      (ok true)
    )
    ERR_PROJECT_NOT_FOUND
  )
)

;; Complete milestone
(define-public (complete-milestone (project-id uint) (milestone-id uint))
  (match (map-get? project-milestones { project-id: project-id, milestone-id: milestone-id })
    milestone-data (begin
      (map-set project-milestones
        { project-id: project-id, milestone-id: milestone-id }
        (merge milestone-data {
          completed: true,
          completion-date: block-height
        })
      )
      (ok true)
    )
    ERR_PROJECT_NOT_FOUND
  )
)

;; Get project information
(define-read-only (get-project (project-id uint))
  (map-get? implementation-projects { project-id: project-id })
)

;; Get project participant
(define-read-only (get-participant (project-id uint) (participant principal))
  (map-get? project-participants { project-id: project-id, participant: participant })
)

;; Get resource allocation
(define-read-only (get-resource (project-id uint) (resource-id uint))
  (map-get? resource-allocations { project-id: project-id, resource-id: resource-id })
)

;; Get milestone
(define-read-only (get-milestone (project-id uint) (milestone-id uint))
  (map-get? project-milestones { project-id: project-id, milestone-id: milestone-id })
)

;; Calculate project progress
(define-read-only (calculate-progress (project-id uint))
  (match (map-get? implementation-projects { project-id: project-id })
    project-data (let
      ((elapsed-time (- block-height (get start-date project-data)))
       (total-time (- (get target-completion project-data) (get start-date project-data)))
       (time-progress (if (> total-time u0) (/ (* elapsed-time u100) total-time) u0))
       (budget-progress (if (> (get budget-allocated project-data) u0)
                          (/ (* (get budget-used project-data) u100) (get budget-allocated project-data)) u0)))
      (some {
        time-progress: time-progress,
        budget-progress: budget-progress,
        status: (get status project-data)
      })
    )
    none
  )
)
