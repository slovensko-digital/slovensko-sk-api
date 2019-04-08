# slovensko.sk API - inštalačná príručka

Máme dobrú a zlú správu. Tá zlá správa je, že na zfunkčnenie tohto komponentu (alebo akejkoľvek inej integrácie na slovensko.sk) je nutné prejsť pomerne náročný proces s NASES a vypracovať množstvo dokumentácie. Tá dobrá správa je, že sme to skoro celé spravili za Vás a tento návod by mal úplne stačiť na to, aby ste komponent dostali do produkčnej prevádzky. Ak sa Vám to zdá zložité, ozvite sa nám emailom na `ekosystem@slovensko.digital` a radi pomôžeme.

## Postup spustenia API komponentu 

Komponent `slovensko-sk-api` je distribuovaný ako Docker [kontajner](https://hub.docker.com/r/skdigital/slovensko-sk-api), ktorý sa spúšťa štandardne, najľahšie cez `docker-compose`.

Pred prvým spustením je potrebné pripraviť si adresár, ktorý bude obsahovať:
 
- [docker-compose.yml](doc/templates/docker-compose.yml) upravený podľa potreby,
- [.env](doc/templates/.env) s doplnenými hodnotami premenných podľa potreby,
- všetky súbory, na ktoré ukazujú premenné podľa upraveného `.env` súboru.

**Ak nepotrebujete automatickú synchronizáciau eForm formulárov**, môžete z `docker-compose.yml` odstrániť služby `clock` a `worker` tak, ako je to v tomto [docker-compose.yml](doc/templates/docker-compose.without-eform-sync.yml) súbore. 

**Ak je podpora autentifikácie cez ÚPVS SSO vypnutá**, niektoré premenné môžu byť z `.env` vynechané tak, ako je to v tomto [.env](doc/templates/.env.without-upvs-sso-support) súbore. Zoznam všetkých možných premenných: 

Premenná | Popis | Príklad | Podpora ÚPVS SSO vypnutá
--- | --- | --- | ---
`RAILS_ENV` | Prostredie Rails aplikácie | štandardne `production` |
`SECRET_KEY_BASE` | Kľúč pre zabezpečenie Rails aplikácie<sup>1</sup> | reťazec vygenerovaný cez `rails secret` | 
`LOGIN_CALLBACK_URLS` | Prefixy adries oddelené čiarkou, na ktoré može byť používateľ presmerovaný po úspešnom prihlásení | `http://localhost:3000` | Nepotrebná 
`LOGOUT_CALLBACK_URLS` | Prefixy adries oddelené čiarkou, na ktoré može byť používateľ presmerovaný po úspešnom odhlásení | `http://localhost:3000` | Nepotrebná
`API_TOKEN_PUBLIC_KEY_FILE` | Cesta k verejnému kľúču pre verifikáciu API tokenov<sup>2</sup> | `security/api-token.public.pem` |  
`OBO_TOKEN_PRIVATE_KEY_FILE` | Cesta k privátnemu a verejnému kľúču pre generovanie a verifikáciu OBO tokenov<sup>3</sup> | `security/obo-token.private.pem` | Nepotrebná  
`EFORM_SYNC` | Automatická synchronizácia eForm formulárov | `true` alebo `false` | 
`UPVS_ENV` | Prostredie ÚPVS | `dev`, `fix` alebo `prod` |   
`UPVS_SSO_SUPPORT` | Podpora autentifikácie cez ÚPVS SSO | `true` alebo `false` | 
`UPVS_IDP_METADATA_FILE` | Cesta k IDP metadátam<sup>4</sup> | `security/upvs-fix-idp.metadata.xml` | Nepotrebná
`UPVS_SP_METADATA_FILE` | Cesta k SP metadátam<sup>4</sup> | `security/podaas-fix-sp.metadata.xml` | Nepotrebná
`UPVS_SP_KS_FILE` | Cesta k úložisku SP certifikátu<sup>4</sup> | `security/podaas-fix-sp.keystore` | Nepotrebná
`UPVS_SP_KS_ALIAS` | Názov záznamu SP certifikátu v úložisku | `podaassp` | Nepotrebná
`UPVS_SP_KS_PASSWORD` | Heslo k úložisku SP certifikátu | `password` | Nepotrebná
`UPVS_SP_KS_PRIVATE_PASSWORD` | Heslo k SP privátnemu kľúču | `password` | Nepotrebná
`UPVS_STS_KS_FILE` | Cesta k úložisku STS certifikátu<sup>4</sup> | `security/podaas-fix-sts.keystore` | 
`UPVS_STS_KS_ALIAS` | Názov záznamu STS certifikátu v úložisku | `podaassts` |
`UPVS_STS_KS_PASSWORD` | Heslo k úložisku STS certifikátu | `password` |
`UPVS_STS_KS_PRIVATE_PASSWORD` | Heslo k STS privátnemu kľúču | `password` |
`UPVS_TLS_TS_FILE` | Cesta k úložisku TLS certifikátov<sup>4</sup> | `upvs-fix.truststore` |
`UPVS_TLS_TS_PASSWORD` | Heslo k úložisku TLS certifikátov | `password` |

<sup>1</sup> Pozri [Securing Rails Applications](https://guides.rubyonrails.org/security.html) časť [Encrypted Session Storage](https://guides.rubyonrails.org/security.html#encrypted-session-storage).<br/>
<sup>2</sup> Súbor vygenerovaný napr. pomocou `openssl genrsa -out api-token.private.pem 2048` a `openssl rsa -in api-token.private.pem -pubout -out api-token.public.pem`.<br/>
<sup>3</sup> Súbor vygenerovaný napr. pomocou `openssl genrsa -out obo-token.private.pem 2048`.<br/>
<sup>4</sup> Pozri časť [*6. Zriadenie prístupov do FIX prostredia*](#6-zriadenie-prstupov-do-fix-prostredia).

Ďalej je potrebné inicializovať databázu cez:

    docker-compose run web rails db:create db:migrate

Následne je vhodné vykonať testy pomocou:

- ak je podpora ÚPVS SSO zapnutá:

      docker-compose run web rspec 

- ak je podpora ÚPVS SSO vypnutá:

      docker-compose run web rspec -t ~sso:true

- pričom pridanie `-t ~upvs` vynechá testy, ktoré používajú živé spojenie s ÚPVS DEV prostredím.
 
Potom je možné spustiť komponent:

    docker-compose up

Aplikácia by mala bežať na porte 3000 pričom jej stav je možné skontrolovať pomocou: 

    curl 'http://localhost:3000/health'

Vykonávanie pravidelných úloh v rámci aplikácie je možné skontrolovať pomocou:

    curl 'http://localhost:3000/health?check=heartbeats'

Spojenie aplikácie s ÚPVS je možné skontrolovať pomocou: 

    curl 'http://localhost:3000/health?check=upvs'

Log aplikácie ide na štandardný výstup.

## Postup zriadenia integrácie na slovensko.sk - Ústredný portál verejnej správy (ÚPVS)

### 1. Zriadenie prístupu k dokumentácii ÚPVS

Na [stránke NASES](https://www.nases.gov.sk/sluzby/usmernenie-k-integracii/index.html) nájdete formulár na prístup k aktuálnej dokumentácii ÚPVS. Odporúčame si prístup zriadiť, kedže sa na portáli, okrem dokumentácie, nachádzajú aj informácie o plánovaných odstávkach a ďalšom rozvoji ÚPVS.

### 2. Zaslanie Dohody o integračnom zámere DIZ 

Je potrebné si zvoliť skratku projektu, ktorá sa bude používať pre účely komunikácie s NASES. Názov môže obsahovať len veľké písmená, bez diakritiky a medzier, a musí byť unikátny. My sme napríklad použili názov PODAAS, ten je už obsadený.

Stiahnite si [šablónu dohody o integračnom zámere](doc/templates/DIZ_PO_TEMPLATE__UPVS_v1.docx) a upravte podľa pokynov v komentároch. Pozor, treba sa uistiť, že používate **aktuálnu šablónu** NASES, pretože tie sa v čase menia.

Tento dokument následne premenujte na `DIZ_PO_<skratka projektu>__UPVS_v1.docx`, kde `<skratka projektu>` nahraďte skratkou Vášho projektu a priložte ako prílohu k emailu:

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
>
> Predmet: **&lt;skratka projektu&gt;** – DEV – DIZ – Požiadavka – Revízia dohody o integračnom zámere – TYP PO – v1.0
>
> Dobrý deň,
>
> týmto zasielam na revíziu DIZ nového projektu. Ide o identický DIZ ako v projekte PODAAS, ktorý uz bol schválený, zmenené boli len integrujúce sa strany a harmonogram.
> 
> Prosím o potvrdenie, že žiadosť ste zaevidovali.
> 
> Ďakujem.

### 3. Podpis DIZ

Po schválení DIZ je potrebné DIZ vytlačiť 4x, podpísať a zaslať poštou (alebo osobne doručiť) do NASES na adresu:

BC Omnipolis  
Trnavská cesta 100/II  
821 01 BRATISLAVA

### 4. Žiadosť o vytvorenie infraštruktúrneho prepojenia

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
> 
> Predmet: **&lt;skratka projektu&gt;** - FIX/PROD - INFRA - Požiadavka - Pridelenie adresného rozsahu
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

XLS zašlite ako prílohu k emailu:

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
> 
> Predmet:  **&lt;skratka projektu&gt;** - FIX/PROD - INFRA - Požiadavka - Vytvorenie infraštruktúrneho prepojenia
> 
> Dobrý deň,
> 
> týmto žiadam o zriadenie tunela do FIX/PROD prostredia. Vyplnenú konfiguráciu posielam v prílohe.
>
> Ďakujem.

### 5. Vytvorenie infraštruktúrneho prepojenia

TODO

### 6. Zriadenie prístupov do FIX prostredia

Vygenerujte certifikáty. Reťazec `podaas` v názvoch súborov, aliasoch a CN certifikátov nahraďte skratkou Vašej integrácie, podobne nahraďte reťazec `podaas.slovensko.digital` v CN certifikátov.  

    keytool -genkeypair -alias podaassts --keyalg RSA --keysize 2048 --sigalg sha512WithRSA -validity 730 -keypass password -keystore podaas-fix-sts.keystore -storepass password -dname "CN=tech.podaas.upvsfix.ext.podaas.slovensko.digital"
    
    keytool -export -keystore podaas-fix-sts.keystore -alias podaassts -storepass password > podaas-fix-sts.crt
    
    keytool -genkeypair -alias podaassp --keyalg RSA --keysize 2048 --sigalg sha512WithRSA -validity 730 -keypass password -keystore podaas-fix-sp.keystore -storepass password -dname "CN=sp.podaas.upvsfix.ext.podaas.slovensko.digital"
    
    keytool -export -keystore podaas-fix-sp.keystore -alias podaassp -storepass password > podaas-fix-sp.crt
    
    keytool -export -keystore podaas-fix-sp.keystore -alias podaassp -storepass password -rfc > podaas-fix-sp.pem

Vytvorte `podaas-fix-sp.metadata.xml` zo súboru [podaas-sp.metadata.xml](doc/templates/podaas-sp.metadata.xml). Treba nahradniť `entityID`, dva verejné klúče (skopírovaním z `podaas-fix-sp.pem`) a endpointy, kde bude **testovacia** verzia bežať. Metadáta podpíšte pomocou [xmlsectool](http://shibboleth.net/downloads/tools/xmlsectool/latest).

    xmlsectool --sign --inFile podaas-fix-sp.metadata.xml --outFile podaas-fix-sp.signed.metadata.xml --keystore podaas-fix-sp.keystore --keystorePassword password --key podaassp --keyPassword password

Vytvorené súbory zašlite emailom:

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
>
> Predmet: **&lt;skratka projektu&gt;** - FIX - IAM - Žiadosť - Zriadenie identít, zastupovanie, registrácia TU a STS
> 
> Dobrý deň,
> 
> týmto žiadam zriadenie testovacích identít 2 x FO, 1 x PO a 1 x OVM a zároveň nastavenie splnomocnenia, kde prvá FO bude zastupovať PO a druhá FO zastupovať OVM.
>
> Taktiež týmto žiadam o zaregistrovanie TU pre uvedenú PO a metadát SP.
> 
> Ďakujem.

Stiahnite TLS certifikáty. TODO

**Ako prílohu priložte do jedného súboru zozipované `podaas-fix-sts.crt`, `podaas-fix-sp.crt` a `podaas-fix-sp.signed.metadata.xml`.** Emailový server na strane dodávateľa to inak odmietne!

### 7. Vykonanie akceptačného testovania (UAT) vo FIX prostredí

Na rozbehnutom komponente `slovensko-sk-api` vo FIX prostredí je potrebné pre jednotlivé UAT prípady vykonať nasledovné:

- pre *TC_IAM_01* a *TC_IAM_01_NEG*

  spustite nasledujúci príkaz v rámci komponentu a zo štandardného výstupu vyberte relevantné časti:

      bin/uat-iam

- pre *TC_IAM_02* a *TC_IAM_03*

  - prihláste sa a odhláste sa cez API komponentu, potom z logu komponentu vyberte relevantné časti,
  - prihláste sa cez API komponentu ale odhláste cez portál ÚPVS, potom z logu komponentu vyberte relevantné časti.

- pre *TC_G2G_01* a *TC_G2G_02*

  spustite nasledujúci príkaz a z logu komponentu vyberte relevantné časti:

      bin/uat-sktalk 'https://podaas.ekosystem.staging.slovensko.digital' <obo-token> <sktalk-message>

  kde `<obo-token>` je OBO token získaný po úspešnom prihlásení a v danom čase ešte platný a `<sktalk-message>` je cesta k súboru so SKTalk správou, ktorá bude odoslaná a následne uložená medzi odoslané.

  Príkaz automaticky vygeneruje platný API token a odošle požiadavku na API komponentu, na to sú potrebné súbory `security/api-token.private.pem` a `security/obo-token.private.pem`.
  Príkaz automaticky nahradí `MessageID` a `CorrelationID` v odosielanej SKTalk správe.
  **Pre akceptovanie G2G prípadov je potrebné správne nastaviť `SenderId` a `RecipientId` podľa prihláseného používateľa**, ktorého OBO token je uvedený v argumentoch príkazu. 

- pre *TC_EFORM_01*, *TC_EFORM_01_NEG* a *TC_EFORM_02*

  spustite nasledujúci príkaz v rámci komponentu a zo štandardného výstupu vyberte relevantné časti: 

      bin/uat-eform

Pozn. úspešne vykonané UAT príkazy končia vždy s exit code 0, niektoré aj napriek výpisu nezachytenej výnimky na konci štandardného výstupu, v tom prípade ide o žiadanú informáciu.

Pozrite si schválený [akceptačný protokol](doc/templates/UAT_SKDIGI_PO_PODAAS_v0_1_2.docx) pre projekt PodaaS (z dokumentu boli odstránené výstupy akceptačných testov). Pozor, treba sa uistiť, že používate **aktuálnu šablónu** NASES, pretože tie sa v čase menia.

### 8. Zriadenie prístupov do PROD prostredia

Vygenerujte certifikáty. Reťazec `podaas` v názvoch súborov, aliasoch a CN certifikátov nahraďte skratkou Vašej integrácie, podobne nahraďte IČO a reťazec `podaas.slovensko.digital` CN v certifikátov.  

    keytool -genkeypair -alias podaassts --keyalg RSA --keysize 2048 --sigalg sha512WithRSA -validity 730 -keystore podaas-prod-sts.keystore -dname "CN=tech.ico-50881337.upvsprod.ext.podaas.slovensko.digital"
    
    keytool -export -keystore podaas-prod-sts.keystore -alias podaassts > podaas-prod-sts.crt
    
    keytool -genkeypair -alias podaassp --keyalg RSA --keysize 2048 --sigalg sha512WithRSA -validity 730 -keystore podaas-prod-sp.keystore -dname "CN=sp.ico-50881337.upvsprod.ext.podaas.slovensko.digital"
    
    keytool -export -keystore podaas-prod-sp.keystore -alias podaassp > podaas-prod-sp.crt
    
    keytool -export -keystore podaas-prod-sp.keystore -alias podaassp -rfc > podaas-prod-sp.pem

Vytvorte `podaas-prod-sp.metadata.xml` zo súboru [podaas-sp.metadata.xml](doc/templates/podaas-sp.metadata.xml). Treba nahradniť `entityID`, dva verejné klúče (skopírovaním z `podaas-prod-sp.pem`) a endpointy, kde bude **produkčná** verzia bežať. Metadáta podpíšte pomocou [xmlsectool](http://shibboleth.net/downloads/tools/xmlsectool/latest).

    xmlsectool --sign --inFile podaas-prod-sp.metadata.xml --outFile podaas-prod-sp.signed.metadata.xml --keystore podaas-prod-sp.keystore --keystorePassword ... --key podaassp --keyPassword ...

TODO

### 9. Vykonanie akceptačného testovania (UAT) v PROD prostredí

Pozn. nutné len v prípade, že používate ÚPVS SSO.

TODO
