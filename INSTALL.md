# slovensko.sk API - inštalačná príručka

Máme dobrú a zlú správu. Tá zlá správa je, že na zfunkčnenie tohto komponentu (alebo akejkoľvek inej integrácie na slovensko.sk) je nutné prejsť pomerne náročný proces s NASES a vypracovať množstvo dokumentácie. Tá dobrá správa je, že sme to skoro celé spravili za Vás a tento návod by mal úplne stačiť na to, aby ste komponent dostali do produkčnej prevádzky. Ak sa Vám to zdá zložité, ozvite sa nám emailom na `ekosystem@slovensko.digital` a radi pomôžeme.

## Postup spustenia komponentu 

Komponent `slovensko-sk-api` je distribuovaný ako Docker kontajner, ktorý sa spúšťa štandardne, najľahšie cez `docker-compose`.

Pred prvým spustením je potrebné pripraviť si adresár, ktorý bude obsahovať:
 
- [docker-compose.yml](doc/templates/docker-compose.yml) uprevený podľa potreby,
- [.env](doc/templates/.env) s doplnenými hodnotami premenných podľa potreby,
- všetky súbory potrebné podľa `.env` umiestnené napr. v podadresári `security`, sú to:

  - `api-token.public.pem` - verejný kľúč pre verifikáciu API tokenov tretej strany, vygenerovaný napr. pomocou `openssl rsa -in api-token.private.pem -pubout -out api-token.public.pem`, 
  - `obo-token.private.pem` - privátny a verejný kľúč pre generovanie a verifikáciu OBO tokenov v rámci komponentu, vygenerovaný napr. pomocou `openssl genrsa -out obo-token.private.pem 2048`,
  - `upvs-fix-idp.metadata.xml` - IDP metadáta, pozri dokument *UPG-1-1-Integracny_manual_UPVS_IAM*
  - `podaas-fix-sp.metadata.xml` - SP metadáta, pozri časť [*6. Zriadenie prístupov do FIX prostredia*](#6-zriadenie-prstupov-do-fix-prostredia),
  - `podaas-fix-sp.keystore` - SP certifikát s kľúčom, pozri časť [*6. Zriadenie prístupov do FIX prostredia*](#6-zriadenie-prstupov-do-fix-prostredia),
  - `podaas-fix-sts.keystore` - STS certifikát s kľúčom, pozri časť [*6. Zriadenie prístupov do FIX prostredia*](#6-zriadenie-prstupov-do-fix-prostredia),
  - `upvs-fix.truststore` - certifikát STS služby na strane ÚPVS, pozri dokument *UPG-1-1-Integracny_manual_UPVS_IAM*.

Ďalej je potrebné inicializovať databázu cez:

    docker-compose run web rails db:create db:migrate
 
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

Na adrese https://www.nases.gov.sk/sluzby/usmernenie-k-integracii/index.html nájdete formulár na prístup k aktuálnej dokumentácii ÚPVS. Odporúčame si prístup zriadiť, kedže sa na portáli, okrem dokumentácie, nachádzajú aj informácie o plánovaných odstávkach a ďalšom rozvoji ÚPVS.

### 2. Zaslanie Dohody o integračnom zámere DIZ 

Je potrebné si zvoliť skratku projektu, ktorá sa bude používať pre účely komunikácie s NASES. Názov môže obsahovať len veľké písmená, bez diakritiky a medzier, a musí byť unikátny. *My sme napríklad použili názov PODAAS, ten je už obsadený.*

Stiahnite si [šablónu dohody o integračnom zámere](doc/templates/DIZ_PO_TEMPLATE__UPVS_v1.docx) a upravte podľa pokynov v komentároch. 

Tento dokument následne premenujte na `DIZ_PO_<skratka projektu>__UPVS_v1.docx`, kde `<skratka projektu>` nahraďte skratkou Vášho projektu a priložte ako prílohu k emailu:

> Adresát: integracie@globaltel.sk, integracie@nases.gov.sk
>
> Predmet: <skratka projektu> – DEV – DIZ – Požiadavka – Revízia dohody o integračnom zámere – TYP PO – v1.0
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
> Predmet:  **&lt;skratka projektu&gt;** – FIX/PROD – INFRA – Požiadavka - Pridelenie adresného rozsahu
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

    xmlsectool.sh --sign --inFile podaas-fix-sp.metadata.xml --outFile podaas-fix-sp.signed.metadata.xml --keystore podaas-fix-sp.keystore --keystorePassword password --key podaassp --keyPassword password

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

**Ako prílohu priložte do jedného súboru zozipované `podaas-fix-sts.crt`, `podaas-fix-sp.crt` a `podaas-fix-sp.signed.metadata.xml`.** Emailový server na strane dodávateľa to inak odmietne!

### 7. Vykonanie akceptačného testovania (UAT)

TODO

### 8. Prechod do produkcie

TODO
