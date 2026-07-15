/* REXX - DORMANT                                                     */
/* Scan a RACF group for dormant / never-used user IDs.               */
/* Usage:  DORMANT group days [REVOKE]                                */
/*   group  - RACF group whose members are scanned                    */
/*   days   - inactivity threshold; last logon older than this many   */
/*            days (or never) is flagged                              */
/*   REVOKE - optional; when present, ALTUSER ... REVOKE each flagged  */
/*            ID. Omit for a read-only report.                        */
/* Companion to the dormant-id-cleanup z/OSMF workflow.               */

arg grp days mode .
if grp = '' | days = '' then do
  say 'DORMANT: missing arguments.'
  say 'Usage: DORMANT group days [REVOKE]'
  exit 12
end
if datatype(days,'W') = 0 then do
  say 'DORMANT: days must be a whole number, got:' days
  exit 12
end
revoke  = (mode = 'REVOKE')
baseNow = date('B')

/* ---- collect group members from LISTGRP ------------------------- */
call outtrap 'LG.'
address TSO "LISTGRP" grp
lgrc = rc
call outtrap 'OFF'
if lgrc <> 0 then do
  say 'DORMANT: LISTGRP' grp 'failed rc='lgrc
  exit 12
end
members = ''
inList  = 0
do i = 1 to lg.0
  ln = lg.i
  if pos('USER(S)=', ln) > 0 then do
    inList = 1
    iterate
  end
  if \inList then iterate
  w1 = word(ln,1)
  w2 = word(ln,2)
  if w1 = 'CONNECT' | w1 = 'REVOKE' then iterate
  if wordpos(w2,'USE READ UPDATE CONTROL ALTER NONE') > 0 then,
    members = members w1
end
members = strip(members)
nmem = words(members)

/* ---- evaluate each member --------------------------------------- */
nDormant = 0; nNever = 0; nRevoked = 0; nActive = 0
flagged  = ''
say 'Dormant ID scan for group' grp '- threshold' days 'days'
say copies('-',60)
do i = 1 to nmem
  u = word(members,i)
  call outtrap 'LU.'
  address TSO "LISTUSER" u
  call outtrap 'OFF'
  isRevoked = 0
  lacc = ''
  do j = 1 to lu.0
    if pos('REVOKED', lu.j) > 0 then isRevoked = 1
    p = pos('LAST-ACCESS=', lu.j)
    if p > 0 then lacc = word(substr(lu.j, p+12),1)
  end
  if isRevoked then do
    say left(u,8) 'ALREADY-REVOKED'
    nRevoked = nRevoked + 1
    iterate
  end
  if lacc = '' | lacc = 'UNKNOWN' then do
    say left(u,8) 'NEVER-USED'
    nNever = nNever + 1
    flagged = flagged u
    iterate
  end
  parse var lacc yy '.' ddd '/' .
  if datatype(yy,'W') = 0 | datatype(ddd,'W') = 0 then do
    say left(u,8) 'DATE-PARSE-ERROR' lacc
    iterate
  end
  if yy <= 70 then yyyy = 2000 + yy
              else yyyy = 1900 + yy
  baseJan1 = date('B', right(yyyy,4,'0')'0101', 'S')
  baseLast = baseJan1 + (ddd - 1)
  ago = baseNow - baseLast
  if ago > days then do
    say left(u,8) 'DORMANT' ago 'days'
    nDormant = nDormant + 1
    flagged  = flagged u
  end
  else do
    say left(u,8) 'ACTIVE' ago 'days'
    nActive = nActive + 1
  end
end
flagged = strip(flagged)
say copies('-',60)
say 'Active:' nActive '  Dormant:' nDormant '  Never-used:' nNever,
    '  Already-revoked:' nRevoked
say 'Total members:' nmem

if \revoke then exit 0

/* ---- REVOKE mode ------------------------------------------------ */
say ' '
say 'Revoking flagged IDs in group' grp '...'
nRev = 0; nFail = 0
do i = 1 to words(flagged)
  u = word(flagged,i)
  address TSO "ALTUSER" u "REVOKE"
  if rc = 0 then do
    say left(u,8) 'REVOKED'
    nRev = nRev + 1
  end
  else do
    say left(u,8) 'REVOKE-FAILED rc='rc
    nFail = nFail + 1
  end
end
say 'Revoked this run:' nRev
say 'Failed:' nFail
if nFail > 0 then exit 8
exit 0
