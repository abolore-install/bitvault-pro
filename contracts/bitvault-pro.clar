;; Title: BitVault Pro - Intelligent Asset Orchestration Protocol
;; 
;; Summary: Next-generation decentralized portfolio management with automated 
;;          rebalancing and intelligent asset allocation strategies built for 
;;          Bitcoin Layer 2 ecosystems
;;
;; Description: BitVault Pro revolutionizes decentralized finance by providing 
;;              institutional-grade portfolio management tools directly on the 
;;              Stacks blockchain. This protocol enables users to create 
;;              sophisticated investment strategies with automated rebalancing, 
;;              risk management, and multi-asset allocation. Designed specifically 
;;              for Bitcoin Layer 2 infrastructure, BitVault Pro combines the 
;;              security of Bitcoin with the flexibility of smart contracts to 
;;              deliver professional-grade wealth management solutions accessible 
;;              to everyone.
;;
;; Features:
;;   - Multi-asset portfolio creation with up to 10 tokens per portfolio
;;   - Automated time-based rebalancing mechanisms
;;   - Granular permission controls and ownership management
;;   - Real-time portfolio valuation and performance tracking
;;   - Gas-optimized operations with minimal transaction costs
;;   - Bitcoin-native security with Stacks Layer 2 efficiency
;;

;; ERROR DEFINITIONS

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PORTFOLIO (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-REBALANCE-FAILED (err u104))
(define-constant ERR-PORTFOLIO-EXISTS (err u105))
(define-constant ERR-INVALID-PERCENTAGE (err u106))
(define-constant ERR-MAX-TOKENS-EXCEEDED (err u107))
(define-constant ERR-LENGTH-MISMATCH (err u108))
(define-constant ERR-USER-STORAGE-FAILED (err u109))
(define-constant ERR-INVALID-TOKEN-ID (err u110))

;; PROTOCOL CONFIGURATION

(define-data-var protocol-owner principal tx-sender)
(define-data-var portfolio-counter uint u0)
(define-data-var protocol-fee uint u25) ;; 0.25% represented as basis points

;; SYSTEM CONSTANTS

(define-constant MAX-TOKENS-PER-PORTFOLIO u10)
(define-constant BASIS-POINTS u10000)

;; DATA STORAGE MAPS

;; Core portfolio metadata storage
(define-map Portfolios
    uint ;; portfolio-id
    {
        owner: principal,
        created-at: uint,
        last-rebalanced: uint,
        total-value: uint,
        active: bool,
        token-count: uint
    }
)

;; Individual asset configurations within portfolios
(define-map PortfolioAssets
    {portfolio-id: uint, token-id: uint}
    {
        target-percentage: uint,
        current-amount: uint,
        token-address: principal
    }
)

;; User portfolio ownership tracking
(define-map UserPortfolios
    principal
    (list 20 uint)
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve complete portfolio information by ID
(define-read-only (get-portfolio (portfolio-id uint))
    (map-get? Portfolios portfolio-id)
)

;; Get specific asset configuration within a portfolio
(define-read-only (get-portfolio-asset (portfolio-id uint) (token-id uint))
    (map-get? PortfolioAssets {portfolio-id: portfolio-id, token-id: token-id})
)

;; List all portfolios owned by a specific user
(define-read-only (get-user-portfolios (user principal))
    (default-to (list) (map-get? UserPortfolios user))
)

;; Calculate rebalancing requirements and timing
(define-read-only (calculate-rebalance-amounts (portfolio-id uint))
    (let (
        (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
        (total-value (get total-value portfolio))
    )
    (ok {
        portfolio-id: portfolio-id,
        total-value: total-value,
        needs-rebalance: (> (- block-height (get last-rebalanced portfolio)) u144) ;; 24 hours in blocks
    }))
)

;; INTERNAL VALIDATION FUNCTIONS

;; Validate token ID within portfolio constraints
(define-private (validate-token-id (portfolio-id uint) (token-id uint))
    (let (
        (portfolio (unwrap! (get-portfolio portfolio-id) false))
    )
    (and 
        (< token-id MAX-TOKENS-PER-PORTFOLIO)
        (< token-id (get token-count portfolio))
        true
    ))
)

;; Ensure percentage values are within valid range
(define-private (validate-percentage (percentage uint))
    (and (>= percentage u0) (<= percentage BASIS-POINTS))
)