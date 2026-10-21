
# Klimmeck-Guide
A game type app, integrated with Telegram and Discord, to let players interact during live streams


## Notifiche push (sviluppo locale)

Il push usa Firebase Cloud Messaging (solo Android in questa fase). Per riceverle in locale:

1. Scarica `google-services.json` dalla console Firebase del progetto condiviso con il backend (app Android `it.lordreavor.klimmeckguide.klimmeck_guide`).
2. Copialo in `android/app/google-services.json`. Il file è in `.gitignore`: non committarlo mai.
3. Il backend deve avere `FIREBASE_SERVICE_ACCOUNT` dello stesso progetto.

Senza il file la build passa con un warning del plugin Google Services e l'app parte con il push disabilitato (log `Push disabled: Firebase unavailable`).

## License

This project is distributed under a custom **proprietary license**.  
Use of the code is allowed only under specific conditions.  
See [LICENSE.txt](./LICENSE.txt) for full terms.

© 2025 Luca Tabbia (LordReavor). All rights reserved.