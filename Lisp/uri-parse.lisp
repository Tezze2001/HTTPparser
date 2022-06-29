;;;; -*- Mode: Lisp -*-
;;;; uri-parse.lisp --
;;;; Implementazione di un parser di URI semplificato

;;;; Autore: Terzi Telemaco
;;;; Matricola: 865981
;;;--------------------------------------------------------------------
;;; definzione di costanti
(defparameter *mailto* "mailto")
(defparameter *news* "news")
(defparameter *tel* "tel")
(defparameter *fax* "fax")
(defparameter *zos* "zos")
(defparameter *default-port* (coerce "80" 'list))
(defparameter *default-max-port-number* 65535)
(defparameter *default-max-ip-number* 255)

;;; definizione dell'oggetto che rappresenta un uri
(defclass uri ()
  ((scheme :reader uri-scheme :initarg :scheme :initform NIL)
   (userinfo :reader uri-userinfo :initarg :userinfo :initform NIL)
   (host :reader uri-host :initarg :host :initform NIL)
   (port :reader uri-port :initarg :port :initform NIL)
   (path :reader uri-path :initarg :path :initform NIL)
   (query :reader uri-query :initarg :query :initform NIL)
   (fragment :reader uri-fragment :initarg :fragment :initform NIL)))

;;; funzione per stampare su stream l'uri-structure
;;; uri-structure -> T / NIL
(defun uri-display (uri-structure &optional (stream T))
  (if (not (null uri-structure))
      (progn
        (not (format stream
                     "Scheme: ~s~%"
                     (uri-scheme uri-structure)))
        (not (format stream
                     "Userinfo: ~s~%"
                     (uri-userinfo uri-structure)))
        (not (format stream
                     "Host: ~s~%"
                   (uri-host uri-structure)))
        (not (format stream
                     "Port: ~s~%"
                     (uri-port uri-structure)))
        (not (format stream
                     "Path: ~s~%"
                     (uri-path uri-structure)))
        (not (format stream
                     "Query: ~s~%"
                     (uri-query uri-structure)))
        (not (format stream
                     "Fragment: ~s~%"
                     (uri-fragment uri-structure))))
    (progn
        (not (format stream
                     "Scheme: ~s~%"
                     NIL))
        (not (format stream
                     "Userinfo: ~s~%"
                     NIL))
        (not (format stream
                     "Host: ~s~%"
                     NIL))
        (not (format stream
                     "Port: ~s~%"
                     NIL))
        (not (format stream
                     "Path: ~s~%"
                     NIL))
        (not (format stream
                     "Query: ~s~%"
                     NIL))
        (not (format stream
                     "Fragment: ~s~%"
                     NIL)))))

;;; funzione per scomporre la stringa e ricavare le sottosezioni
;;; dell'uri
;;; string -> uri-structure
(defun uri-parse (string)
  (let ((list (coerce string 'list)))
    (multiple-value-bind 
        (scheme-list rest) 
        (recognize-scheme list)
      (if (not (null scheme-list))
            (cond ((not (null (scheme-syntax-p scheme-list)))
                   (uri-parse-scheme-syntax scheme-list
                                            rest))
                  ((not (null (authorithy-p rest))) 
                   (uri-parse-authorithy scheme-list rest))
                  (T (uri-parse-optional scheme-list rest)))))))

;;; funzione per riconoscere authorithy e optional dall'uri
;;; list -> uri-structure
(defun uri-parse-authorithy (scheme-list rest)
  (multiple-value-bind 
      (userinfo-list host-list port-list rest) 
      (recognize-authorithy (authorithy-p rest))
    (multiple-value-bind 
        (path-list query-list fragment-list rest) 
        (recognize-optional (optional-p rest))
      (if (and (not (null host-list))
               (null rest))
          (make-instance 'uri 
                         :scheme 
                         (uri-coerce (replace-space scheme-list)
                                     'string)
                         :userinfo 
                         (uri-coerce (replace-space userinfo-list)
                                     'string)
                         :host 
                         (uri-coerce (replace-space host-list)
                                     'string)
                         :port 
                         (parse-integer (coerce port-list 'string))
                         :path 
                         (uri-coerce (replace-space path-list)
                                     'string)
                         :query 
                         (uri-coerce (replace-space query-list)
                                     'string)
                         :fragment 
                         (uri-coerce (replace-space fragment-list)
                                     'string))))))   

;;; funzione per riconoscere optional dall'uri
;;; list -> uri-structure
(defun uri-parse-optional (scheme-list rest)
  (multiple-value-bind 
      (path-list query-list fragment-list rest) 
      (recognize-optional (optional-p rest))
    (if (null rest)
        (make-instance 'uri 
                       :scheme 
                       (uri-coerce (replace-space scheme-list)
                                   'string)
                       :path 
                       (uri-coerce (replace-space path-list)
                                   'string)
                       :query 
                       (uri-coerce (replace-space query-list)
                                   'string)
                       :fragment 
                       (uri-coerce (replace-space fragment-list)
                                   'string)))))

;;; funzione per riconoscere scheme-syntax dall'uri
;;; list -> uri-structure
(defun uri-parse-scheme-syntax (scheme-list rest)
  (let ((scheme-syntax (scheme-syntax-p scheme-list)))
    (cond ((eql scheme-syntax *mailto*)
           (uri-parse-mailto scheme-list rest))
          ((eql scheme-syntax *news*)
           (uri-parse-news scheme-list rest))
          ((or (eql scheme-syntax *tel*)
               (eql scheme-syntax *fax*))
           (uri-parse-tel-fax scheme-list rest))
          ((eql scheme-syntax *zos*)
           (uri-parse-zos scheme-list rest)))))

;;; funzione per riconoscere mailto
;;; list -> uri-structure
(defun uri-parse-mailto (scheme-list rest)
  (multiple-value-bind 
      (userinfo-list host-list rest) 
      (recognize-mailto rest)
    (if (null rest)
        (make-instance 'uri 
                       :scheme 
                       (uri-coerce (replace-space scheme-list) 
                                   'string)
                       :userinfo 
                       (uri-coerce (replace-space userinfo-list) 
                                   'string)
                       :host 
                       (uri-coerce (replace-space host-list)
                                   'string)))))

;;; funzione per riconoscere news
;;; list -> uri-structure
(defun uri-parse-news (scheme-list rest)
  (multiple-value-bind 
      (host-list rest) 
      (recognize-news rest)
    (if (null rest)
        (make-instance 'uri 
                       :scheme
		       (uri-coerce (replace-space scheme-list)
                                   'string)
                       :host
		       (uri-coerce (replace-space host-list)
                                   'string)))))

;;; funzione per riconoscere tel o fax
;;; list -> uri-structure
(defun uri-parse-tel-fax (scheme-list rest)
  (multiple-value-bind 
      (userinfo-list rest) 
      (recognize-tel-fax rest)
    (if (null rest)
        (make-instance 'uri 
                       :scheme 
                       (uri-coerce (replace-space scheme-list)
                                   'string)
                       :userinfo 
                       (uri-coerce (replace-space userinfo-list)
                                   'string)))))

;;; funzione per riconoscere zos
;;; list -> uri-structure
(defun uri-parse-zos (scheme-list rest)
  (if (not (null (authorithy-p rest)))
      (multiple-value-bind 
          (userinfo-list host-list port-list rest) 
          (recognize-authorithy (authorithy-p rest))
        (if (eql (first rest) #\/)
            (multiple-value-bind 
                (path-list rest) 
                (recognize-scheme-syntax-path (rest rest))
              (multiple-value-bind 
                  (query-list fragment-list rest) 
                  (recognize-scheme-syntax-optional rest)
                (if (and (null rest)
                         (not (null path-list)))
                    (make-instance 'uri 
                                   :scheme 
                                   (uri-coerce (replace-space scheme-list)
                                               'string)
                                   :userinfo 
                                   (uri-coerce (replace-space userinfo-list)
                                               'string)
                                   :host 
                                   (uri-coerce (replace-space host-list) 
                                               'string)
                                   :port 
                                   (parse-integer (coerce port-list
                                                          'string))
                                   :path 
                                   (uri-coerce (replace-space path-list) 
                                               'string)
                                   :query 
                                   (uri-coerce (replace-space query-list)
                                               'string)
                                   :fragment 
                                   (uri-coerce (replace-space fragment-list)
                                               'string)))))))
    (multiple-value-bind 
        (path-list rest) 
        (recognize-scheme-syntax-path (optional-p rest))
      (multiple-value-bind 
          (path-list-nil query-list fragment-list rest) 
          (recognize-optional rest)
        (if (and (null rest)
                 (not (null path-list))
                 (null path-list-nil))
            (make-instance 'uri 
                           :scheme 
                           (uri-coerce (replace-space scheme-list)
                                       'string)
                           :path 
                           (uri-coerce (replace-space path-list)
                                       'string)
                           :query 
                           (uri-coerce (replace-space  query-list)
                                       'string)
                           :fragment 
                           (uri-coerce (replace-space fragment-list)
                                       'string)))))))

;;; funzione per riconoscere se il carattere è un digit
;;; char -> T / NIL
(defun digit (char)
  (digit-char-p char))

;;; funzione per riconoscere se il carattere è uno dei caratteri
;;; accettati
;;; char -> T / NIL
(defun char-p (char)
  (or (digit char)
      (both-case-p char)
      (eql char #\.)
      (eql char #\/)
      (eql char #\?)
      (eql char #\#)
      (eql char #\@)
      (eql char #\:)
      (eql char #\!)
      (eql char #\$)
      (eql char #\&)
      (eql char #\()
      (eql char #\))
      (eql char #\*)
      (eql char #\+)
      (eql char #\')
      (eql char #\-)
      (eql char #\,)
      (eql char #\;)
      (eql char #\=)
      (eql char #\[)
      (eql char #\])
      (eql char #\_)
      (eql char #\~)
      (eql char #\Space)))

;;; funzione per riconoscere se il carattere è un identificatore
;;; char -> T / NIL
(defun identificator (char)
  (or (and (char-p char)
           (not (eql char #\/))
           (not (eql char #\?))
           (not (eql char #\#))
           (not (eql char #\@))
           (not (eql char #\:)))
      (digit char)))

;;; funzione per riconoscere se il carattere è un identificatore host
;;; char -> T / NIL
(defun host-identificator (char)
  (or (and (identificator char)
           (not (eql char #\.)))
      (digit char)))

;;; funzione per riconoscere se il carattere è un identificatore ip
;;; char -> T / NIL
(defun ip-identificator (char)
  (or (eql char #\.)
      (digit char)))

;;; funzione per controllare se il valore dell'ottetto ip è un valore
;;; accettato
;;; list -> T / NIL
(defun ip-p (ip-list)
  (<= (parse-integer (coerce ip-list 'string))
      *default-max-ip-number*))

;;; funzione per riconoscere se il carattere è un identificatore port
;;; char -> T / NIL
(defun port-identificator (char)
  (digit char))

;;; funzione per controllare se la porta è un valore accettato
;;; list -> T / NIL
(defun port-p (port-list)
  (<= (parse-integer (coerce port-list
			     'string))
      *default-max-port-number*))

;;; funzione per riconoscere se il carattere è un identificatore path
;;; char -> T / NIL
(defun path-identificator (char)
  (identificator char))

;;; funzione per riconoscere se il carattere è un identificatore path
;;; per zos
;;; char -> T / NIL
(defun scheme-sintax-path-identificator (char)
  (or (both-case-p char)
      (digit char)
      (eql char #\.)))

;;; funzione per riconoscere se il carattere è un identificatore query
;;; char -> T / NIL
(defun query-identificator (char)
  (and (char-p char)
       (not (eql char #\#))))

;;; funzione per riconoscere se il carattere è un identificatore
;;; fragment
;;; char -> T / NIL
(defun fragment-identificator (char)
  (and (char-p char)))

;;; funzione per riconoscere se la lista coincide con uno
;;; scheme-syntax
;;; list -> T / NIL
(defun scheme-syntax-p (list)
  (let ((str (coerce list 'string)))
    (cond ((string-equal str *mailto*) *mailto*)
          ((string-equal str *news*) *news*)
          ((string-equal str *tel*) *tel*)
          ((string-equal str *fax*) *fax*)
          ((string-equal str *zos*) *zos*)
          (T NIL))))

;;; funzione per riconoscere se la lista inizia con //, 
;;; nel caso restituisce una lista senza // iniziali. 
;;; Altrimenti restituisce NIL.
;;; list -> list / NIL
(defun authorithy-p (list)
  (cond ((and (eql (first list) #\/)
              (eql (second list) #\/))
         (rest (rest list)))
        (T NIL)))

;;; funzione per riconoscere se la lista ha i campi 
;;; optional nel caso restituisce una lista senza 
;;; lo / iniziale, nel caso iniziasse con // allora restituisce 
;;; la lista senza modificarla perché tanto fallirà 
;;; successivamente
;;; list -> list / NIL
(defun optional-p (list)
  (cond ((and (eql (first list) #\/)
              (not (eql (second list) #\/)))
         (rest list))
        ((and (eql (first list) #\/)
              (eql (second list) #\/))
         list)
        (T NIL)))

;;; funzione che richiama coerce
;;; con la differenza che quando si passa NIL ritorna 
;;; NIL
;;; list -> list / NIL
(defun uri-coerce (field type)
  (if (eql field NIL) 
      NIL
    (coerce field type)))

;;; funzione che sostituisce gli spazi in una lista 
;;; con %20
;;; list -> list / NIL
(defun replace-space (list)
  (cond ((null list) NIL)
        ((eql (first list) #\Space) 
         (append '(#\% #\2 #\0)
                 (replace-space (rest list))))
        (T  (append (list (first list)) 
                    (replace-space (rest list))))))

;;; funzione per ricavare scheme dall'uri sottoforma
;;; di lista di caratteri, restituisce la lista 
;;; scheme riconosciuta e il resto della lista di input.
;;; Se restituisce NIL allora c'è stato un errore.
;;; list -> list, list
(defun recognize-scheme (list &key (scheme-list NIL))
  (cond ((null list) NIL)
        ((and (eql (first list) #\:)
              (not (null scheme-list))) 
         (values scheme-list (rest list)))  
        ((identificator (first list))
         (recognize-scheme (rest list)
                           :scheme-list 
                           (append scheme-list
				   (list (first list)))))))

;;; funzione per riconoscere authorithy dall'uri, 
;;; restituisce le liste userinfo, host, port 
;;; riconosciute e il resto della lista uri. 
;;; Se le 4 liste sono NIL allora c'è stato un errore
;;; list -> list, list, list, list
#|(defun recognize-authorithy (list)
  (multiple-value-bind 
      (userinfo-list rest) 
      (recognize-userinfo list)
    (multiple-value-bind
        (host-list rest) 
        (recognize-ip (if (eql userinfo-list NIL)
                          list
                        rest))
      (if (not (null host-list))
          (multiple-value-bind 
              (port-list rest)
              (recognize-port rest)
            (cond ((and (not (null port-list))
                        (port-p port-list)
                        (or (null rest)
                            (eql (first rest) #\/)))
                   (values userinfo-list 
                           host-list 
                           port-list 
                           rest))
                  ((and (null port-list)
                        (or (null rest)
                            (eql (first rest) #\/)))
                   (values userinfo-list 
                           host-list
                           *default-port*
                           rest))
                  (T (values NIL NIL NIL NIL))))
        (multiple-value-bind
            (host-list rest) 
            (recognize-host (if (eql userinfo-list NIL)
                                list
                              rest))
          (if (not (null host-list))
              (multiple-value-bind 
                  (port-list rest)
                  (recognize-port rest)
                (cond ((and (not (null port-list))
                            (port-p port-list)
                            (or (null rest)
                                (eql (first rest) #\/)))
                       (values userinfo-list 
                               host-list 
                               port-list 
                               rest))
                      ((and (null port-list)
                            (or (null rest)
                                (eql (first rest) #\/)))
                       (values userinfo-list 
                               host-list
                               *default-port*
                               rest))
                      (T (values NIL NIL NIL NIL))))))))))|#
(defun recognize-authorithy (list)
  (multiple-value-bind 
      (userinfo-list rest) 
      (recognize-userinfo list)
    (multiple-value-bind
        (host-list rest) 
        (parse-host (if (eql userinfo-list NIL)
                        list
                      rest))
      (if (not (null host-list))
          (multiple-value-bind 
              (port-list rest)
              (recognize-port rest)
            (cond ((and (not (null port-list))
                        (port-p port-list)
                        (or (null rest)
                            (eql (first rest) #\/)))
                   (values userinfo-list 
                           host-list 
                           port-list 
                           rest))
                  ((and (null port-list)
                        (or (null rest)
                            (eql (first rest) #\/)))
                   (values userinfo-list 
                           host-list
                           *default-port*
                           rest))
                  (T (values NIL NIL NIL NIL))))))))

;;; funzione per riconoscere userinfo
;;; restituisce la lista userinfo riconosciuta e il resto della lista
;;; uri. 
;;; Se le 2 liste sono NIL allora c'è stato un errore
;;; list -> list, list
(defun recognize-userinfo (list &key
                                (userinfo-list NIL))
  (cond ((null list) (values NIL NIL))
        ((identificator (first list))
         (recognize-userinfo (rest list) 
                             :userinfo-list 
                             (append userinfo-list
				     (list (first list)))))
        ((and (not (null userinfo-list))
              (eql (first list) #\@))
         (values userinfo-list (rest list)))
        (T (values NIL NIL))))

;;; funzione per riconoscere host 
;;; restituisce la lista host riconosciuta e il resto della lista uri.
;;; Se le 2 liste sono NIL allora c'è stato un errore
;;; list -> list, list
(defun parse-host (list)
  (multiple-value-bind
      (host-list rest) 
      (recognize-ip list)
    (if (not (null host-list))
        (values host-list rest)
      (multiple-value-bind
          (host-list rest) 
          (recognize-host list)
        (values host-list rest)))))

;;; funzione per riconoscere host come un ip
;;; restituisce la lista host riconosciuta e il resto della lista uri.
;;; Se le 2 liste sono NIL allora c'è stato un errore
;;; list -> list, list
(defun recognize-ip (list &key
                          (ip-list NIL)
                          (ultimo-ottetto NIL))
  (cond ((and (null list)
              (eql (length ip-list) 15))
         (values ip-list list))
        ((and (not (null list))
              (not (eql (length ip-list) 15))
              (ip-identificator (first list))
              (not (eql (first list) #\.))
              (ip-p (append ultimo-ottetto (list (first list)))))
         (recognize-ip (rest list) 
                       :ip-list 
                       (append ip-list (list (first list)))
                       :ultimo-ottetto 
                       (append ultimo-ottetto (list (first list)))))
        ((and (not (null list))
              (not (null ip-list))
              (not (eql (length ip-list) 15))
              (eql (first list) #\.)
              (eql (length ultimo-ottetto) 3))
         (recognize-ip (rest list) 
                       :ip-list 
                       (append ip-list (list (first list)))))
        ((and (not (null list))
              (eql (length ip-list) 15)
              (or (eql (first list) #\:)
                  (eql (first list) #\/)))
         (values ip-list list))
        (T (values NIL list))))

;;; funzione per riconoscere host
;;; restituisce la lista host riconosciuta e il resto della lista uri.
;;; Se le 2 liste sono NIL allora c'è stato un errore
;;; list -> list, list
(defun recognize-host (list &key
                            (host-list NIL))
  (cond ((null list) (values host-list list))
        ((and (null host-list)
              (host-identificator (first list)))
         (recognize-host (rest list) 
                         :host-list 
                         (append host-list (list (first list)))))
        ((and (not (null host-list))
              (not (eql (second list) #\:))
              (not (eql (second list) #\/))
              (not (eql (second list) #\.))
              (not (null (rest list)))
              (identificator (first list)))
         (recognize-host (rest list) 
                         :host-list 
                         (append host-list (list (first list)))))
        ((host-identificator (first list))
         (recognize-host (rest list) 
                         :host-list 
                         (append host-list (list (first list)))))
        ((or (eql (first list) #\:)
             (eql (first list) #\/))
         (values host-list list))
        (T (values NIL list))))

;;; funzione per riconoscere port
;;; restituisce la lista port riconosciuta e il resto della lista uri.
;;; Se le 2 liste sono NIL allora c'è stato un errore
;;; list -> list, list
(defun recognize-port (list &key
                            (port-list NIL))
  (cond ((null list) (values port-list list))
        ((and (eql (first list) #\:)
              (not (null (rest list)))
              (port-identificator (second list))
              (null port-list))
         (recognize-port (rest (rest list)) 
                         :port-list 
                         (append port-list (list (second list)))))
        ((and (not (null port-list))
              (port-identificator (first list)))
         (recognize-port (rest list) 
                         :port-list 
                         (append port-list (list (first list)))))
        ((and (not (null port-list))
              (eql (first list) #\/))
         (values port-list list))
        (T (values NIL list))))

;;; funzione per ricavare optional dalla lista
;;; restituisce le liste path, query e fragment riconosciute e il 
;;; resto della lista uri.
;;; Se il resto non è vuoto allora c'è stato un errore
;;; list -> list, list, list, list
(defun recognize-optional (list)
  (multiple-value-bind 
      (path-list rest)
      (recognize-path list)
    (multiple-value-bind
        (query-list rest)
        (recognize-query rest)
      (multiple-value-bind 
          (fragment-list rest)
          (recognize-fragment rest)
        (values path-list query-list fragment-list rest)))))         

;;; funzione per ricavare path dalla lista
;;; restituisce la lista path riconosciuta e il resto della 
;;; lista uri
;;; list -> list, list     
(defun recognize-path (list &key
                            (path-list NIL))
  (cond ((null list) (values path-list
                             list))
        ((and (eql (first list) #\/)
              (not (null (rest list)))
              (not (eql (second list) #\/))
              (not (null path-list)))
         (recognize-path (rest (rest list))
                         :path-list 
                         (append path-list 
                                 (list (first list)) 
                                 (list (second list)))))
        ((path-identificator (first list))
         (recognize-path (rest list)
                         :path-list 
                         (append path-list 
                                 (list (first list)))))
        (T (values path-list list))))

;;; funzione per ricavare query dalla lista
;;; restituisce la lista query riconosciuta e il resto 
;;; della lista uri
;;; list -> list, list
(defun recognize-query (list &key
                             (query-list NIL))
  (cond ((null list) (values query-list
                             list))
        ((and (eql (first list) #\?)
              (null query-list)
              (query-identificator (second list)))
         (recognize-query (rest (rest list))
                          :query-list 
                          (list (second list))))
        ((and (query-identificator (first list))
              (not (null query-list)))
         (recognize-query (rest list)
                          :query-list 
                          (append query-list 
                                  (list (first list)))))
        (T (values query-list list))))

;;; funzione per ricavare fragment dalla lista
;;; restituisce la lista fragment riconosciuta e il resto 
;;; della lista uri
;;; list -> list, list
(defun recognize-fragment (list &key
                                (fragment-list NIL))
  (cond ((null list) (values fragment-list
                             list))
        ((and (eql (first list) #\#)
              (null fragment-list)
              (fragment-identificator (second list)))
         (recognize-fragment (rest (rest list))
                             :fragment-list 
                             (list (second list))))
        ((and (fragment-identificator (first list))
              (not (null fragment-list)))
         (recognize-fragment (rest list)
                             :fragment-list 
                             (append fragment-list 
                                     (list (first list)))))
        (T (values fragment-list list))))

;;; funzione per riconoscere mailto
;;; restituisce le liste userinfo e host riconosciute e il 
;;; resto della lista uri
;;; list -> list, list, list   
(defun recognize-mailto (list)
  (multiple-value-bind
      (userinfo-list rest)
      (recognize-scheme-syntax-userinfo list)
    (multiple-value-bind 
        (host-list rest)
        (parse-host rest)
      (values userinfo-list host-list rest))))

;;; funzione per riconoscere userinfo per gli scheme syntax
;;; restituisce la lista userinfo riconosciuta e il resto 
;;; della lista uri
;;; list -> list, list
(defun recognize-scheme-syntax-userinfo (list &key
                                              (userinfo-list NIL))
  (cond ((null list) (values userinfo-list NIL))
        ((identificator (first list))
         (recognize-scheme-syntax-userinfo (rest list) 
                                           :userinfo-list 
                                           (append userinfo-list 
                                                   (list (first list)))))
        ((and (not (null userinfo-list))
              (eql (first list) #\@)
              (not (null (rest list))))
         (values userinfo-list (rest list)))
        (T (values userinfo-list list))))

;;; funzione per riconoscere news
;;; restituisce la lista host riconosciuta e il resto 
;;; della lista uri
;;; list -> list, list
(defun recognize-news (list)
  (multiple-value-bind 
      (host-list rest)
      (parse-host list)
    (values host-list rest)))

;;; funzione per riconoscere tel e fax  
;;; restituisce la lista userinfo riconosciuta e il 
;;; resto della lista uri
;;; list -> list, list
(defun recognize-tel-fax (list)
  (recognize-scheme-syntax-userinfo list))

;;; funzione per riconoscere path per lo schema zos
;;; restituisce la lista path riconosciuta e il resto
;;; della lista uri
;;; list -> list, list
(defun recognize-scheme-syntax-path (list)
  (multiple-value-bind 
      (id44-list rest)
      (recognize-id44 list)
    (multiple-value-bind 
        (id8-list rest)
        (recognize-id8 rest)
      (values (append id44-list id8-list) rest)))) 

;;; funzione per riconoscere id44
;;; restituisce la lista id44 riconosciuta e il resto 
;;; della lista uri
;;; list -> list, list
(defun recognize-id44 (list &key
                            (id44-list NIL))
  (cond ((null list) (values id44-list list))
        ((and (alphanumericp (first list))
              (or (null (rest list))
                  (eql (second list) #\?)
                  (eql (second list) #\#))
              (<= (length id44-list) 43))
         (values (append id44-list 
                         (list (first list)))
                 (rest list)))
        ((and (alphanumericp (first list))
              (eql (second list) #\()   
              (not (null (rest (rest list))))
              (<= (length id44-list) 43))
         (values (append id44-list 
                         (list (first list) #\())
                 (rest (rest list))))
        ((and (null id44-list) 
              (both-case-p (first list)))
         (recognize-id44 (rest list) 
                         :id44-list 
                         (append id44-list 
                                 (list (first list)))))
        ((and (not (null id44-list))        
              (null (rest list))
              (alphanumericp (first list))
              (<= (length id44-list) 43))
         (values (append id44-list 
                         (list (first list)))
                 (rest list))) 
        ((and (not (null id44-list))
              (not (null (rest list)))
              (scheme-sintax-path-identificator (first list))
              (<= (length id44-list) 43))
         (recognize-id44 (rest list) 
                         :id44-list 
                         (append id44-list 
                                 (list (first list)))))
        (T (values NIL NIL))))

;;; funzione per riconoscere id8
;;; restituisce la lista id8 riconosciuta e il resto 
;;; della lista uri
;;; list -> list, list
(defun recognize-id8 (list &key
                           (id8-list NIL))
  (cond ((null list) (values id8-list list))
        ((and (eql (second list) #\))
              (alphanumericp (first list))
              (<= (length id8-list) 7))
         (values (append id8-list 
                         (list (first list) #\))) 
                 (rest (rest list))))
        ((and (null id8-list) 
              (both-case-p (first list)))
         (recognize-id8 (rest list) 
                        :id8-list 
                        (append id8-list 
                                (list (first list)))))
        ((and (not (null id8-list))
              (not (null (rest list)))
              (alphanumericp (first list))
              (<= (length id8-list) 7))
         (recognize-id8 (rest list) 
                        :id8-list 
                        (append id8-list 
                                (list (first list)))))
        (T (values NIL list))))

;;; funzione per riconoscere optional per zos
;;; restituisce la liste query e fragment riconosciute e 
;;; il resto della lista uri
;;; list -> list, list, list
(defun recognize-scheme-syntax-optional (list)
  (multiple-value-bind 
      (query-list rest)
      (recognize-query list)
    (multiple-value-bind 
        (fragment-list rest)
        (recognize-fragment rest)
	(values query-list fragment-list rest))))

;;;; end of file -- uri-parse.lisp --
