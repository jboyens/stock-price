#lang racket

(require http http/request json racket/cmdline)

(define symbol (command-line #:args (symbol)
                             symbol))

(define API_URL "https://api.iextrading.com/1.0/stock/~a/quote")

(define (read-entity/jsexpr in h)
  (input-port? string? . -> . jsexpr?)
  (read-json in))

(define (stock-data symbol)
  (string? . -> . jsexpr?)
  (let ([url (format API_URL symbol)])
    (call/input-request "1.1" "GET" url empty read-entity/jsexpr)))

(define (format-stock-data data)
  (hash? . -> . string?)
  (let* ([symbol (hash-ref data 'symbol)]
        [latestPrice (hash-ref data 'latestPrice)]
        [change (hash-ref data 'change)]
        [arrow (if (positive? change) "" "")])
    (format "~a ~a ~a ~a" symbol latestPrice change arrow)))

(define cache-dir (build-path (getenv "HOME") ".cache" "stock-price"))

;; always succeeds - either the dir exists or it's going to create it
(make-directory* cache-dir)

(define stock-cache-file (build-path cache-dir symbol))

(define time-since-last-update
  (if (not (file-exists? stock-cache-file))
    +inf.0
    (- (current-seconds)
       (file-or-directory-modify-seconds stock-cache-file))))

;; wait 15 mins to hit the API again (to be nice)
(when (time-since-last-update . > . 900)
  (display-to-file (format-stock-data (stock-data symbol))
                   stock-cache-file
                   #:mode 'text
                   #:exists 'replace))

(display (file->string stock-cache-file))
