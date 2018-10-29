# PodaaS - inštalačná príručka

Máme dobrú a zlú správu. Tá zlá správa je, že na zfunkčnenie tohto komponentu podaní (alebo akejkoľvek inej integrácie na slovensko.sk) je nutné prejsť pomerne náročný proces s NASES a vypracovať množstvo dokumentácie. Tá dobrá správa je, že sme to skoro celé spravili za Vás a tento návod by mal úplne stačiť na to, aby ste komponent dostali do produkčnej prevádzky.

## Postup zriadenia integrácie na slovensko.sk - ústredný portál verejnej správy (UPVS)

### 1. Zriadenie prístupu k dokumentácii UPVS

   Na adrese https://www.nases.gov.sk/sluzby/usmernenie-k-integracii/index.html nájdete formulár na prístup k aktuálnej dokumentácii UPVS. Odporúčame si prístup zriadiť, kedže sa na portáli, okrem dokumentácie, nachádzajú aj informácie o plánovaných odstávkach a ďalšom rozvoji UPVS.

### 2. Zaslanie Dohody o integračnom zámere DIZ 

### 3. Podpis DIZ

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

1. V prvej záložke `Základné údaje` nájdete `Pridelený koordinovaný rozsah pre služby v tuneloch ES:` napríklad `100.66.0.128/28`. Od tohto rozsahu sa odvíjajú nasledujúce nastavenia.
2. V prvej záložke vyplňte potrebné kontaktné údaje pre externý subjekt (to ste Vy)
3. V tretej záložke `Integračné a aplikačné endpointy` vyplňte všetky riadky stĺpca `Rozhranie ES TunelIP` tak, že pre FIX prostredie uvediete piatu adresu rozsahu (t.j. pre rozsah `100.66.0.128/28` to bude `100.66.0.128 + 5` = `100.66.0.133`) a pre PROD prostredie desiatu adresu rozsahu `100.55.0.128 + 10` = `100.66.0.138`. 
4. V tretej záložke `Integračné a aplikačné endpointy` následne označte červeným pozadím riadky s rozhraním `IAM-WS - 1.7, 2.0` toto sa nepoužíva, ostatné riadky označte zeleným pozadím. Teda: `schranka - EKR`, `UIR (URP, URZ - BPM)`, `USR (SB-Ext. Zbernica)` aj `IAM-STS.` 
5. V štvrtej záložke `GUI Endpointy Test-Fix` povoľte prístup z internetu cez GUI pre Portal 1.7, 2.0, Prihlasenie IAM, Formulare, eFormulare, schranka - eDesk 1.7, 2.0. 
6. V štvrtej záložke `GUI Endpointy Test-Fix` do `IP GW ES pre povolenie pristupu ku GUI rozhraniam:` uveďte verejnú IP adresu stroja, cez ktorý sa pristupovať k portálu pre účely testovania.
7. V piatej záložke `DNS` uveďte ako `IP ES Site` pre FIX tretiu adresu rozsahu (t.j. pre rozsah `100.66.0.128/28` to bude `100.66.0.128 + 3` = `100.66.0.131`) a pre PROD štvrtú adresu rozsahu (t.j. pre rozsah `100.66.0.128/28` to bude `100.66.0.128 + 4` = `100.66.0.132`)  
8. V záložke `IPsec LAN to LAN` uveďte do `Remote VPN gateway IP address ( ES site )` verejnú IP adresu stroja, kde bude bežať tento komponent (resp. koniec IPsec tunela)

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


### 6. Zriadenie prístupov do FIX prostredia

`keytool -genkeypair -alias podaassts --keyalg RSA --keysize 2048 --sigalg sha512WithRSA -validity 730 -keypass password -keystore podaas-fix-sts.keystore -storepass password -dname "CN=tech.podaas.upvsfix.ext.podaas.slovensko.digital"`

`keytool -export -keystore podaas-fix-sts.keystore -alias podaassts -storepass password > podaas-fix-sts.crt`

`keytool -genkeypair -alias podaassp --keyalg RSA --keysize 2048 --sigalg sha512WithRSA -validity 730 -keypass password -keystore podaas-fix-sp.keystore -storepass password -dname "CN=sp.podaas.upvsfix.ext.podaas.slovensko.digital"`

`keytool -export -keystore podaas-fix-sp.keystore -alias podaassp -storepass password > podaas-fix-sp.crt`

`keytool -export -keystore podaas-fix-sp.keystore -alias podaassp -storepass password -rfc > podaas-fix-sp.pem`

Vytvorte `podaas-fix-sp.metadata.xml` zo súboru `install/podaas-sp.metadata.xml.template`. Treba nahradniť entityID, dva verejné klúče (skopírovaním z `podaas-fix-sp.pem`) a endpointy, kde bude **testovacia** verzia bežať.

Podpíšte pomocou [xmlsectool](http://shibboleth.net/downloads/tools/xmlsectool/latest/).

`xmlsectool.sh --sign --inFile podaas-fix-sp.metadata.xml --outFile podaas-fix-sp.signed.metadata.xml --keystore podaas-fix-sp.keystore --keystorePassword password --key podaassp --keyPassword password`


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

### 8. Prechod do produkcie
