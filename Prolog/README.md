# Parser di stringhe URI
Parser di stringhe URI è un utility che permette all'utente di fare il
parsing di stringhe URI.

Il parser è un'implementazione semplificata dello standard
[RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986).
## Prerequisiti
Per usare il progetto si richiede l'ultima versione di SWI-Prolog.
## Richieste progetto
Sviluppare un parser di stringhe URI semplificato.
Per ogni stringa in input si devono riconoscere le seguenti sottostringhe:
1. Scheme
2. Userinfo
3. Host
4. Port (default 80)
5. Path
6. Query
7. Fragment
### Grammatica
La grammatica è definita in questo modo:
```python
URI ::= SCHEME ':' [AUTHORITHY]  ['/' [PATH] ['?' QUERY] ['#' FRAGMENT]]
URI ::= 'mailto' ':' [USERINFO ['@' HOST]]
URI ::= 'news' ':' [HOST]
URI ::= 'tel' ':' [USERINFO]
URI ::= 'fax' ':' [USERINFO]
URI ::= 'zos' ':' [AUTHORITHY]  '/' ID44 ['(' ID8 ')'] ['?' QUERY]
    	['#' FRAGMENT]
AUTHORITHY ::= '//' [USERINFO '@'] HOST [':' PORT]
USERINFO ::= IDENTIFICATORE
HOST ::= IDENTIFICATORE-HOST ['.' IDENTIFICATORE-HOST]* | IP
IP ::= NNN '.' NNN '.' NNN '.' NNN 
N ::= DIGIT
PORT ::= DIGIT+
PATH ::= IDENTIFICATORE ['/' IDENTIFICATORE]*
QUERY ::= <caratteri senza '#'>+
FRAGMENT ::= <caratteri>+
IDENTIFICATORE ::= <caratteri senza '/', '?', '#', '@' e ':'>+
IDENTIFICATORE-HOST ::= <caratteri senza '.', '/', '?', '#', '@', e ':'>+
DIGIT ::= '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' 
ID44 ::= (<caratteri alfanumerici> | '.')+
ID8 ::= <caratteri alfanumerici>+
```
Osservazioni:
- Il campo **PORT** ha come valore di default 80, quando authorithy è presente. 
- Il campo **IP** è stato implementato anche se è inutile dato che in ogni caso 
  se la sottostringa di **HOST** non è un **IP** viene riconosciuto come un 
  identificatore. 
- Il campo **ID44** deve iniziare con un carattere alfabetico e non deve 
  terminare con un punto, inoltre la sua lunghezza non deve superare i 
  44 caratteri.
- Il campo **ID8** deve iniziare con un carattere alfabetico e la sua lunghezza 
  non deve superare gli 8 caratteri.
- Tutti i campi ad eccezione di **PORT** e **PATH** dello schema **ZOS** 
  accettano anche lo spazio il quale verrà codificato in %20.

## Utilizzo 
Per caricare il progetto in SWI-Prolog basta invocare il predicato **consult** e si
specifica il path del sorgente:
```prolog
?- consult('D:\\progetto\\uri-parse.pl').
true.
```
Una volta che il progetto è stato caricato su SWI-Prolog, si può eseguire 
interrogando l'interprete:
```Prolog
?- uri_parse("http://www.google.it/search", U).
U = uri(http, [], 'www.google.it', 80, search, [], []).
```
Utilizzando l'interfaccia uri_display si può stampare in modo formattato su 
terminale l'URI unificata.
```Prolog
?- uri_parse("http://www.google.it/search", U), uri_display(U).
Display URI:
        Scheme==>http
        Userinfo==>[]
        Host==>www.google.it
        Port==>80
        Path==>search
        Query==>[]
        Fragment==>[]
U = uri(http, [], 'www.google.it', 80, search, [], [])
```
**uri_display** permette anche la stampa formattata su uno stream
```Prolog
?- uri_parse("http://www.google.it/search", U), 
   open("out.txt", write, OUT), 
   uri_display(OUT, U), 
   close(OUT).
U = uri(http, [], 'www.google.it', 80, search, [], []),
OUT = <stream>(000000000DB95DC0).
```
```Txt
**** FILE out.txt ****
Display URI:
        Scheme==>http
        Userinfo==>[]
        Host==>www.google.it
        Port==>80
        Path==>search
        Query==>[]
        Fragment==>[]
```
## Autore
L'autore del progetto è Telemaco Terzi matricola 865981.