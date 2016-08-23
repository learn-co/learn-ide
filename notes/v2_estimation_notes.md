learn ide v2 Estimation Notes
============================

## OS Support?
=============
- Windows 7+


### high level major goals (blocking)

Drew

1. **discuss in meeting, 2-3 weeks posssibly?? path forward murky, needs more time to explore / research** new tree view with better file syncing (remote => client unidirectional flow)
  - local files since 
  - syncing between remote and local


Josh

2. extract learn-ide code from atom core

  - websocket connections (single-socket)

    - **3 days** (certainty: 9/10) - implementing single socket logic

    - **10 days** (certainty: 5/10) - moving socket logic out of atom core into extension package

  - learn open

    - **3 days** (certainty: 8/10) update mac os protocol url for opening in atom:// instead of learn-ide://

  - **2 days** (certainty: 8/10) authentication & setup

  - **5 days** (certainty: 2/10) rewriting packaging scripts for windows/mac/linux
    - rewrite for new package that's not dependent on atom core fork
    - improve installation experience

  - **5 days** QA


minor goals (not blocking and if we have time)
- auto reconnect websocket
  -may increase in importance if websocket is critical for tree view to sync correctly
- log out connection errors to console to aid with debugging (general client debugging tools)
- rm sslv3 support by upgrading websocketd (security vuln brought up by devin)
