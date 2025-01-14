# **ETL proces datasetu IMDb**
Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z IMDB datasetu. Projekt sa zameriava na preskúmanie trendov vo filmovom priemysle, správania divákov a ich hodnotení. Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúcových metrik.

---
1. Úvod a popis zdrojových dát
Cieľom projektu je analyzovať dáta o filmoch, ich hodnoteniach, obsadení a režiséroch. Analýza umožňuje identifikovať trendy v žanroch, obľúbených hercov a správanie divákov na základe hodnotení.
Zdrojovými dátami je dataset IMDB dostupný [tu](https://www.kaggle.com/datasets/lakshmi25npathi/imdb-dataset-of-50k-movie-reviews). Dataset obsahuje nasledovné tabuľky:
- `movie`
- `ratings`
- `actors`
- `director`
- `genre`
  
ETL proces zahŕňa extrahovanie, čistenie a transformáciu týchto dát do viacdimenzionálneho modelu vhodného na analýzu.

---
### **1.1 Dátová architektúra**
Surové dáta sú usporiadané v relačnom modeli znázornenom na entitno-relačnom diagrame (ERD):

<p align="center">
  <img src="https://github.com/SomeUnknownNickname/IMDb/blob/main/IMDB_ERD.png">
  <br>
  <em>Obrázok 1 Entitno-relačná schéma IMDb</em>
</p>

---
## **2 Dimenzionálny model**
Navrhnutý bol hviezdicový model (star schema), pre efektívnu analýzu filmových hodnotení, kde centrálny bod predstavuje faktová tabuľka fact_ratings, ktorá je prepojená s nasledujúcimi dimenziami:

- **`dim_users`**:
Obsahuje demografické údaje o používateľoch, ako sú veková kategória, pohlavie, povolanie, vzdelanie a PSČ.

Atribúty: ID používateľa, veková skupina, pohlavie, zamestnanie, úroveň vzdelania, PSČ.


- **`dim_movies`**:
Obsahuje podrobné informácie o filmoch vrátane názvu, roku vydania, dĺžky filmu a štúdia.

Atribúty: ID filmu, názov, rok vydania, dĺžka filmu, štúdio.


- **`dim_actors`**:
Obsahuje informácie o hercoch vrátane mena, priezviska a ich postavenia alebo úlohy vo filme.

Atribúty: ID herca, meno, priezvisko, postavenie.


- **`dim_directors`**:
Obsahuje údaje o režiséroch, ako sú meno, priezvisko a ich význam alebo postavenie.

Atribúty: ID režiséra, meno, priezvisko, postavenie.


- **`dim_date`**:
Zahrňuje informácie o dátumoch hodnotení, ako sú deň, mesiac, rok, názov dňa, číslo týždňa a štvrťrok.

Atribúty: ID dátumu, dátum, deň, názov dňa, mesiac, názov mesiaca, rok, týždeň, štvrťrok.


- **`dim_time`**:
Obsahuje podrobné časové údaje hodnotení, ako sú hodina a formát AM/PM.

Atribúty: ID času, čas, hodina, AM/PM.


- **`genres`**:
Obsahuje informácie o filmových žánroch.

Atribúty: ID žánru, názov žánru.


- **`movies_genres`**:
Prepojovacia tabuľka medzi filmami a ich žánrami.

Atribúty: ID filmu, ID žánru.


Štruktúra hviezdicového modelu je znázornená na diagrame nižšie. Diagram ukazuje prepojenia medzi faktovou tabuľkou a dimenziami, čo zjednodušuje pochopenie a implementáciu modelu.

<p align="center">
  <img src="https://github.com/SomeUnknownNickname/IMDb/blob/main/Dimenzionalny_model.png">
  <br>
  <em>Obrázok 2 Schéma hviezdy pre IMDb</em>
</p>

---
## **3. ETL proces v Snowflake**
Proces ETL (Extract, Transform, Load) pozostával z troch hlavných krokov: extrakcia dát (Extract), transformácia (Transform) a načítanie (Load). V Snowflake bol tento proces implementovaný s cieľom spracovať zdrojové dáta zo staging vrstvy a pripraviť ich do viacdimenzionálneho modelu vhodného na analýzu a vizualizáciu.

---
### **3.1 Extract (Extrahovanie dát)**
Dáta zo zdrojového datasetu vo formáte .csv boli najskôr nahrané do Snowflake pomocou interného stage úložiska s názvom my_stage. Stage v Snowflake slúži ako dočasné úložisko na účely importu alebo exportu dát. Vytvorenie tohto stage úložiska bolo realizované pomocou príkazu:

#### Príklad kódu:
```sql
CREATE OR REPLACE STAGE my_stage;
```

Súbory obsahujúce údaje o filmoch, hercoch, režiséroch, hodnoteniach, žánroch a dátume vydania boli nahrané do úložiska stage. Údaje boli následne importované do pracovných tabuliek pomocou príkazu COPY INTO. Pre každú tabuľku bol použitý podobný príkaz:

```sql
COPY INTO occupations
FROM @my_stage/occupations.csv
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);
```
V prípade tabuľky Names bolo dodatočne použité nastavenie ```NULL_IF = ('NULL')``` kvôli chybe, ktorá súvisela s číslami, ktoré sa z nejakého dôvodu exportovali ako text.

---
### **3.1 Transform (Transformácia dát)**

V tejto fáze boli dáta zo staging tabuliek vyčistené, transformované a obohatené. Hlavným cieľom bolo pripraviť dimenzie a faktovú tabuľku, ktoré umožnia jednoduchú a efektívnu analýzu.

Dimenzia dim_names uchováva údaje o jednotlivcoch (pravdepodobne hercoch alebo režiséroch) spojených s filmami. Obsahuje informácie o ich menách, kategóriách, dôležitých projektoch a ďalšie údaje. Ide o dimenziu typu SCD 2, ktorá umožňuje sledovať historické zmeny v stĺpci filmov, podľa ktorých sú známe, a možnú zmenu kategórie (herec/režisér).

```sql
CREATE TABLE dim_names AS
SELECT DISTINCT
    n.id AS name_id,
    n.name,
    n.height,
    n.date_of_birth,
    n.known_for_movies,
    CASE
        WHEN rm.category IS NULL OR rm.category = 'NULL' THEN 'director'
        WHEN rm.category = 'actor' THEN 'actor'
        WHEN rm.category = 'actress' THEN 'actress'
    END AS category
FROM names n
LEFT JOIN role_mapping rm
    ON n.id = rm.name_id;
```

Faktová tabuľka fact_raitings obsahuje záznamy o hodnoteniach filmov a je prepojená na všetky relevantné dimenzie. Táto tabuľka zahŕňa kľúčové metriky, ako je priemerné hodnotenie, celkový počet hlasov, mediánové hodnotenie, a obsahuje aj časové údaje, ako je dátum publikácie filmu. Taktiež umožňuje analýzu vzťahov medzi filmami, režisérmi a dátumami.

```sql
DROP TABLE IF EXISTS fact_raitings;
CREATE TABLE fact_raitings AS
SELECT
    ROW_NUMBER() OVER (ORDER BY r.movie_id) AS id,  
    r.avg_rating,                                   
    r.total_votes,                                  
    r.median_rating,                                
    m.movie_id AS movieId,                          
    n.id AS nameId,                                 
    d.date_id AS dateId                             
FROM ratings r
JOIN dim_movie m ON r.movie_id = m.movie_id         
LEFT JOIN director_mapping dm ON r.movie_id = dm.movie_id
LEFT JOIN names n ON dm.name_id = n.id             
JOIN dim_date d ON m.date_published = d.full_date;
```

---
### **3.3 Load (Načítanie dát)**

Po úspešnom vytvorení dimenzií a faktovej tabuľky boli dáta nahraté do finálnej štruktúry. Na záver boli staging tabuľky odstránené, aby sa optimalizovalo využitie úložiska:

```sql
DROP TABLE names;
DROP TABLE genre;
DROP TABLE raitings;
DROP TABLE director_mapping;
DROP TABLE role_mapping;
DROP TABLE movie;
```

ETL proces v Snowflake umožnil transformáciu pôvodných dát z formátu .csv do viacdimenzionálneho modelu typu hviezda. Tento proces zahŕňal čistenie, obohacovanie a reorganizáciu dát. Výsledný model poskytuje analytické nástroje pre skúmanie preferencií a správania používateľov, čím tvorí základ pre vizualizácie a reporty.

---
## **4 Vizualizácia dát**

Dashboard obsahuje `5 vizualizácií`, ktoré poskytujú základný prehľad o kľúčových metrikách a trendoch týkajúcich sa kníh, používateľov a hodnotení. Tieto vizualizácie odpovedajú na dôležité otázky a umožňujú lepšie pochopiť správanie používateľov a ich preferencie.

<p align="center">
  <img src="" alt="ERD Schema">
  <br>
  <em>Obrázok 3 Dashboard IMDB datasetu</em>
</p>

---
### ** 1. Najlepšie filmy podľa priemerného hodnotenia **

Tento graf zobrazuje 10 najlepšie hodnotených filmov podľa priemerného hodnotenia. Filmy ako Kirket a Love in Kilnerry dosiahli najvyššie priemerné hodnotenie 10, pričom ďalšie tituly ako Gini Helida Kathe a Android Kunjappan Version 5.25 nasledujú s hodnotením tesne pod 10.

```sql
SELECT 
    dm.title AS movie_title, 
    MAX(fr.avg_rating) AS average_rating
FROM fakt_ratings fr
JOIN dim_movie dm ON fr.movieId = dm.movie_id
GROUP BY dm.title
ORDER BY average_rating DESC
LIMIT 10;
```

---
### ** 2. Najlepšie krajiny podľa počtu filmov **

Tento graf zobrazuje 10 krajín s najväčším počtom filmov. Na vrchole rebríčka sú krajiny s najväčšou filmovou produkciou, pričom ostatné krajiny nasledujú podľa počtu jedinečných filmov.

```sql
SELECT 
    dm.country, 
    COUNT(DISTINCT dm.movie_id) AS movie_count
FROM dim_movie dm
GROUP BY dm.country
ORDER BY movie_count DESC
LIMIT 10;
```
---
### ** 3. Najlepšie krajiny podľa priemerného hodnotenia **

Tento graf zobrazuje 10 krajín s najvyšším priemerným hodnotením filmov. Krajiny sú zoradené zostupne podľa priemerného hodnotenia, pričom na vrchole sú tie, ktorých filmy získali najlepšie hodnotenia.

```sql
SELECT 
    dm.country, 
    Round(AVG(fr.avg_rating), 2) AS average_rating
FROM fakt_ratings fr
JOIN dim_movie dm ON fr.movieId = dm.movie_id
GROUP BY dm.country
ORDER BY average_rating DESC
LIMIT 10;
```
---
### ** 4. Najlepšie žánre podľa počtu filmov **

Tento graf zobrazuje 10 najpopulárnejších filmových žánrov podľa počtu filmov. Žánry sú zoradené zostupne, pričom na vrchole sú tie, ktoré majú najväčšie zastúpenie vo filmovej produkcii.

```sql
SELECT 
    dg.genre_name, 
    COUNT(mgb.movie_id) AS movie_count
FROM movie_genre_bridge mgb
JOIN dim_genre dg ON mgb.genre_name = dg.genre_name
GROUP BY dg.genre_name
ORDER BY movie_count DESC
LIMIT 10;

```
---
### ** 5. Priemerné hodnotenie filmov podľa produkčnej spoločnosti **


Tento graf zobrazuje 10 produkčných spoločností s najvyšším priemerným hodnotením filmov. Obsahuje aj informáciu o počte filmov, ktoré každá spoločnosť vyprodukovala, pričom zohľadňuje len spoločnosti s viac ako jedným filmom. Na vrchole sú spoločnosti s najlepším hodnotením.

```sql
SELECT 
    dm.production_company, 
    ROUND(AVG(fr.avg_rating), 2) AS average_rating,
    COUNT(DISTINCT dm.movie_id) AS movie_count
FROM fakt_ratings fr
JOIN dim_movie dm ON fr.movieId = dm.movie_id
GROUP BY dm.production_company
HAVING movie_count > 1 
ORDER BY average_rating DESC
LIMIT 10;
```

Dashboard poskytuje prehľad o preferenciách divákov a správaní používateľov. Vizualizácie zodpovedajú otázky týkajúce sa najlepšie hodnotených filmov, počtu filmov podľa krajiny a žánru, a priemerného hodnotenia podľa produkčných spoločností. Tieto dáta pomáhajú optimalizovať odporúčacie systémy, marketingové stratégie a správu filmových zbierok.

---

**Autor:** Vladyslav Shaposhnikov