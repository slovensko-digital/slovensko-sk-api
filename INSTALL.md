**Inštalačná príručka popisuje komponent verzie [2.1.1](https://github.com/slovensko-digital/slovensko-sk-api/releases/tag/v2.1.1), uistite sa, že čítate príručku [verzie komponentu](https://github.com/slovensko-digital/slovensko-sk-api/releases), ktorý používate.**

# slovensko.sk API - Inštalačná príručka

Máme dobrú a zlú správu. Tá zlá správa je, že na zfunkčnenie tohto komponentu (alebo akejkoľvek inej integrácie na slovensko.sk) je nutné prejsť pomerne náročný proces s NASES a vypracovať množstvo dokumentácie. Tá dobrá správa je, že sme to skoro celé spravili za Vás a tento návod by mal úplne stačiť na to, aby ste komponent dostali do produkčnej prevádzky. Ak sa Vám to zdá zložité, ozvite sa nám emailom na ekosystem@slovensko.digital a radi pomôžeme.

## Postup spustenia API komponentu 

Komponent slovensko.sk API je distribuovaný ako Docker [kontajner](https://ghcr.io/slovensko-digital/slovensko-sk-api), ktorý sa spúšťa štandardne, najľahšie cez `docker-compose`.

Pred prvým spustením je potrebné pripraviť si adresár, ktorý bude obsahovať:
 
- [docker-compose.yml](doc/templates/docker-compose.yml) upravený podľa potreby,
- [.env](doc/templates/.env) s doplnenými hodnotami [premenných prostredia](#premenné-prostredia) podľa potreby,
- všetky [bezpečnostné súbory](#bezpečnostné-súbory), ktoré komponent požaduje podľa upraveného `.env` súboru.

Pričom:

- **ak potrebujete automatickú synchronizáciu eForm formulárov**, musíte do súboru `docker-compose.yml` pridať služby `clock` a `worker` tak, ako je to v tomto [docker-compose.yml](doc/templates/docker-compose.with_eform_sync.yml) súbore, 
- **ak potrebujete podporu pre autentifikáciu cez ÚPVS SSO**, musíte do súboru`.env` pridať ďaľšie premenné tak, ako je to v tomto [.env](doc/templates/.env.with_upvs_sso) súbore.

Pozri časť [Konfigurácia API komponentu](#konfigurácia-api-komponentu).

Najskôr je potrebné inicializovať databázu cez:

    docker-compose run web bundle exec rails db:create db:migrate

Potom je možné spustiť komponent:

    docker-compose up

Komponent by mal bežať na porte 3000, stav je možné skontrolovať pomocou: 

    curl localhost:3000/health

Možnosti komponentu popisuje [Špecifikácia API](https://generator.swagger.io/index.html?url=https://slovensko-sk-api.ekosystem.slovensko.digital/openapi.yaml).

Log komponentu ide na štandardný výstup.

## Postup aktualizovania API komponentu 

Najskôr je potrebné stiahnuť nový komponent:

    docker-compose pull

Následne je možné komponent reštartovať:

    docker-compose stop
    docker-compose up --force-recreate

Na rozdiel od `docker-compose restart` toto reflektuje aj zmeny v rámci súboru `docker-compose.yml`. 

## Postup volania API komponentu

Ukážka odoslania SKTalk správy a uloženia medzi odoslané správy v schránke

    curl -H 'Authorization: Bearer API-TOKEN' -H 'Content-Type: application/json' -d '{ "message": SKTALK-MESSAGE }' localhost:3000/api/sktalk/receive_and_save_to_outbox

kde `API-TOKEN` je [JWT](https://jwt.io) vytvorený podľa [Špecifikácie API](https://generator.swagger.io/index.html?url=https://slovensko-sk-api.ekosystem.slovensko.digital/openapi.yaml) a `SKTALK-MESSAGE` je valídna SKTalk správa s unikátnym `MessageID` (prípadne aj `CorrelationID`) a správne nastaveným `SenderId` a `RecipientId`.

V prípade potreby je možné vyskúšať komponet prevádzkovaný na strane Slovensko.Digital v DEV a FIX prostrediach: 

- komponent v **DEV prostredí** je dostupný na URL

      https://dev.slovensko-sk-api.staging.slovensko.digital

  pozri aktuálny [stav komponentu](https://dev.slovensko-sk-api.staging.slovensko.digital/health) a [špecifikáciu API](https://generator.swagger.io/index.html?url=https://dev.slovensko-sk-api.staging.slovensko.digital/openapi.yaml) nasadenej verzie. 

- komponent vo **FIX prostredí** je dostupný na URL

      https://fix.slovensko-sk-api.staging.slovensko.digital

  pozri aktuálny [stav komponentu](https://fix.slovensko-sk-api.staging.slovensko.digital/health) a [špecifikáciu API](https://generator.swagger.io/index.html?url=https://fix.slovensko-sk-api.staging.slovensko.digital/openapi.yaml) nasadenej verzie.

- komponenty v **DEV a FIX prostredí** majú rovnaký privátny kľúč pre generovanie API tokenov a rovnaký verejný kľúč pre verifikáciu OBO tokenov, ale majú rôzne PO a OVM identity, [kontaktujte nás](mailto:ekosystem@slovensko.digital).

## Konfigurácia API komponentu

Zoznam premenných prostredia a bezpečnostných súborov potrebných pre spustenie komponentu.

#### Premenné prostredia: 

Premenná | Popis | Hodnota
--- | --- | ---
`RAILS_ENV` | Prostredie Rails aplikácie<sup>1</sup> | `development` (predvolená), `test`, `staging` alebo `production`
`RAILS_CACHE_ID` | Identifikátor Rails Cache<sup>1</sup> | jedinečný identifikátor (potrebná iba v prostredí kde beží viacero komponentov)
`LOG_LEVEL` | Úroveň logovania Rails aplikácie<sup>2</sup> | `debug` (predvolená), `info`, `warn`, `error` alebo `fatal`
`SECRET_KEY_BASE` | Kľúč zabezpečenia Rails aplikácie<sup>5</sup> | bezpečný reťazec
`TIME_ZONE` | Časové pásmo Rails aplikácie | `Europe/Bratislava` (predvolená) alebo `UTC` a pod.
`UPVS_ENV` | Prostredie ÚPVS<sup>2</sup> | `dev` (predvolená), `fix` alebo `prod`
`UPVS_LOG_LEVEL` | Úroveň logovania ÚPVS komunikácie<sup>3</sup> | `trace`, `debug`, `info` (predvolená), `warn`, `error` alebo `off` (predvolená ak `RAILS_ENV=test` alebo `UPVS_ENV=prod`)
`UPVS_KS_SALT` | Soľ hesla k úložisku certifikátov<sup>6</sup> | bezpečný reťazec (potrebná iba ak `UPVS_ENV=prod`)
`UPVS_PK_SALT` | Soľ hesla k privátnemu kľúču v úložisku certifikátov<sup>6</sup> | bezpečný reťazec (potrebná iba ak `UPVS_ENV=prod`)
`EFORM_SYNC_SUBJECT` | Subjekt ukazujúci na STS certifikát pre automatickú synchronizáciu eForm formulárov<sup>7</sup> | `{sub}` (potrebná iba pre eForm Sync)
`SSO_SP_SUBJECT` | Subjekt ukazujúci na SP certifikát pre podpisovanie pri autentifikácii cez ÚPVS SSO<sup>8</sup> | `{sub}` (potrebná iba pre ÚPVS SSO)
`SSO_PROXY_SUBJECT` | Subjekt ukazujúci na STS certifikát pre OBO prístup pri autentifikácii cez ÚPVS SSO | `{sub}` (potrebná iba pre ÚPVS SSO)
`LOGIN_CALLBACK_URLS` | Základné URL oddelené čiarkou, na ktoré može byť používateľ presmerovaný po úspešnom prihlásení | bezpečná URL (potrebná iba pre ÚPVS SSO)
`LOGOUT_CALLBACK_URLS` | Základné URL oddelené čiarkou, na ktoré može byť používateľ presmerovaný po úspešnom odhlásení | bezpečná URL (potrebná iba pre ÚPVS SSO)
`STS_HEALTH_SUBJECT` | Subjekt ukazujúci na STS certifikát pre kontrolu spojenia s ÚPVS STS | `{sub}` (potrebná iba pre STS Health)

<sup>1</sup> [Rails Environment Settings](https://guides.rubyonrails.org/configuring.html#rails-environment-settings)  
<sup>2</sup> Integračný manuál ÚPVS IAM, pozri časť [1.](#1-zriadenie-prístupu-k-dokumentácii-úpvs)  
<sup>3</sup> [Debugging Rails Applications](https://guides.rubyonrails.org/debugging_rails_applications.html#log-levels)  
<sup>4</sup> [Logback Architecture](http://logback.qos.ch/manual/architecture.html)  
<sup>5</sup> Reťazec vygenerovaný príkazom `rails secret`  
<sup>6</sup> Reťazec dlhý aspoň 40 znakov  
<sup>7</sup> Nastavenie premennej zapína automatickú synchronizáciu eForm formulárov  
<sup>8</sup> Nastavenie premennej zapína podporu pre autentifikáciu cez ÚPVS SSO  

#### Bezpečnostné súbory:

Súbor | Popis | Podpora ÚPVS SSO vypnutá
--- | --- | ---
`security/api_token_{RAILS_ENV}.public.pem` | Verejný kľúč pre verifikáciu API tokenov<sup>1</sup> |
`security/obo_token_{RAILS_ENV}.private.pem` | Privátny a verejný kľúč pre generovanie a verifikáciu OBO tokenov<sup>2</sup> | Nepotrebný
`security/sso/upvs_{UPVS_ENV}.metadata.xml` | Metadáta IDP<sup>3</sup> | Nepotrebný
`security/sso/{SSO_SP_SUBJECT}_{UPVS_ENV}.metadata.xml` | Metadáta SP<sup>3</sup> | Nepotrebný
`security/sso/{SSO_SP_SUBJECT}_{UPVS_ENV}.keystore` | Úložisko SP certifikátu pre podpisovanie<sup>5,6</sup> | Nepotrebný
`security/sts/{SSO_PROXY_SUBJECT}_{UPVS_ENV}.keystore` | Úložisko STS certifikátu pre OBO prístup<sup>5,6</sup> | Nepotrebný
`security/sts/{sub}_{UPVS_ENV}.keystore` | Úložisko STS certifikátu<sup>4,5,6</sup> |
`security/tls/upvs_{UPVS_ENV}.truststore` | Úložisko TLS certifikátov<sup>7,8</sup> |

<sup>1</sup> Kľúč vygenerovaný príkazom `openssl genrsa -out api_token_development.private.pem 2048` a `openssl rsa -in api_token_development.private.pem -pubout -out api_token_development.public.pem`  
<sup>2</sup> Kľúč vygenerovaný príkazom `openssl genrsa -out obo_token_development.private.pem 2048`  
<sup>3</sup> Metadáta IDP / SP musia byť zaregistrované v prostredí ÚPVS, pozri časť [6.](#3-vytvorenie-identít-a-zriadenie-prístupov-do-dev-prostredia)  
<sup>4</sup> Hodnota SUB claim z API tokenu nahrádza výraz `{sub}` v názve súboru  
<sup>5</sup> Certifikát v úložisku musí byť zaregistrovaný v prostredí ÚPVS, pozri časť [6.](#3-vytvorenie-identít-a-zriadenie-prístupov-do-dev-prostredia)  
<sup>6</sup> Heslo k úložisku a heslo k privátnemu kľúču v prostredí ÚPVS DEV a FIX je `password`. Pozor, tieto heslá v prostredí ÚPVS PROD sú SHA1 podľa vzorov `{UPVS_KS_SALT}:{sub}` (pre heslo k úložisku) a `{UPVS_PK_SALT}:{sub}` (pre heslo k privátnemu kľúču) v hexadecimálnom formáte  
<sup>7</sup> Certifikát v úložisku pre prostredie ÚPVS DEV sa dá získať napr. cez `echo | openssl s_client -servername 'vyvoj.upvs.globaltel.sk' -connect 'vyvoj.upvs.globaltel.sk:443' | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > upvs_dev.crt`  
<sup>8</sup> Heslo k úložisku v prostredí ÚPVS DEV, FIX a PROD je `password`  

## Postup zriadenia integrácie na slovensko.sk (Ústredný portál verejnej správy – ÚPVS)

### 1. Zriadenie prístupu k dokumentácii ÚPVS

Na [stránke NASES](https://www.nases.gov.sk/sluzby/usmernenie-k-integracii/index.html) nájdete formulár na prístup k aktuálnej dokumentácii ÚPVS. Odporúčame si prístup zriadiť, kedže sa na [partner framework portáli](https://kp.gov.sk/pf/default.aspx), okrem dokumentácie, nachádzajú aj informácie o plánovaných odstávkach a ďalšom rozvoji ÚPVS.

### 2. Zaslanie a podpis dohody o integračnom zámere (DIZ)

Je potrebné si zvoliť skratku projektu, ktorá sa bude používať pre účely komunikácie s NASES. Názov môže obsahovať len veľké písmená, bez diakritiky a medzier, a musí byť unikátny. My sme napríklad použili názov PODAAS, ten je už obsadený.

Stiahnite si šablónu dohody o integračnom zámere z [partner framework portálu](https://kp.gov.sk/pf/default.aspx) a upravte podľa potreby. **Pozor**, treba sa uistiť, že používate **aktuálnu šablónu** NASES, pretože tie sa v čase menia.

Tento dokument následne premenujte na `DIZ_PO_{project}_v1.docx`, kde reťazec `{project}` nahraďte skratkou Vášho projektu a priložte ako prílohu k emailu:

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
>
> Predmet: **{project}** – DEV – DIZ – Požiadavka – Revízia dohody o integračnom zámere – TYP PO – v1
>
> Dobrý deň,
>
> týmto zasielam na revíziu DIZ nového projektu.
> 
> Prosím o potvrdenie, že žiadosť ste zaevidovali.
> 
> Ďakujem.

Po schválení DIZ je potrebné DIZ vytlačiť 4x, podpísať a zaslať poštou (alebo osobne doručiť) do NASES na adresu:

Národná agentúra pre sieťové a elektronické služby
BC Omnipolis
Trnavská cesta 100/II
821 01 Bratislava

### 3. Vytvorenie identít a zriadenie prístupov do DEV prostredia

TODO

### 4. Žiadosť o vytvorenie infraštruktúrneho prepojenia

Požiadajte o vytvorenie infraštruktúrneho prepojenia emailom:

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
> 
> Predmet: **{project}** - FIX/PROD - INFRA - Požiadavka - Pridelenie adresného rozsahu
> 
> Dobrý deň,
> 
> týmto žiadam o pridelenie adresného rozsahu pre tunel do FIX/PROD prostredia a zaslanie potrebného XLS pre špecifikáciu komunikácie.
>
> Ďakujem.

NASES Vám zašle naspäť XLS dokument, ktorý bude treba doplniť nasledovne:

1. V prvej záložke *Základné údaje* nájdete `Pridelený koordinovaný rozsah pre služby v tuneloch ES:` napríklad `100.66.0.128/28`. Od tohto rozsahu sa odvíjajú nasledujúce nastavenia.
2. V prvej záložke vyplňte potrebné kontaktné údaje pre externý subjekt (to ste Vy)
3. V tretej záložke *Integračné a aplikačné endpointy* vyplňte všetky riadky stĺpca `Rozhranie ES TunelIP` tak, že pre FIX prostredie uvediete piatu adresu rozsahu (t.j. pre rozsah `100.66.0.128/28` to bude `100.66.0.128 + 5` = `100.66.0.133`) a pre PROD prostredie desiatu adresu rozsahu `100.55.0.128 + 10` = `100.66.0.138`. 
4. V tretej záložke *Integračné a aplikačné endpointy* následne označte červeným pozadím riadky s rozhraním `IAM-WS - 1.7, 2.0` toto sa nepoužíva, ostatné riadky označte zeleným pozadím. Teda: `schranka - EKR`, `UIR (URP, URZ - BPM)`, `USR (SB-Ext. Zbernica)` aj `IAM-STS.` 
5. V štvrtej záložke *GUI Endpointy Test-Fix* povoľte prístup z internetu cez GUI pre Portal 1.7, 2.0, Prihlasenie IAM, Formulare, eFormulare, schranka - eDesk 1.7, 2.0. 
6. V štvrtej záložke *GUI Endpointy Test-Fix* do `IP GW ES pre povolenie pristupu ku GUI rozhraniam:` uveďte verejnú IP adresu stroja, cez ktorý sa pristupovať k portálu pre účely testovania.
7. V piatej záložke *DNS* uveďte ako `IP ES Site` pre FIX tretiu adresu rozsahu (t.j. pre rozsah `100.66.0.128/28` to bude `100.66.0.128 + 3` = `100.66.0.131`) a pre PROD štvrtú adresu rozsahu (t.j. pre rozsah `100.66.0.128/28` to bude `100.66.0.128 + 4` = `100.66.0.132`)  
8. V záložke *IPsec LAN to LAN* uveďte do `Remote VPN gateway IP address ( ES site )` verejnú IP adresu stroja, kde bude bežať tento komponent (resp. koniec IPsec tunela)

Doplnený XLS dokument priložte ako prílohu k emailu:

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
> 
> Predmet:  **{project}** - FIX/PROD - INFRA - Požiadavka - Vytvorenie infraštruktúrneho prepojenia
> 
> Dobrý deň,
> 
> týmto žiadam o zriadenie tunela do FIX/PROD prostredia. Vyplnenú konfiguráciu posielam v prílohe.
>
> Ďakujem.

### 5. Vytvorenie infraštruktúrneho prepojenia

TODO

### 6. Vytvorenie identít a zriadenie prístupov do FIX prostredia

Požiadajte o vytvorenie identít emailom:

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
>
> Predmet: **{project}** - FIX - IAM - Žiadosť - Zriadenie identít a zastupovanie
> 
> Dobrý deň,
> 
> týmto žiadam zriadenie testovacích identít 4x FO, 2x PO a 2x OVM a zároveň nastavenie splnomocnenia, kde prvé dve FO budú zastupovať PO a druhé dve FO budú zastupovať OVM.
> 
> Ďakujem.

Pre vytvorené identity vygenerujte STS certifikáty. Reťazec `{sub}` v názvoch súborov a aliasoch nahraďte vhodnou skratkou Vašej integrácie, podobne upravte hodnotu CN certifikátov, kde `{cin}` je IČO a `{suffix}` je identifikačné číslo organizácie v prípade ak ide o organizačnú zložku.  

    keytool -genkeypair -alias {sub} -keyalg RSA -keysize 2048 -sigalg sha512WithRSA -dname "CN=ico-{cin}_{suffix}" -validity 730 -keypass password -keystore {sub}_fix.keystore -storepass password
    keytool -export -alias {sub} -keystore {sub}_fix.keystore -storepass password > {sub}_fix.crt
    keytool -export -alias {sub} -keystore {sub}_fix.keystore -storepass password -rfc > {sub}_fix.pem

Vygenerované certifikáty je následne potrebné zaregistrovať vyplnením formuláru *Zriadenie technického účtu a registrácia certifikátu* v časti [*Môj profil – Technické účty a certifikáty*](https://portal.upvsfixnew.gov.sk/sk/moj-profil/technicke-ucty-a-certifikaty), ktorý je dostupný po prihlásení testovacej identity (FO) na [ÚPVS portál](https://portal.upvsfixnew.gov.sk) v zastúpení testovacej identity (PO alebo OVM), pre ktorú bude registrácia príslušného certifikátu vykonávaná, pozri [Návod na využívanie služieb centrálneho registra autentifikačných certifikátov](https://www.slovensko.sk/_img/CMS4/Navody/navod_autentifikacne_certifikaty.pdf).

#### CEP

Ak potrebujete podporu pre podpisovanie podaní, požiadajte o pridelenie testovacieho KSC emailom: 

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
>
> Predmet: **{project}** - FIX - CEP - Žiadosť - Pridelenie testovacieho KSC
> 
> Dobrý deň,
>
> týmto žiadam o pridelenie testovacieho KSC pre PO s IČO {cin}.
> 
> Ďakujem.

#### ÚPVS SSO

Ak potrebujete podporu pre autentifikáciu cez ÚPVS SSO, podobne vygenerujte SP certifikáty pre šifrovanie a podpisovanie, certifikát určený pre šifrovanie sa musí odlišovať od certifikátu určeného pre podpisovanie. Následne vytvorte `{sub}_fix.metadata.xml` podľa súboru [podaas_dev.metadata.xml](doc/templates/podaas_dev.metadata.xml), kde `{sub}` bude hodnota `SSO_SP_SUBJECT`, pričom treba nahradiť `entityID`, verejné klúče pre šifrovanie a podpisovanie (skopírovaním z PEM súborov) a endpointy, kde bude **testovacia** verzia bežať.

Vygenerované metadáta je následne potrebné zaregistrovať vyplnením formuláru *Registrácia poskytovateľa služieb* v časti [*Môj profil – Technické účty a certifikáty*](https://portal.upvsfixnew.gov.sk/sk/moj-profil/technicke-ucty-a-certifikaty), ktorý je dostupný po prihlásení testovacej identity (FO) na [ÚPVS portál](https://portal.upvsfixnew.gov.sk) v zastúpení testovacej identity (PO alebo OVM), pre ktorú bude registrácia príslušných metadát vykonávaná, pozri [Návod na využívanie služieb centrálneho registra SP metadát](https://www.slovensko.sk/_img/CMS4/Navody/navod_poskytovatelia_sluzieb.pdf).

### 7. Vykonanie akceptačného testovania (UAT) vo FIX prostredí

Stiahnite si šablónu akceptačného protokolu z [partner framework portálu](https://kp.gov.sk/pf/default.aspx) a upravte podľa potreby. **Pozor**, treba sa uistiť, že používate **aktuálnu šablónu** NASES, pretože tie sa v čase menia.

TODO

### 8. Zriadenie prístupov do PROD prostredia

TODO

### 9. Vykonanie akceptačného testovania (UAT) v PROD prostredí

Ak potrebujete podporu pre autentifikáciu cez ÚPVS SSO, budete vyzvaní na vykonanie UAT aj v PROD prostredí.  

TODO
