%%%% -*- Mode: Prolog -*-
%%%% uri-parse.pl --
%%%% Implementazione di un parser di URI semplificato

%%%% Autore: Terzi Telemaco
%%%% Matricola: 865981
%%% -------------------------------------------------------------------
%%% uri_parse/2
%%% uri_parse(+URIString, -URI)
%%% Vero quando URIString può essere scomposto in un URI del tipo:
%%% uri(SchemeF, UserinfoF, HostF, PortF, PathF, QueryF, FragmentF)
%%% Falso altrimenti
%%  Riconosce gli URI che rispettano scheme syntax
uri_parse(String,
          uri(SchemeFFF,
              UserinfoFF,
              HostFF,
              PortF,
              PathFF,
              QueryFF,
              FragmentFF)) :-
    atom_chars(String, StringChars),
    scheme(StringChars, Scheme, Rest),
    atom_string(Scheme, SchemeF),
    check_scheme_syntax(SchemeF),
    string_lower(SchemeF, LowerScheme),
    !,
    scheme_syntax(LowerScheme,
                  Rest,
                  result(Userinfo,
                         Host,
                         Port,
                         Path,
                         Query,
                         Fragment),
                  []),
    replace_space(Scheme, SchemeFF),
    replace_space(Userinfo, UserinfoF),
    replace_space(Host, HostF),
    replace_space(Path, PathF),
    replace_space(Query, QueryF),
    replace_space(Fragment, FragmentF),
    atom_string_uri(SchemeFFF, SchemeFF),
    atom_string_uri(UserinfoFF, UserinfoF),
    atom_string_uri(HostFF, HostF),
    number_string_uri(PortF, Port),
    atom_string_uri(PathFF, PathF),
    atom_string_uri(QueryFF, QueryF),
    atom_string_uri(FragmentFF, FragmentF).

%% Riconosce gli URI che hanno authorithy
uri_parse(String,
          uri(SchemeFFF,
              UserinfoFF,
              HostFF,
              PortF,
              PathFF,
              QueryFF,
              FragmentFF)) :-
    atom_chars(String, StringChars),
    scheme(StringChars, Scheme, ['/', '/' | Rest1]),
    atom_string_uri(Scheme, SchemeF),
    \+ check_scheme_syntax(SchemeF),
    !,
    authorithy(Rest1, auth(Userinfo, Host, Port), Rest2),
    optional(Rest2, option(Path, Query, Fragment), []),
    replace_space(Scheme, SchemeFF),
    replace_space(Userinfo, UserinfoF),
    replace_space(Host, HostF),
    replace_space(Path, PathF),
    replace_space(Query, QueryF),
    replace_space(Fragment, FragmentF),
    atom_string_uri(SchemeFFF, SchemeFF),
    atom_string_uri(UserinfoFF, UserinfoF),
    atom_string_uri(HostFF, HostF),
    number_string_uri(PortF, Port),
    atom_string_uri(PathFF, PathF),
    atom_string_uri(QueryFF, QueryF),
    atom_string_uri(FragmentFF, FragmentF).

%%  Riconosce gli URI che non hanno authorithy, ma hanno optional
uri_parse(String,
          uri(SchemeFFF,
              [],
              [],
              [],
              PathFF,
              QueryFF,
              FragmentFF)) :-
    atom_chars(String, StringChars),
    scheme(StringChars, Scheme, ['/', C | Ts]),
    C \= '/',
    Ts \= [],
    atom_string_uri(Scheme, SchemeF),
    \+ check_scheme_syntax(SchemeF),
    !,
    optional(['/', C | Ts], option(Path, Query, Fragment), []),
    replace_space(Scheme, SchemeFF),
    replace_space(Path, PathF),
    replace_space(Query, QueryF),
    replace_space(Fragment, FragmentF),
    atom_string_uri(SchemeFFF, SchemeFF),
    atom_string_uri(PathFF, PathF),
    atom_string_uri(QueryFF, QueryF),
    atom_string_uri(FragmentFF, FragmentF).

%% Riconosce gli URI che non hanno authorithy, optional e terminano
%% con '/'
uri_parse(String, uri(SchemeFFF, [], [], [], [], [], [])) :-
    atom_chars(String, StringChars),
    scheme(StringChars, Scheme, ['/' | []]),
    atom_string_uri(SchemeF, Scheme),
    \+ check_scheme_syntax(SchemeF),
    !,
    replace_space(Scheme, SchemeFF),
    atom_string_uri(SchemeFFF, SchemeFF).

%% Riconosce gli URI che non hanno authorithy, optional e non
%% terminano  con '/'
uri_parse(String, uri(SchemeFFF, [], [], [], [], [], [])) :-
    atom_chars(String, StringChars),
    scheme(StringChars, Scheme, []),
    atom_string(Scheme, SchemeF),
    \+ check_scheme_syntax(SchemeF),
    !,
    replace_space(Scheme, SchemeFF),
    atom_string_uri(SchemeFFF, SchemeFF).

%%% uri_display/2
%%% uri_display(+Stream, +Uri)
%%% Sempre vero ed effettua la stampa su stream di
%%% URI = uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment)
uri_display(StreamOUT, Uri) :-
    Uri = uri(Scheme,
              Userinfo,
              Host,
              Port,
              Path,
              Query,
              Fragment),
    write(StreamOUT, 'Display URI:\n'),
    write(StreamOUT, '\tScheme==>'),
    write(StreamOUT, Scheme),
    write(StreamOUT, '\n'),
    write(StreamOUT, '\tUserinfo==>'),
    write(StreamOUT, Userinfo),
    write(StreamOUT, '\n'),
    write(StreamOUT, '\tHost==>'),
    write(StreamOUT, Host),
    write(StreamOUT, '\n'),
    write(StreamOUT, '\tPort==>'),
    write(StreamOUT, Port),
    write(StreamOUT, '\n'),
    write(StreamOUT, '\tPath==>'),
    write(StreamOUT, Path),
    write(StreamOUT, '\n'),
    write(StreamOUT, '\tQuery==>'),
    write(StreamOUT, Query),
    write(StreamOUT, '\n'),
    write(StreamOUT, '\tFragment==>'),
    write(StreamOUT, Fragment),
    write(StreamOUT, '\n').

%%% uri_display/1
%%% uri_display(+Uri)
%%% Sempre vero ma effettua la stampa su stdout di
%%% URI = uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment)
uri_display(Uri) :-
    current_output(Stream),
    uri_display(Stream, Uri),
    !.

%%% scheme/3
%%% scheme(+StringList, -SchemeF, -Rest)
%%% Vero quando StringList è formata da SchemeF ':' Rest.
%%% Falso altrimenti
scheme(StringList, SchemeF, Rest) :-
    recognize_scheme(StringList, [], SchemeF, Rest),
    !.

%%% recognize_scheme/4
%%% recognize_scheme(+StringList, +Scheme, -SchemeFF, -Rest)
%%% Simula un'automa che riconosce scheme.
%%% - StringList è la lista di input
%%% - Scheme è la lista di scheme riconosciuta prima di leggere il
%%% nuovo carattere
%%% - SchemeFF è la lista di scheme riconosciuta dopo aver letto
%%% il carattere
%%% - Rest è il resto della stringa, tutto quello dopo il ':'
%%% Vero quando la sottostringa di prefisso rispetta [SCHEME].
%%% Falso altrimenti.
recognize_scheme([':' | Ts], Scheme, Scheme, Ts) :-
    Scheme \= [],
    !.
recognize_scheme([C | Ts], Scheme, SchemeFF, Rest) :-
    schemeIdentificator(C),
    !,
    append(Scheme, [C], SchemeF),
    recognize_scheme(Ts, SchemeF, SchemeFF, Rest).

%%% authorithy/3
%%% authorithy(+StringList, -auth(Userinfo, Host, Port), -Rest)
%%% Vero quando StringList si può scomporre in
%%% [Userinfo '@'] Host [':' Port] e quando Rest è
%%% ['/' [PATH] ['?' QUERY] ['#' FRAGMENT]]
%%% Falso altrimenti.
authorithy(StringList, auth(Userinfo, Host, Port), Rest) :-
    recognize_authorithy(StringList, Userinfo, Host, Port, Rest),
    !.

%%% recognize_authorithy/5
%%% recognize_authorithy(+StringList, -UserinfoF, -HostF, -PortFF,
%%% -RestF)
%%% Simula un'automa che riconosce authorithy.
%%% - StringList è la lista di input
%%% - UserinfoF è la lista di userinfo riconosciuta
%%% - HostF è la lista di host riconosciuta
%%% - PortF è la lista di port riconosciuta
%%% - Rest è il resto della lista, tutto quello dopo port: ['/' | _]
%%% oppure []
%%% Vero quando StringList si può scomporre in
%%% [Userinfo '@'] Host [':' Port] e quando Rest è il resto della
%%% lista: ['/' [PATH] ['?' QUERY] ['#' FRAGMENT]]
%%% Falso altrimenti.
recognize_authorithy(StringList,
                     UserinfoF,
                     HostF,
                     PortFF,
                     RestF) :-
    recognize_userinfo(StringList, [], UserinfoF, Rest1),
    UserinfoF \= [],
    host(Rest1, HostF, Rest2),
    HostF \= [],
    !,
    recognize_port(Rest2, [], PortF, RestF),
    check_null_port(PortF, PortFF).
recognize_authorithy(StringList,
                     [],
                     HostF,
                     PortFF,
                     RestF) :-
    \+ recognize_userinfo(StringList, [], _Userinfo, _Rest),
    host(StringList, HostF, Rest2),
    HostF \= [],
    !,
    recognize_port(Rest2, [], PortF, RestF),
    check_null_port(PortF, PortFF).

%%% recognize_userinfo/4
%%% recognize_userinfo(+StringList, +Userinfo, -UserinfoFF, -Rest)
%%% Simula un'automa che riconosce userinfo.
%%% - StringList è la lista di input
%%% - Userinfo è tutto quello riconosciuto prima di leggere il nuovo
%%% carattere
%%% - UserinfoFF è quello riconosciuto leggendo il nuovo carattere
%%% - Rest è il resto della lista di input ovvero l'Host
%%% Vero quando StringList contiene come prefisso una sottostringa
%%% userinfo
%%% Falso altrimenti.
recognize_userinfo(['@' | Ts], [], [], Ts) :- !.
recognize_userinfo(['@' | Ts], Userinfo, Userinfo, Ts) :-
    Userinfo \= [],
    !.
recognize_userinfo([C | Ts], Userinfo, UserinfoFF, Rest) :-
    userinfoIdentificator(C),
    !,
    append(Userinfo, [C], UserinfoF),
    recognize_userinfo(Ts, UserinfoF, UserinfoFF, Rest).

%%% host/3
%%% host(+StringList, -HostFF, -Rest)
%%% - StringList è la lista di input
%%% - HostFF è l'host riconosciuto
%%% - Rest è il resto della lista di input ovvero la porta
%%% o optional o []
%%% Vero quando StringList contiene come prefisso una sottostringa
%%% host
%%% Falso altrimenti.
host(StringList, Host, Rest) :-
    StringList \= [],
    recognize_ip(StringList, 0, [], [], Host, Rest),
    !.
host(StringList, Host, Rest) :-
    \+ recognize_ip(StringList, 0, [], [], _Host, _Rest),
    !,
    recognize_host(StringList, [], Host, Rest),
    Host \= [].

%%% recognize_ip/6
%%% recognize_ip(+StringList, +Ottetto, +Host, +OttettoList,
%%% -HostFF, -Rest)
%%% Simula un'automa che riconosce ip.
%%% - StringList è la lista di input
%%% - Ottetto è il contatore di ottetti
%%% - Host è tutto quello riconosciuto prima di leggere il nuovo
%%% carattere
%%% - OttettoList è la lista dell'ultimo ottetto parziale riconosciuto
%%% - HostFF è quello riconosciuto leggendo il nuovo
%%% carattere
%%% - Rest è il resto della lista di input ovvero la porta o
%%% optional o []
%%% Vero quando StringList contiene come prefisso una
%%% sottostringa ip
%%% Falso altrimenti.
recognize_ip([],
             3,
             Host,
             OttettoList,
             Host,
             []) :-
    length(OttettoList, 3),
    !.
recognize_ip([':' | Ts],
             3,
             Host,
             OttettoList,
             Host,
             [':' | Ts]) :-
    length(OttettoList, 3),
    !.
recognize_ip(['/' | Ts],
             3,
             Host,
             OttettoList,
             Host,
             ['/' | Ts]) :-
    length(OttettoList, 3),
    !.
recognize_ip([D | Ts],
             Ottetto,
             Host,
             OttettoList,
             HostFF,
             Rest) :-
    Ottetto < 4,
    ipIdentificator(D),
    length(OttettoList, L),
    L < 3,
    !,
    append(OttettoList, [D], OttettoListF),
    is_ip(OttettoListF),
    append(Host, [D], HostF),
    recognize_ip(Ts,
                  Ottetto,
                  HostF,
                  OttettoListF,
                  HostFF,
                  Rest).
recognize_ip(['.' | Ts],
             Ottetto,
             Host,
             OttettoList,
             HostFF,
             Rest) :-
    OttettoInc is Ottetto + 1,
    length(OttettoList, 3),
    !,
    append(Host, ['.'], HostF),
    recognize_ip(Ts,
                  OttettoInc,
                  HostF,
                  [],
                  HostFF,
                  Rest).

%%% recognize_host/4
%%% recognize_host(+StringList, +Host, -HostFF, -Rest)
%%% Simula un'automa che riconosce host.
%%% - StringList è la lista di input
%%% - Host è tutto quello riconosciuto prima di leggere il nuovo
%%% carattere
%%% - HostFF è quello riconosciuto leggendo il nuovo carattere
%%% - Rest è il resto della lista di input ovvero la porta
%%% o optional o []
%%% Vero quando StringList contiene come prefisso una
%%% sottostringa host
%%% Falso altrimenti.
recognize_host([], Host, Host, []) :-
    Host \= [],
    !.
recognize_host([':' | Ts], Host, Host, [':' | Ts]) :-
    Host \= [],
    !.
recognize_host(['/' | Ts], Host, Host, ['/' | Ts]) :-
    Host \= [],
    !.
recognize_host(['.', C | Ts], Host, HostFF, Rest) :-
    Host \= [],
    hostIdentificator(C),
    !,
    append(Host, ['.', C], HostF),
    recognize_host(Ts, HostF, HostFF, Rest).
recognize_host([C | Ts], Host, HostFF, Rest) :-
    hostIdentificator(C),
    !,
    append(Host, [C], HostF),
    recognize_host(Ts, HostF, HostFF, Rest).

%%% recognize_port/4
%%% recognize_port(+StringList, +Port, -PortFF, -Rest)
%%% Simula un'automa che riconosce port.
%%% - StringList è la lista di input
%%% - Port è tutto quello riconosciuto prima di leggere il nuovo
%%% carattere
%%% - PortFF è quello riconosciuto leggendo il nuovo carattere
%%% - Rest è il resto della lista di input ovvero optional o []
%%% Vero quando StringList contiene come prefisso una sottostringa
%%% port e 0 <= Port <= 65535
%%% Falso altrimenti.
recognize_port([], Port, Port, []) :- !.
recognize_port(['/' | Ts], Port, Port, ['/' | Ts]) :- !.
recognize_port([':', D | Ts], Port, PortFF, Rest) :-
    portIdentificator(D),
    !,
    append(Port, [D], PortF),
    is_port(PortF),
    recognize_port(Ts, PortF, PortFF, Rest).
recognize_port([D | Ts], Port, PortFF, Rest) :-
    portIdentificator(D),
    !,
    append(Port, [D], PortF),
    is_port(PortF),
    recognize_port(Ts, PortF, PortFF, Rest).

%%% optional/3
%%% optional(+StringList, -option(Path, Query, Fragment), -Rest)
%%% Vero quando StringList è formata da
%%% ['/' [PATH] ['?' QUERY] ['#'FRAGMENT]]
%%% Falso altrimenti
optional(StringList, option(Path, Query, Fragment), Rest) :-
    recognize_optional(StringList,
                       Path,
                       Query,
                       Fragment,
                       Rest),
    !.

%%% recognize_optional/5
%%% recognize_optional(+StringList, -Path, -Query, -Fragment, -Rest)
%%% Simula un'automa che riconosce optional.
%%% - StringList è la lista di input
%%% - Path è la lista di path riconosciuta
%%% - Query è la lista di query riconosciuta
%%% - Fragment è la lista di fragment riconosciuta
%%% - Rest è il resto della lista ovvero []
%%% Vero quando StringList è formata da ['/' [PATH] ['?' QUERY]
%%% ['#'FRAGMENT]] e Rest è []
%%% Falso altrimenti
recognize_optional([], [], [], [], []) :- !.
recognize_optional(StringList, Path, Query, Fragment, []) :-
    path(StringList, Path, Rest1),
    query(Rest1, Query, Rest2),
    fragment(Rest2, Fragment, []),
    !.

%%% path/3
%%% path(+StringList, -Path, -Rest)
%%% Vero quando StringList inizia con '/' e dopo
%%% [PATH] o ['?' QUERY] o ['#'FRAGMENT]
%%% Falso altrimenti.
path([], [], []) :- !.
path(['/', '?' | Ts], [], ['?' | Ts]) :- !.
path(['/', '#' | Ts], [], ['#' | Ts]) :- !.
path(['/' | []], [], []) :- !.
path(['/', C | Ts], Path, Rest) :-
    pathIdentificator(C),
    !,
    recognize_path(Ts, [C], Path, Rest).

%%% recognize_path/4
%%% recognize_path(+StringList, +Path, -PathFF, -Rest)
%%% Simula un'automa che riconosce path.
%%% - StringList è la lista di input
%%% - Path è la lista di path riconosciuta prima di leggere il
%%% carattere
%%% - PathFF è la lista di path riconosciuta dopo aver letto il
%%% carattere
%%% - Rest è il resto della lista ovvero [] oppure [['?' QUERY] ['#'
%%% FRAGMENT]] oppure [['#' FRAGMENT]]
%%% Vero quando StringList è formata da [[PATH] ['?' QUERY] ['#'
%%% FRAGMENT]] e Rest è []
%%% Falso altrimenti.
recognize_path([], Path, Path, []) :- !.
recognize_path(['?' | Ts], Path, Path, ['?' | Ts]) :- !.
recognize_path(['#' | Ts], Path, Path, ['#' | Ts]) :- !.
recognize_path(['/', C | Ts], Path, PathFF, Rest) :-
    pathIdentificator(C),
    !,
    append(Path, ['/', C], PathF),
    recognize_path(Ts, PathF, PathFF, Rest).
recognize_path([C | Ts], Path, PathFF, Rest) :-
    pathIdentificator(C),
    !,
    append(Path, [C], PathF),
    recognize_path(Ts, PathF, PathFF, Rest).

%%% query/3
%%% query(+StringList, -Query, -Rest)
%%% Vero quando StringList ha come prefisso '?' QUERY o '#' FRAGMENT
%%% Falso altrimenti.
query([], [], []) :- !.
query(['#' | Ts], [], ['#' | Ts]) :- !.
query(['?', C | Ts], Query, Rest) :-
    queryIdentificator(C),
    !,
    recognize_query(Ts, [C], Query, Rest).

%%% recognize_query/4
%%% recognize_query(+StringList, +Query, -QueryFF, -Rest)
%%% Simula un'automa che riconosce query.
%%% - StringList è la lista di input
%%% - Query è la lista di query riconosciuta prima di leggere il
%%% carattere
%%% - QueryFF è la lista di query riconosciuta dopo aver letto il
%%% carattere
%%% - Rest è il resto della lista ovvero [] oppure ['#' FRAGMENT]
%%% Vero quando StringList è formata da QUERY ['#' FRAGMENT] e Rest
%%% è []
%%% Falso altrimenti.
recognize_query([], Query, Query, []) :- !.
recognize_query(['#' | Ts], Query, Query, ['#' | Ts]) :- !.
recognize_query([C | Ts], Query, QueryFF, Rest) :-
    queryIdentificator(C),
    !,
    append(Query, [C], QueryF),
    recognize_query(Ts, QueryF, QueryFF, Rest).

%%% fragment/3
%%% fragment(+StringList, -Fragment, -Rest)
%%% Vero quando StringList ha come prefisso '#' FRAGMENT o []
%%% Falso altrimenti.
fragment([], [], []) :- !.
fragment(['#', C | Ts], Fragment, Rest) :-
    fragmentIdentificator(C),
    !,
    recognize_fragment(Ts, [C], Fragment, Rest).

%%% recognize_fragment/4
%%% recognize_fragment(+StringList, +Fragment, -FragmentFF, -Rest)
%%% Simula un'automa che riconosce fragment.
%%% - StringList è la lista di input
%%% - Fragment è la lista di fragment riconosciuta prima di
%%% leggere il carattere
%%% - FragmentFF è la lista di fragment riconosciuta dopo aver
%%% letto il carattere
%%% - Rest è il resto della lista ovvero []
%%% Vero quando StringList è formata da [FRAGMENT] e Rest è []
%%% Falso altrimenti.
recognize_fragment([], Fragment, Fragment, []) :- !.
recognize_fragment([C | Ts], Fragment, FragmentFF, Rest) :-
    fragmentIdentificator(C),
    !,
    append(Fragment, [C], FragmentF),
    recognize_fragment(Ts, FragmentF, FragmentFF, Rest).

%%% scheme_syntax/4
%%% scheme_syntax(+Scheme, +StringList, -Result, -Rest)
%%% Vero quando StringList rispetta lo scheme particolare
%%% Falso altrimenti.
scheme_syntax("mailto",
              StringList,
              result(Userinfo, Host, [], [], [], []),
              []) :-
    !,
    mailto(StringList, Userinfo, Host, []).
scheme_syntax("news",
              StringList,
              result([], Host, [], [], [], []),
              []) :-
    !,
    news(StringList, Host, []).
scheme_syntax("tel",
              StringList,
              result(Userinfo, [], [], [], [], []),
              []) :-
    !,
    tel_fax(StringList, Userinfo, []).
scheme_syntax("fax",
              StringList,
              result(Userinfo, [], [], [], [], []),
              []) :-
    !,
    tel_fax(StringList, Userinfo, []).
scheme_syntax("zos",
              ['/', '/' | StringList],
              result(Userinfo,
                     Host,
                     Port,
                     Path,
                     Query,
                     Fragment),
              []) :-
    !,
    zos(StringList,
        Userinfo,
        Host,
        Port,
        Path,
        Query,
        Fragment,
        []).
scheme_syntax("zos",
              ['/', C | StringList],
              result([],
                     [],
                     [],
                     Path,
                     Query,
                     Fragment),
              []) :-
    pathZosIdentificator(C),
    !,
    zos(['/', C | StringList],
        [],
        [],
        [],
        Path,
        Query,
        Fragment,
        []).

%%% mailto/4
%%% mailto(+StringList, -Userinfo, -Host, -Rest)
%%% Vero quando StringList rispetta [USERINFO ['@' HOST]]
%%% Falso altrimenti.
mailto([], [], [], []) :- !.
mailto(StringList, Userinfo, [], []) :-
    recognize_scheme_syntax_userinfo(StringList,
                                     [],
                                     Userinfo,
                                     []),
    StringList \= [],
    Userinfo \= [],
    !.
mailto(StringList, Userinfo, Host, []) :-
    recognize_scheme_syntax_userinfo(StringList,
                                     [],
                                     Userinfo,
                                     Rest1),
    Userinfo \= [],
    !,
    host(Rest1, Host, []).

%%% recognize_scheme_syntax_userinfo/4
%%% recognize_scheme_syntax_userinfo(+StringList, +Userinfo,
%%% -UserinfoFF, -Rest)
%%% Simula un'automa che riconosce userinfo per gli scheme syntax.
%%% - StringList è la lista di input
%%% - Userinfo è la lista di userinfo riconosciuta prima di leggere
%%% il carattere
%%% - UserinfoFF è la lista di userinfo riconosciuta dopo aver
%%% letto il carattere
%%% - Rest è il resto della lista
%%% Vero quando StringList è formata da [USERINFO] e Rest è []
%%% oppure ['@' HOST]
%%% Falso altrimenti.
recognize_scheme_syntax_userinfo(['@', C | Ts],
                                 Userinfo,
                                 Userinfo,
                                 [C | Ts]) :-
    hostIdentificator(C),
    !.
recognize_scheme_syntax_userinfo([C | []],
                                 Userinfo,
                                 UserinfoF,
                                 []) :-
    userinfoIdentificator(C),
    !,
    append(Userinfo, [C], UserinfoF).
recognize_scheme_syntax_userinfo([C | Ts],
                                 Userinfo,
                                 UserinfoFF,
                                 Rest) :-
    userinfoIdentificator(C),
    Ts \= [],
    !,
    append(Userinfo, [C], UserinfoF),
    recognize_scheme_syntax_userinfo(Ts,
                                     UserinfoF,
                                     UserinfoFF,
                                     Rest).

%%% news/3
%%% news(+StringList, -HostF, -Rest)
%%% Vero quando StringList rispetta [HOST]
%%% Falso altrimenti.
news([], [], []) :- !.
news([C | Ts], HostF, []) :-
    !,
    host([C | Ts], HostF, []).

%%% tel_fax/3
%%% tel_fax(+StringList, -UserinfoF, -Rest)
%%% Vero quando StringList rispetta [USERINFO]
%%% Falso altrimenti.
tel_fax([], [], []) :- !.
tel_fax([C | Ts], UserinfoF, []) :-
    !,
    recognize_scheme_syntax_userinfo([C | Ts], [], UserinfoF, []).

%%% zos/8
%%% zos(+StringList, -Userinfo, -Host, -Port, -Path, -Query,
%%% -Fragment, -Rest)
%%% Vero quando StringList rispetta
%%% [AUTHORITHY] '/' ID44 ['(' ID8 ')'] ['?' QUERY] ['#' FRAGMENT] e
%%% Rest []
%%% Falso altrimenti.
zos(StringList, Userinfo, Host, Port, Path, Query, Fragment, []) :-
    authorithy(StringList, auth(Userinfo, Host, Port), Rest1),
    !,
    zos_path(Rest1, Path, Rest2),
    optional(['/' | Rest2], option([], Query, Fragment), []).
zos(StringList, [], [], [], Path, Query, Fragment, []) :-
    \+ authorithy(StringList, auth(_Userinfo, _Host, _Port), _Rest1),
    !,
    zos_path(StringList, Path, Rest2),
    optional(['/' | Rest2], option([], Query, Fragment), []).

%%% zos_path/3
%%% zos_path(+StringList, -Path, -Rest)
%%% Vero quando StringList rispetta
%%% '/' ID44 ['(' ID8 ')'] e Rest rispetta [] o ['?' QUERY] ['#'
%%% FRAGMENT]
%%% Falso altrimenti.
zos_path(['/', C | Ts], Path, Rest) :-
    pathZosIdentificator(C),
    \+ digit(C),
    recognize_id44(Ts, [C], Id44, [C2 | Ts2]),
    pathZosIdentificator(C2),
    \+ digit(C2),
    !,
    recognize_id8(Ts2, [C2], Id8, Rest),
    append(Id44, Id8, Path).
zos_path(['/', C | Ts], Id44, Rest) :-
    pathZosIdentificator(C),
    \+ digit(C),
    recognize_id44(Ts, [C], Id44, Rest),
    Rest = ['?' | _Ts],
    !.
zos_path(['/', C | Ts], Id44, Rest) :-
    pathZosIdentificator(C),
    \+ digit(C),
    recognize_id44(Ts, [C], Id44, Rest),
    Rest = ['#' | _Ts],
    !.
zos_path(['/', C | Ts], Id44, Rest) :-
    pathZosIdentificator(C),
    \+ digit(C),
    recognize_id44(Ts, [C], Id44, Rest),
    Rest = [],
    !.

%%% recognize_id44/4
%%% recognize_id44(+StringList, +Id44, -Id44F, -Rest)
%%% Simula un'automa che riconosce id44.
%%% - StringList è la lista di input
%%% - Id44 è la lista di id44 riconosciuta prima di leggere il
%%% carattere
%%% - Id44F è la lista di id44 riconosciuta dopo aver
%%% letto il carattere
%%% - Rest è il resto della lista
%%% Vero quando StringList ha come prefisso ID44 o ID44 ['(' ID8 ')']
%%% e Rest rispetta [] o [ID8 ')'] e ID44 inizia con un carattere
%%% alfabetico e non termina con un punto e la lunghezza è <= 44
%%% Falso altrimenti.
recognize_id44([], Id44, Id44, []) :- !.
recognize_id44(['?' | Ts], Id44, Id44, ['?' | Ts]) :- !.
recognize_id44(['#' | Ts], Id44, Id44, ['#' | Ts]) :- !.
recognize_id44(['(', C | Ts], Id44, Id44F, [C | Ts]) :-
    pathZosIdentificator(C),
    !,
    append(Id44, ['('], Id44F).
recognize_id44(['.', C | Ts], Id44, Id44FF, Rest) :-
    pathZosIdentificator(C),
    !,
    append(Id44, ['.', C], Id44F),
    length(Id44F, LId44F),
    LId44F =< 44,
    recognize_id44(Ts, Id44F, Id44FF, Rest).
recognize_id44([C | Ts], Id44, Id44FF, Rest) :-
    pathZosIdentificator(C),
    !,
    append(Id44, [C], Id44F),
    length(Id44F, LId44F),
    LId44F =< 44,
    recognize_id44(Ts, Id44F, Id44FF, Rest).

%%% recognize_id8/4
%%% recognize_id8(+StringList, +Id8, -Id8F, -Rest)
%%% Simula un'automa che riconosce id8.
%%% - StringList è la lista di input
%%% - Id8 è la lista di id8 riconosciuta prima di leggere il
%%% carattere
%%% - Id8F è la lista di id8 riconosciuta dopo aver
%%% letto il carattere
%%% - Rest è il resto della lista
%%% Vero quando StringList ha come prefisso [] o ID8 ')' e Rest è
%%% [], ID8 inizia con un carattere alfabetico e la lunghezza è <= 8
%%% Falso altrimenti.
recognize_id8([')' | Ts], Id8, Id8F, Ts) :-
    !,
    append(Id8, [')'], Id8F).
recognize_id8([C | Ts], Id8, Id8FF, Rest) :-
    pathZosIdentificator(C),
    !,
    append(Id8, [C], Id8F),
    length(Id8F, LId8F),
    LId8F =< 8,
    recognize_id8(Ts, Id8F, Id8FF, Rest).

%%% Predicati per specificare l'insieme di caratteri accettati
digit('0').
digit('1').
digit('2').
digit('3').
digit('4').
digit('5').
digit('6').
digit('7').
digit('8').
digit('9').
%%% special characters
charat('.') :- !.
charat('/') :- !.
charat('?') :- !.
charat('#') :- !.
charat('@') :- !.
charat(':') :- !.
charat('!') :- !.
charat('$') :- !.
charat('&') :- !.
charat('(') :- !.
charat(')') :- !.
charat('*') :- !.
charat('-') :- !.
charat('+') :- !.
charat('\'') :- !.
charat(',') :- !.
charat(';') :- !.
charat('=') :- !.
charat('[') :- !.
charat(']') :- !.
charat('_') :- !.
charat('~') :- !.
charat(' ') :- !.
charat(C) :-
    alphabetic(C),
    !.
alphabetic(C) :-
    lower(C),
    !.
alphabetic(C) :-
    upper(C),
    !.
alphanumeric(C) :-
    alphabetic(C),
    !.
alphanumeric(C) :-
    digit(C),
    !.
%%% upper characters
upper('A') :- !.
upper('B') :- !.
upper('C') :- !.
upper('D') :- !.
upper('E') :- !.
upper('F') :- !.
upper('G') :- !.
upper('H') :- !.
upper('I') :- !.
upper('J') :- !.
upper('K') :- !.
upper('L') :- !.
upper('M') :- !.
upper('N') :- !.
upper('O') :- !.
upper('P') :- !.
upper('Q') :- !.
upper('R') :- !.
upper('S') :- !.
upper('T') :- !.
upper('U') :- !.
upper('V') :- !.
upper('W') :- !.
upper('X') :- !.
upper('Y') :- !.
upper('Z') :- !.
%%% lower characters
lower('a') :- !.
lower('b') :- !.
lower('c') :- !.
lower('d') :- !.
lower('e') :- !.
lower('f') :- !.
lower('g') :- !.
lower('h') :- !.
lower('i') :- !.
lower('j') :- !.
lower('k') :- !.
lower('l') :- !.
lower('m') :- !.
lower('n') :- !.
lower('o') :- !.
lower('p') :- !.
lower('q') :- !.
lower('r') :- !.
lower('s') :- !.
lower('t') :- !.
lower('u') :- !.
lower('v') :- !.
lower('w') :- !.
lower('x') :- !.
lower('y') :- !.
lower('z') :- !.
identificator(C) :-
    charat(C),
    C \= '/',
    C \= '?',
    C \= '#',
    C \= '@',
    C \= ':',
    !.
identificator(D) :-
    digit(D),
    !.
schemeIdentificator(C) :-
    identificator(C).
userinfoIdentificator(C) :-
    identificator(C).
hostIdentificator(C) :-
    identificator(C),
    C \= '.'.
portIdentificator(D) :-
    digit(D).
ipIdentificator(D) :-
    digit(D).
pathIdentificator(C) :-
    identificator(C).
pathZosIdentificator(C) :-
    alphanumeric(C),
    !.
queryIdentificator(C) :-
    charat(C),
    C \= '#',
    !.
queryIdentificator(D) :-
    digit(D),
    !.
fragmentIdentificator(C) :-
    charat(C),
    !.
fragmentIdentificator(D) :-
    digit(D),
    !.

%%% default_port/1
%%% default_port(?Port)
%%% Vero se Port è ['8', '0']
%%% Falso altrimenti
default_port(['8', '0']).

%%% is_port/1
%%% is_port(?Port)
%%% Vero quando Port è un numero compreso tra 0 e 65535 inclusi
%%% Falso altrimenti
is_port(Port) :-
    atomics_to_string(Port, String),
    atom_number(String, N),
    N >= 0,
    N =< 65535.

%%% check_null_port/2
%%% check_null_port(?Port, ?PortF)
%%% Il predicato non fallisce mai. PortF sarà Port se l'ultimo è
%%% diverso sa [], altrimenti ['8', '0']
check_null_port([], PortF) :-
    !,
    default_port(PortF).
check_null_port(Port, Port) :-
    Port \= [],
    !.

%%% is_ip/1
%%% is_ip(?Ip)
%%% Vero quando Ip è una lista di caratteri che convertita in numero è
%%% compreso tra 0 e 255 inclusi
%%% Falso altrimenti
is_ip(Ip) :-
    atomics_to_string(Ip, String),
    atom_number(String, N),
    N >= 0,
    N =< 255.

%%% replace_space/2
%%% replace_space(?List, ?ListReplaced)
%%% Vero quando ListReplaced ha
%%% tutti gli elementi di List tranne gli spazi che
%%% sono sostituiti con %20.
%%% Falso altrimenti
replace_space([], []) :- !.
replace_space([' ' | Hs], ['%', '2', '0' | Ts]) :-
    !,
    replace_space(Hs, Ts).
replace_space([C | Hs], [C | Ts]) :-
    C \= ' ',
    !,
    replace_space(Hs, Ts).

%%% scheme_syntax_type/1
%%% scheme_syntax_type(?Scheme)
%%% Vero se Scheme è uno scheme syntax
%%% Falso altrimenti
scheme_syntax_type("mailto") :- !.
scheme_syntax_type("news") :- !.
scheme_syntax_type("tel") :- !.
scheme_syntax_type("fax") :- !.
scheme_syntax_type("zos") :- !.

%%% check_scheme_syntax/1
%%% check_scheme_syntax(+Scheme)
%%% Vero se Scheme è uguale a uno scheme syntax
%%% Falso altrimenti
check_scheme_syntax(Scheme) :-
    string_lower(Scheme, LowerScheme),
    scheme_syntax_type(LowerScheme).

%%% atom_string_uri/2
%%% atom_string_uri(?Atom, ?String)
%%% Ha lo stesso comportamento di atom_string con la differenza che
%%% aggiunge il caso in cui Atom è [] e String è "".
atom_string_uri([], "") :- !.
atom_string_uri([], []) :- !.
atom_string_uri(Atom, String) :-
    atom_string(Atom, String),
    !.
number_string_uri([], "") :- !.
number_string_uri([], []) :- !.
number_string_uri(Number, String) :-
    !,
    number_string(Number, String).
number_string_uri(Number, String) :-
    var(Number),
    nonvar(String),
    String \= [],
    !,
    number_string(Number, String).
number_string_uri(Number, String) :-
    var(Number),
    nonvar(String),
    String \= "",
    !,
    number_string(Number, String).
number_string_uri(Number, String) :-
    var(String),
    nonvar(Number),
    !,
    number_string(Number, String).

%%%% end of file -- uri-parse.pl --
