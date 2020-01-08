/-  lsp-sur=language-server
/+  *server,
    auto=language-server-complete,
    lsp-parser=language-server-parser,
    easy-print=language-server-easy-print,
    rune-snippet=language-server-rune-snippet,
    build=language-server-build,
    default-agent
|%
+$  card  card:agent:gall
+$  lsp-req
  $:  uri=@t
      $%  [%sync changes=(list change)]
          [%completion position]
          [%commit @ud]
          [%hover position]
      ==
  ==
::
+$  change
  $:  range=(unit range)
      range-length=(unit @ud)
      text=@t
  ==
::
+$  range
  $:  start=position
      end=position
  ==
::
+$  position
  [row=@ud col=@ud]
::
+$  state-zero  [%0 bufs=(map uri=@t buf=wall) builds=(map uri=@t =vase) errs=(map uri=@t (list tang)) proc-id=@]
+$  versioned-state
  $%
    state-zero
  ==
--
^-  agent:gall
=|  state-zero
=*  state  -
=<
  |_  =bowl:gall
  +*  this      .
      lsp-core  +>
      lsp       ~(. lsp-core bowl)
      def       ~(. (default-agent this %|) bowl)
  ::
  ++  on-init
    ^+  on-init:*agent:gall
    ^-  (quip card _this)
    ~&  >  %lsp-init
    :_  this  :_  ~
    :*  %pass  /connect
        %arvo  %e
        %connect  [~ /'~language-server-protocol']  %language-server
    ==
  ::
  ++  on-save   !>(state)
  ++  on-load
    ^+  on-load:*agent:gall
    |=  old-state=vase
    ^-  (quip card _this)
    ~&  >  %lsp-upgrade
    [~ this(state *state-zero)]
  ::
  ++  on-poke
    ^+  on-poke:*agent:gall
    |=  [=mark =vase]
    ^-  (quip card _this)
    =^  cards  state
      ?+    mark  (on-poke:def mark vase)
          ::  %handle-http-request
        ::  (handle-http-request:lsp !<([eyre-id=@ta inbound-request:eyre] vase))
          %language-server-rpc-request
        (handle-json-rpc:lsp !<(request-message:lsp-sur vase))
      ==
    [cards this]
  ::
  ++  on-watch
    |=  =path
    ~&  'subscribe on path'
    ?:  ?=([%primary ~] path)
      :_  this
      ~
      ::  (give-rpc-notification:lsp demo-diagnostic:lsp)
    ?.  ?=([%http-response @ ~] path)
      (on-watch:def path)
    `this
  ++  on-leave  on-leave:def
  ++  on-peek   on-peek:def
  ++  on-agent  on-agent:def
  ++  on-arvo
    ^+  on-arvo:*agent:gall
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    =^  cards  state
      ?+  sign-arvo  (on-arvo:def wire sign-arvo)
        [%e %bound *]  `state
        [%f *]  (handle-build:lsp wire +.sign-arvo)
      ==
    [cards this]
  ::
  ++  on-fail   on-fail:def
  --
::
|_  bow=bowl:gall
::
++  parser
  =,  dejs:format
  |^
  %:  ot
    method+so
    :-  %params
    %-  of
    :~  sync+sync
        completion+position
        commit+ni
        hover+position
    ==
    ~
  ==
  ::
  ++  sync
    %-  ar
    %:  ou
      range+(uf ~ (pe ~ range))
      'rangeLength'^(uf ~ (pe ~ ni))
      text+(un so)
      ~
    ==
  ::
  ++  range
    %:  ot
      start+position
      end+position
      ~
    ==
  ::
  ++  position
    %:  ot
      line+ni
      character+ni
      ~
    ==
  --
::
++  json-response
  |=  [eyre-id=@ta jon=json]
  ^-  (list card)
  (give-simple-payload:app eyre-id (json-response:gen (json-to-octs jon)))
::
++  give-rpc-notification
  |=  res=all:response:lsp-sur
  ^-  (list card)
  :_  ~
  [%give %fact `/primary %language-server-rpc-response !>([~ res])]
::
++  handle-json-rpc
  |=  req=request-message:lsp-sur
  ^-  (quip card _state)
  =^  cards  state
    ?+  +<.req  [~ state]
        %text-document--did-open
      (handle-did-open +>.req)
        %text-document--did-change
      (handle-did-change +>.req)
        %text-document--did-save
      (handle-did-save +>.req)
        %text-document--did-close
      (handle-did-close +>.req)
        %exit
      handle-exit
    ==
  [cards state]
::
++  handle-exit
  ^-  (quip card _state)
  ~&  >  %lsp-shutdown
  :_  *state-zero
  %+  turn
    ~(tap in ~(key by builds))
  |=  uri=@t
  [%pass /ford/[uri] %arvo %f %kill ~]
::
++  handle-did-close
  |=  [uri=@t version=@]
  ^-  (quip card _state)
  =.  bufs
    (~(del by bufs) uri)
  =.  errs
    (~(del by errs) uri)
  =.  builds
    (~(del by builds) uri)
  :_  state
  [%pass /ford/[uri] %arvo %f %kill ~]~
::
++  handle-did-save
  |=  [uri=@t version=@]
  ^-  (quip card _state)
  ~&  "Committing"
  :_  state
  :_  (give-rpc-notification (get-parser-diagnostics uri))
  :*
    %pass
    /commit
    %agent
    [our.bow %hood]
    %poke
    %kiln-commit
    !>([q.byk.bow |])
  ==


::
++  handle-did-change
  |=  [document=versioned-doc-id:lsp-sur changes=(list change:lsp-sur)]
  ^-  (quip card _state)
  =/  updated=wall
    (sync-buf (~(got by bufs) uri.document) changes)
  =.  bufs
    (~(put by bufs) uri.document updated)
  `state
::
++  handle-build
  |=  [=path =gift:able:ford]
  ^-  (quip card _state)
  ~&  'Built'
  ?.  ?=([%made *] gift)
    [~ state]
  ?.  ?=([%complete *] result.gift)
    [~ state]
  =/  uri=@t
    (snag 1 path)
  =/  =build-result:ford
    build-result.result.gift
  ?+  build-result  [~ state]
        ::
      [%success %core *]
    =.  builds
      (~(put by builds) uri vase.build-result)
    =.  errs
      (~(del by errs) uri)
    [~ state]
        ::
      [%error *]
    ~&  message.build-result
    =/  error-range=range
      (snag 0 (get-error-from-tang:build message.build-result))
    :_  state
    (give-rpc-notification (get-ford-diagnostics error-range uri))
  ==
::
++  get-ford-diagnostics
  |=  [=range uri=@t]
  ^-  text-document--publish-diagnostics:response:lsp-sur
  :+  %text-document--publish-diagnostics
    uri
  [[range 1 'Build Error'] ~]
::
++  handle-did-open
  |=  item=text-document-item:lsp-sur
  ^-  (quip card _state)
  =.  bufs
    (~(put by bufs) uri.item (to-wall (trip text.item)))
  =/  =path
    (uri-to-path:build uri.item)
  =/  =schematic:ford
    [%core [our.bow %home] (flop path)]
  :_  state
  ^-  (list card)
  :_  (give-rpc-notification (get-parser-diagnostics uri.item))
  ^-  card
  [%pass /ford/[uri.item] %arvo %f %build live=%.y schematic]
::
::  +handle-http-request: received on a new connection established
::
::  ++  handle-http-request
::    |=  [eyre-id=@ta =inbound-request:eyre]
::    ^-  (quip card _state)
::    ?>  ?=(^ body.request.inbound-request)
::    =/  =lsp-req
::      %-  parser
::      (need (de-json:html q.u.body.request.inbound-request))
::    =/  buf  (~(gut by bufs) uri.lsp-req *wall)
::    =^  cards  buf
::      ?+  +<.lsp-req  !!
::        %sync        (handle-sync buf eyre-id +>.lsp-req)
::        ::  %completion  (handle-completion buf eyre-id +>.lsp-req)
::        ::  %commit      (handle-commit buf eyre-id uri.lsp-req)
::        ::  %hover       (handle-hover buf eyre-id +>.lsp-req)
::      ==
::    =.  bufs
::      (~(put by bufs) uri.lsp-req buf)
::    [cards state]
::  ::
++  get-parser-diagnostics
  |=  uri=@t
  ^-  text-document--publish-diagnostics:response:lsp-sur
  =/  t=tape
    (zing (join "\0a" `wall`(~(got by bufs) uri)))
  ::  ~&  t
  =/  parse
    (lily:auto t (lsp-parser *beam))
  ::  ~&  parse
  :+  %text-document--publish-diagnostics
    uri
  ?.  ?=(%| -.parse)
    ~
  =/  loc=position:lsp-sur
    [(dec -.p.parse) +.p.parse]
  :_  ~
  [[loc loc] 1 'Syntax Error']
::
::  ++  handle-commit
::    |=  [buf=wall eyre-id=@ta uri=@t]
::    ^-  [(list card) wall]
::    :_  buf
::    =/  jon
::      (regen-diagnostics buf)
::    :_  (json-response eyre-id jon)
::    :*
::      %pass
::      /commit
::      %agent
::      [our.bow %hood]
::      %poke
::      %kiln-commit
::      !>([q.byk.bow |])
::    ==
::  ::
::  ++  handle-hover
::    |=  [buf=wall eyre-id=@ta row=@ud col=@ud]
::    ^-  [(list card) wall]
::    =/  txt
::      (zing (join "\0a" buf))
::    =+  (get-id:auto (get-pos buf row col) txt)
::    ?~  id
::      [(json-response eyre-id *json) buf]
::    =/  match=(unit (option:auto type))
::      (search-exact:auto u.id (get-identifiers:auto -:!>(..zuse)))
::    ?~  match
::      [(json-response eyre-id *json) buf]
::    =/  contents
::      %-  crip
::      ;:  weld
::        "`"
::        ~(ram re ~(duck easy-print detail.u.match))
::        "`"
::      ==
::    :_  buf
::    %+  json-response  eyre-id
::    %-  pairs:enjs:format
::    [contents+s+contents ~]
::
++  sync-buf
  |=  [buf=wall changes=(list change:lsp-sur)]
  |-  ^-  wall
  ?~  changes
    buf
  ?:  ?|(?=(~ range.i.changes) ?=(~ range-length.i.changes))
    =/  =wain  (to-wain:format text.i.changes)
    =.  buf  (turn wain trip)
    $(changes t.changes)
  =/  =tape      (zing (join "\0a" buf))
  =/  start-pos  (get-pos buf start.u.range.i.changes)
  =/  end-pos    (get-pos buf end.u.range.i.changes)
  =.  tape
    ;:  weld
      (scag start-pos tape)
      (trip text.i.changes)
      (slag end-pos tape)
    ==
  =.  buf  (to-wall tape)
  $(changes t.changes)
::
::  ++  handle-sync
::    |=  [buf=wall eyre-id=@ta changes=(list change)]
::    :-  (json-response eyre-id *json)
::    (sync-buf buf changes)

::
++  to-wall
  |=  =tape
  ^-  wall
  %+  roll  (flop tape)
  |=  [char=@tD =wall]
  ?~  wall
    [[char ~] ~]
  ?:  =('\0a' char)
    [~ wall]
  [[char i.wall] t.wall]
::
++  get-pos
  |=  [buf=wall position]
  ^-  @ud
  ?~  buf
    0
  ?:  =(0 row)
    col
  %+  add  +((lent i.buf))  ::  +1 because newline
  $(row (dec row), buf t.buf)
::
++  safe-sub
  |=  [a=@ b=@]
  ?:  (gth b a)
    0
  (sub a b)
::
::  ++  handle-completion
::    |=  [buf=wall eyre-id=@ta row=@ud col=@ud]
::    ^-  [(list card) wall]
::    =/  =tape  (zing (join "\0a" buf))
::    =/  pos  (get-pos buf row col)
::    :_  buf
::    ::  Check if we're on a rune
::    ::
::    =/  rune  (swag [(safe-sub pos 2) 2] tape)
::    ?:  (~(has by runes:rune-snippet) rune)
::      (json-response eyre-id (rune-snippet rune))
::    ::  Don't run on large files because it's slow
::    ::
::    ?:  (gth (lent buf) 1.000)
::      =,  enjs:format
::      (json-response eyre-id (pairs good+b+& result+~ ~))
::    ::
::    =/  tl
::      (tab-list-tape:auto -:!>(..zuse) pos tape)
::    =,  enjs:format
::    %+  json-response  eyre-id
::    ?:  ?=(%| -.tl)
::      (format-diagnostic p.tl)
::    ?~  p.tl
::      *json
::    %-  pairs
::    :~  good+b+&
::    ::
::        :-  %result
::        %-  pairs
::        :~  'isIncomplete'^b+&
::        ::
::            :-  %items
::            :-  %a
::            =/  lots  (gth (lent u.p.tl) 10)
::            %-  flop
::            %+  turn  (scag 50 u.p.tl)
::            |=  [=term =type]
::            ?:  lots
::              (frond label+s+term)
::            =/  detail  (crip ~(ram re ~(duck easy-print type)))
::            (pairs label+s+term detail+s+detail ~)
::        ==
::    ==
++  demo-diagnostic
  :+  %text-document--publish-diagnostics
    'file:///Users/liamfitzgerald/dev/urbit/urbit-src/pkg/arvo/gen/code.hoon'
  :~
    [[[1 1] [2 2]] 1 'Syntax error']
  ==
--
