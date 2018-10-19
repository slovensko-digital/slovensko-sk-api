# PodaaS - inštalačná príručka

Máme dobrú a zlú správu. Tá zlá správa je, že na zfunkčnenie tohto komponentu podaní (alebo akejkoľvek inej integrácie na slovensko.sk) je nutné prejsť pomerne náročný proces s NASES a vypracovať množstvo dokumentácie. Tá dobrá správa je, že sme to skoro celé spravili za Vás a tento návod by mal úplne stačiť na to, aby ste komponent dostali do produkčnej prevádzky.

## Postup zriadenia integrácie na slovensko.sk - ústredný portál verejnej správy (UPVS)

### 1. Zriadenie prístupu k dokumentácii UPVS

   Na adrese https://www.nases.gov.sk/sluzby/usmernenie-k-integracii/index.html nájdete formulár na prístup k aktuálnej dokumentácii UPVS. Odporúčame si prístup zriadiť, kedže sa na portáli, okrem dokumentácie, nachádzajú aj informácie o plánovaných odstávkach a ďalšom rozvoji UPVS.

### 2. Zaslanie Dohody o integračnom zámere DIZ 

### 3. Podpis DIZ

### 4. Vytvorenie infraštruktúrneho prepojenia do FIX prostredia

### 5. Zriadenie prístupov do FIX prostredia

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

**Ako prílohy priložte `podaas-fix-sts.crt`, `podaas-fix-sp.crt` a `podaas-fix-sp.signed.metadata.xml`.**


### 9. Vykonanie akceptačného testovania (UAT)

### 10. Prechod do produkcie
