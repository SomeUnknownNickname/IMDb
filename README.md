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
