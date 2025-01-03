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
