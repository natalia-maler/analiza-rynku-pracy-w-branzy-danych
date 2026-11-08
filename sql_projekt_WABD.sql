USE WieLkaAnkietaBran¿yData
GO

/* Stanowiska w bran¿y danych pod k¹tem analizy wynagrodzeñ, kompetencji i satysfakcji zawodowej   */

-- W analizie uwzglêdniono 297 respondentów.

/* Struktura stanowisk - kto pracuje w bran¿y danych? */
-- Strona przedstawia strukturê badanej próby wed³ug stanowiska, p³ci, poziomu doœwiadczenia oraz wykszta³cenia respondentów. 
-- Pozwala okreœliæ, jakie grupy zawodowe dominuj¹ w badaniu i jaki jest ich profil edukacyjny.

-- Struktura p³ci respondentów w badanej grupie
-- Celem jest okreœlenie struktury p³ci respondentów bior¹cych udzia³ w ankiecie.
-- Sprawdzana jest liczba kobiet i mê¿czyzn oraz ich udzia³ procentowy w ca³ej badanej grupie. Pozwala to scharakteryzowaæ próbê badawcz¹ i sprawdziæ, czy jest ona zró¿nicowana pod wzglêdem p³ci.
SELECT
    p³eæ,
    COUNT(*) AS LiczbaOsob,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS UdzialProcentowy
FROM ogolne
GROUP BY p³eæ
ORDER BY LiczbaOsob DESC;


-- Liczba i udzia³ respondentów na poszczególnych stanowiskach
-- Celem analizy jest ustalenie, jakie stanowiska s¹ najczêœciej reprezentowane w badanej grupie i jaki procent wszystkich respondentów przypada na ka¿d¹ rolê.

SELECT stanowisko, COUNT(*) AS LiczbaOsob, CAST( 100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS UdzialProcentowy
FROM ogolne
GROUP BY stanowisko
ORDER BY LiczbaOsob DESC;


-- Struktura p³ci w obrêbie poszczególnych stanowisk
-- Poni¿sze zapytanie sprawdza, jak wygl¹da udzia³ kobiet i mê¿czyzn w obrêbie ka¿dej roli.
SELECT stanowisko, p³eæ, COUNT(*) AS LiczbaOsob,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY stanowisko) AS DECIMAL(5,2)) AS UdzialProcentowy
FROM ogolne
GROUP BY stanowisko, p³eæ


-- Wykszta³cenie a stanowisko - jakie kierunki studiów reprezentuj¹ osoby pracuj¹ce w bran¿y danych
-- Celem analizy jest sprawdzenie, jakie wykszta³cenie posiadaj¹ respondenci pracuj¹cy na ró¿nych stanowiskach w bran¿y danych. 
-- Chcemy okreœliæ, czy poszczególne stanowiska s¹ zdominowane przez absolwentów kierunków informatycznych, czy te¿ w bran¿y znajduj¹ zatrudnienie osoby z wykszta³ceniem ekonomicznym, matematycznym, przyrodniczym.
SELECT
    stanowisko,
    kierunek_wykszta³cenia,
    COUNT(*) AS LiczbaOsob,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY stanowisko) AS DECIMAL(5,2)) AS UdzialProcentowy
FROM dbo.ogolne
WHERE kierunek_wykszta³cenia IS NOT NULL
GROUP BY stanowisko, kierunek_wykszta³cenia
ORDER BY stanowisko, LiczbaOsob DESC;


-- Struktura stanowisk wed³ug poziomu seniority
-- Celem analizy jest sprawdzenie, jakie poziomy doœwiadczenia zawodowego dominuj¹ na poszczególnych stanowiskach. 
-- Mo¿na zadaæ pytanie, czy wœród data analyst przewa¿aj¹ osoby na poziomie junior, mid czy senior oraz czy struktura seniority ró¿ni siê miêdzy rolami.
SELECT stanowisko, poziom_stanowiska_seniority AS Seniority, COUNT(*) AS LiczbaOsob,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY stanowisko) AS DECIMAL(5,2)) AS UdzialProcentowy
FROM ogolne
GROUP BY stanowisko, poziom_stanowiska_seniority
ORDER BY stanowisko, LiczbaOsob DESC;

/* Podsumowanie sekcji */
-- Najliczniejsz¹ grupê stanowi¹ data analyst - 162 osoby z wartoœci¹ procentow¹ 54.55%.
-- Kolejne miejsca zajmuj¹ data scientist - 13.13% i data engineer - 11.11%.
-- £¹cznie te trzy stanowiska obejmuj¹ prawie 79% badanej grupy.
-- W próbie dominuj¹ osoby na poziomie mid / regular, choæ struktura doœwiadczenia ró¿ni siê miêdzy stanowiskami.

/* Wynagrodzenia - które stanowiska zarabiaj¹ najwiêcej?  */
-- W tej sekcji przechodzimy od struktury stanowisk do jednego z najwa¿niejszych aspektów pracy w bran¿y danych, czyli wynagrodzeñ. 
-- Warto sprawdziæ, czy wysokoœæ zarobków ró¿ni siê w zale¿noœci od stanowiska, a tak¿e czy poziom seniority ma zwi¹zek z wysokoœci¹ wynagrodzenia.

-- Które stanowiska s¹ najlepiej wynagradzane?
-- Celem jest porównanie wynagrodzeñ osób pracuj¹cych na ró¿nych stanowiskach w bran¿y danych. Warto ustaliæ, które role charakteryzuj¹ siê 
-- najwy¿szym przeciêtnym wynagrodzeniem, a które najni¿szym. W analizie wykorzystano œredni¹, minimum, maksimum oraz
-- medianê, która pozwala ograniczyæ wp³yw pojedynczych, wyj¹tkowo wysokich wynagrodzeñ.
WITH Dane AS
(
    SELECT o.stanowisko, TRY_CONVERT(DECIMAL(12,2), REPLACE(op.[zarobki], ',', '.')) AS Wynagrodzenie
    FROM dbo.ogolne o
    INNER JOIN dbo.organizacja_pracy op ON o.id = op.id
),
Statystyki AS
(
    SELECT
        stanowisko,
        COUNT(Wynagrodzenie) AS LiczbaWynagrodzen,
        AVG(Wynagrodzenie) AS SrednieWynagrodzenie,
        MIN(Wynagrodzenie) AS MinimalneWynagrodzenie,
        MAX(Wynagrodzenie) AS MaksymalneWynagrodzenie
    FROM Dane
    GROUP BY stanowisko
),
Mediany AS
(
    SELECT DISTINCT stanowisko, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Wynagrodzenie)
        OVER ( PARTITION BY stanowisko) AS Mediana
    FROM Dane
    WHERE Wynagrodzenie IS NOT NULL
)
SELECT
    s.stanowisko,
    s.LiczbaWynagrodzen,
    s.SrednieWynagrodzenie,
    m.Mediana,
    s.MinimalneWynagrodzenie,
    s.MaksymalneWynagrodzenie
FROM Statystyki s
LEFT JOIN Mediany m ON s.stanowisko = m.stanowisko
ORDER BY s.SrednieWynagrodzenie DESC;

-- Wynagrodzenia wed³ug stanowiska i seniority 
WITH Dane AS
(
    SELECT o.stanowisko, o.poziom_stanowiska_seniority AS Seniority,
        TRY_CONVERT(
            DECIMAL(12,2),
            REPLACE(op.[zarobki], ',', '.')
        ) AS Wynagrodzenie
    FROM dbo.ogolne o
    INNER JOIN dbo.organizacja_pracy op ON o.id = op.id
)
SELECT stanowisko, Seniority,COUNT(Wynagrodzenie) AS LiczbaOsob, AVG(Wynagrodzenie) AS SrednieWynagrodzenie
FROM Dane
GROUP BY stanowisko, Seniority
ORDER BY stanowisko, SrednieWynagrodzenie DESC;

/* Podsumowanie */
/* 
- Najwy¿sza œrednia wynagrodzeñ wystêpuje wœród ml/ai engineerów - 12 157 z³.
- Kolejne miejsca zajmuj¹ data scientist - 11 496 z³ oraz analytics engineer - 11 233 z³.
- Najni¿sza œrednia wystêpuje wœród data analystów - 8 381 z³.
- Wynagrodzenie zazwyczaj roœnie wraz z poziomem seniority.
- Mediana pozwala zauwa¿yæ, ¿e wysokie pojedyncze wynagrodzenia mog¹ zawy¿aæ œredni¹, szczególnie w grupie data scientist.
*/

/* Technologie i kompetencje - czym ró¿ni¹ siê poszczególne stanowiska? */
-- W tej sekcji chcemy przejœæ od pytania „ile zarabiaj¹ osoby na poszczególnych stanowiskach?” do pytania „czym w³aœciwie zajmuj¹ siê te osoby i jakich technologii u¿ywaj¹?”.
-- Tutaj warto zbadaæ nie tylko najpopularniejsze jêzyki programowania, ale przede wszystkim to, jakie technologie i zadania s¹ charakterystyczne dla konkretnych stanowisk.

-- Jakie jêzyki programowania s¹ najczêœciej u¿ywane na poszczególnych stanowiskach?
-- W tej analizie warto siê skupiæ, jakie jêzyki programowania dominuj¹ w codziennej pracy osób na poszczególnych stanowiskach. 
-- Pozwoli to okreœliæ, czy konkretne role maj¹ charakter bardziej analityczny, programistyczny czy in¿ynierski.
-- Dodatkowo rozk³ad procentowy jest liczony osobno dla ka¿dego stanowiska, aby uzyskaæ wyniki dla konkretnej grupy.
SELECT
    o.stanowisko,
    t.w_jakim_jezyku_programujesz_najczesciej_w_swojej_pracy AS JezykProgramowania,
    COUNT(*) AS LiczbaOsob,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY o.stanowisko) AS DECIMAL(5,2)) AS UdzialProcentowy
FROM ogolne o
INNER JOIN technologie t ON o.id = t.id
WHERE t.w_jakim_jezyku_programujesz_najczesciej_w_swojej_pracy IS NOT NULL
GROUP BY o.stanowisko, t.w_jakim_jezyku_programujesz_najczesciej_w_swojej_pracy
ORDER BY o.stanowisko, LiczbaOsob DESC;

-- Jaki udzia³ pracy stanowi programowanie?
-- Na podstawie tej analizy bêdzie mo¿na porównaæ, czy programowanie jest bardziej charakterystyczne dla data engineer i ml/ai engineer, czy równie¿ stanowi istotn¹ czêœæ pracy data analyst i business analyst.
SELECT
    o.stanowisko,
    COUNT(TRY_CONVERT(DECIMAL(10,2), t.jaki_procent_twojej_pracy_stanowi_programowanie)) AS LiczbaOdpowiedzi,
    AVG(TRY_CONVERT(DECIMAL(10,2), t.jaki_procent_twojej_pracy_stanowi_programowanie)) AS SredniUdzialProgramowania
FROM dbo.ogolne o
INNER JOIN dbo.technologie t ON o.id = t.id
GROUP BY o.stanowisko
ORDER BY SredniUdzialProgramowania DESC;


-- Jakie poszczególne technologie i narzêdzia wykorzystuj¹ osoby na stanowiskach?
-- Analiza pozwala nie tylko sprawdziæ, jakie narzêdzia s¹ popularne, ale przede wszystkim odkryæ charakterystyczne zestawy technologii dla poszczególnych ról.
WITH TechnologieRespondentow AS
(
    SELECT o.id, o.stanowisko, x.Technologia, x.CzyUzywa
    FROM dbo.ogolne o
    INNER JOIN dbo.technologie t ON o.id = t.id

    CROSS APPLY
    (
        VALUES
            ('Python', CAST(t.[programowanie_python] AS INT)),
			('SQL', CAST(t.[programowanie_sql] AS INT)),
            ('Power BI', CAST(t.[narzedzia_power_bi] AS INT)),
            ('Airflow', CAST(t.[narzedzia_airflow] AS INT)),
            ('Docker', CAST(t.[narzedzia_docker] AS INT)),
            ('Git', CAST(t.[narzedzia_git_github_gitlab] AS INT)),
            ('TensorFlow', CAST(t.[narzedzia_tensorflow] AS INT)),
            ('PyTorch', CAST(t.[narzedzia_pytorch] AS INT)),
			('Databricks', CAST(t.[narzedzia_databricks] AS INT)),
			('LLM', CAST(t.[narzedzia_llm_y] AS INT)),
			('Bazy danych', CAST(t.[narzedzia_bazy_danych] AS INT))
    ) AS x(Technologia, CzyUzywa)
)
SELECT stanowisko, Technologia,
    COUNT(*) AS LiczbaRespondentow,
    SUM(CzyUzywa) AS LiczbaUzytkownikow,
    CAST(100.0 * SUM(CzyUzywa) / COUNT(*) AS DECIMAL(5,2)) AS ProcentUzytkownikow
FROM TechnologieRespondentow
GROUP BY stanowisko, Technologia
ORDER BY stanowisko, ProcentUzytkownikow DESC;

/* Podsumowanie */
/*
SQL i bazy danych s¹ wa¿ne przede wszystkim na stanowiskach analitycznych i BI.
Python dominuje wœród data scientistów i ml/ai engineerów.
Data engineerzy ³¹cz¹ wykorzystanie SQL i Pythona z narzêdziami do przetwarzania i automatyzacji danych.
ML/AI engineerzy wyró¿niaj¹ siê czêstym wykorzystaniem dockera, git i narzêdzi zwi¹zanych z LLM.
Podsumowuj¹c, bran¿a danych nie wymaga jednego uniwersalnego zestawu kompetencji. Technologie i narzêdzia s¹ mocno zwi¹zane z charakterem wykonywanej pracy.
*/

/* Organizacja pracy i zespo³y - jak wygl¹daj¹ projekty i zakres odpowiedzialnoœci? */

-- Samodzielnoœæ techniczna wed³ug stanowiska
-- Celem analizy jest odkrycie "na ile pracownicy sami podejmuj¹ decyzje i rozwi¹zuj¹ problemy".
SELECT
    o.stanowisko,
    p.jak_oceniasz_swoja_samodzielnosc_w_kwestiach_technicznych_np_wybor_narzedzi_metod_rozwiazywanie_problemow_tech AS SamodzielnoscTechniczna,
    COUNT(*) AS LiczbaOsob,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY o.stanowisko) AS DECIMAL(5,2)) AS UdzialProcentowy
FROM ogolne o
INNER JOIN dbo.projekty p ON o.id = p.id
WHERE p.jak_oceniasz_swoja_samodzielnosc_w_kwestiach_technicznych_np_wybor_narzedzi_metod_rozwiazywanie_problemow_tech IS NOT NULL
GROUP BY o.stanowisko, p.jak_oceniasz_swoja_samodzielnosc_w_kwestiach_technicznych_np_wybor_narzedzi_metod_rozwiazywanie_problemow_tech
ORDER BY o.stanowisko, LiczbaOsob DESC;

-- Liczba projektów wed³ug stanowiska
-- Przedstawiona anliza pozwala oceniæ, czy okreœlone stanowiska czêœciej pracuj¹ nad jednym projektem, kilkoma projektami czy wiêksz¹ liczb¹ zadañ jednoczeœnie.
SELECT
    o.stanowisko,
    p.nad_iloma_projektami_obecnie_pracujesz AS LiczbaProjektow,
    COUNT(*) AS LiczbaRespondentow,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY o.stanowisko) AS DECIMAL(5,2)) AS UdzialProcentowy
FROM dbo.ogolne o
INNER JOIN dbo.projekty p ON o.id = p.id
WHERE p.nad_iloma_projektami_obecnie_pracujesz IS NOT NULL
GROUP BY o.stanowisko, p.nad_iloma_projektami_obecnie_pracujesz
ORDER BY o.stanowisko, LiczbaRespondentow DESC;

-- Rodzaj zespo³u wed³ug stanowiska
-- Celem analizy jest okreœlenie, w jakiego rodzaju zespo³ach pracuj¹ osoby na poszczególnych stanowiskach.
-- Pozwala to sprawdziæ, czy dane stanowisko jest zwi¹zane g³ównie ze wspó³prac¹ w zespo³ach technicznych, biznesowych, mieszanych.
WITH Dane AS
(
    SELECT o.stanowisko, z.w_jakim_zespole_obecnie_pracujesz AS RodzajZespolu, COUNT(DISTINCT z.id) AS LiczbaOsob
    FROM dbo.ogolne o
    INNER JOIN dbo.zespol z ON o.id = z.id
    WHERE z.w_jakim_zespole_obecnie_pracujesz IS NOT NULL
    GROUP BY o.stanowisko, z.w_jakim_zespole_obecnie_pracujesz
)
SELECT
    stanowisko,
    RodzajZespolu,
    LiczbaOsob,
    CAST(100.0 * LiczbaOsob / SUM(LiczbaOsob) OVER (PARTITION BY stanowisko) AS DECIMAL(5,2)) AS UdzialProcentowy
FROM Dane
ORDER BY stanowisko, LiczbaOsob DESC;

-- Ocena atmosfery i kompetencji technicznych zespo³u
-- Celem analizy jest porównanie, jak pracownicy poszczególnych stanowisk oceniaj¹ atmosferê i wspó³pracê w swoich zespo³ach oraz 
-- poziom kompetencji technicznych pozosta³ych cz³onków zespo³u. Pozwala to okreœliæ, czy dobre relacje zespo³owe id¹ w parze z wysok¹ ocen¹ wiedzy i umiejêtnoœci technicznych.
SELECT
    o.stanowisko,
    COUNT(DISTINCT z.id) AS LiczbaOdpowiedzi,
    AVG(TRY_CONVERT(DECIMAL(10,2),
        z.jak_oceniasz_swój_zespó³_pod_wzglêdem_relacji_personalnych_atmosfera_wspó³praca
    )) AS SredniaOcenaAtmosfery,
    AVG(TRY_CONVERT(DECIMAL(10,2),
        z.jak_oceniasz_swój_zespó³_pod_wzglêdem_kompetencji_technicznych_umiejêtnoœci_wiedza
    )) AS SredniaOcenaKompetencjiTechnicznych
FROM dbo.ogolne o
INNER JOIN dbo.zespol z ON o.id = z.id
GROUP BY o.stanowisko
ORDER BY SredniaOcenaAtmosfery DESC;

-- Ogólna struktura form zatrudnienia
-- Celem analizy jest okreœlenie, jakie formy zatrudnienia dominuj¹ wœród respondentów
WITH Dane AS
(
    SELECT
        p.w_jakiej_formie_jesteœ_obecnie_zatrudniony_a AS FormaZatrudnienia,
        COUNT(DISTINCT p.id) AS LiczbaOsob
    FROM dbo.organizacja_pracy p
    WHERE p.w_jakiej_formie_jesteœ_obecnie_zatrudniony_a IS NOT NULL
    GROUP BY p.w_jakiej_formie_jesteœ_obecnie_zatrudniony_a
)
SELECT
    FormaZatrudnienia,
    LiczbaOsob,
    CAST(100.0 * LiczbaOsob / SUM(LiczbaOsob) OVER ()AS DECIMAL(5,2)) AS UdzialProcentowy
FROM Dane
ORDER BY LiczbaOsob DESC;

-- Podsumowanie
-- W wiêkszoœci grup najczêœciej realizowane s¹ 2-3 projekty.
-- Na wiêkszoœci stanowisk najczêœciej deklarowana jest umiarkowana samodzielnoœæ techniczna, choæ wystêpuj¹ ró¿nice miêdzy rolami.
-- Wystêpuj¹ ró¿nice miêdzy stanowiskami, przyk³adowo ml/ai engineerzy czêœciej wskazuj¹ bardzo wysok¹ samodzielnoœæ, a data engineerzy najczêœciej umiarkowan¹.
-- Rodzaj zespo³u jest powi¹zany ze specyfik¹ stanowiska - role in¿ynierskie czêœciej pracuj¹ w zespo³ach technicznych, a analityczne w mieszanych lub biznesowych.
-- Atmosfera i kompetencje techniczne zespo³ów s¹ oceniane stosunkowo wysoko, choæ oceny ró¿ni¹ siê miêdzy stanowiskami.
-- Zdecydowanie najpopularniejsz¹ form¹ zatrudnienia jest umowa o pracê - 82.94%, a drug¹ B2B - 13.31%.

/* Satysfakcja zawodowa - które stanowiska s¹ najbardziej zadowolone? */
/* W tej czêœci przedstawione s¹ analizy poziomu zadowolenia zawodowego osób pracuj¹cych na ró¿nych stanowiskach. 
Celem jest sprawdzenie, czy satysfakcja z pracy ró¿ni siê w zale¿noœci od stanowiska oraz czy mog¹ mieæ na ni¹ wp³yw takie czynniki jak 
równowaga miêdzy ¿yciem zawodowym a prywatnym i czêstotliwoœæ pracy po godzinach. */

-- Œredni poziom zadowolenia wed³ug stanowiska
-- Celem analizy jest sprawdzenie, jak respondenci oceniaj¹ swoje ogólne zadowolenie z pracy w zale¿noœci od zajmowanego stanowiska. 
-- Wykorzystane s¹ odpowiedzi na pytanie o stopieñ zadowolenia z pracy, oceniane w skali od 1 do 10, gdzie wy¿sza wartoœæ oznacza wiêksz¹ satysfakcjê zawodow¹.
SELECT
    o.stanowisko,
    COUNT(TRY_CONVERT(DECIMAL(10,2), w.w_jaki_stopniu_jesteœ_zadowolona_y_ze_swojej_pracy)) AS LiczbaOsob,
    AVG(TRY_CONVERT(DECIMAL(10,2), w.w_jaki_stopniu_jesteœ_zadowolona_y_ze_swojej_pracy)) AS SrednieZadowolenie
FROM dbo.ogolne o
INNER JOIN dbo.well_being w ON o.id = w.id
GROUP BY o.stanowisko
ORDER BY SrednieZadowolenie DESC;

-- Zadowolenie a work-life balance
-- Przedstawiona analiza sprawdza jaki odsetek osób na poszczególnych stanowiskach jest zadowolony z równowagi miêdzy ¿yciem zawodowym a prywatnym. 
-- Pozwala to oceniæ, czy pracownicy ró¿nych specjalizacji w podobnym stopniu potrafi¹ ³¹czyæ obowi¹zki zawodowe z ¿yciem prywatnym.
SELECT
    o.stanowisko,
    COUNT(w.zadowolenie_work_life_balance) AS LiczbaOdpowiedzi,
    SUM(
        CASE
            WHEN w.zadowolenie_work_life_balance = 1 THEN 1
            ELSE 0
        END
    ) AS LiczbaZadowolonych,
    CAST(
        100.0 * SUM(
            CASE
                WHEN w.zadowolenie_work_life_balance = 1 THEN 1
                ELSE 0
            END
        ) /
        NULLIF(COUNT(w.zadowolenie_work_life_balance), 0)
        AS DECIMAL(5,2)
    ) AS ProcentZadowolonych
FROM dbo.ogolne o
INNER JOIN dbo.well_being w ON o.id = w.id
GROUP BY o.stanowisko
ORDER BY ProcentZadowolonych DESC;

-- Zadowolenie a nadgodziny
-- Ostatnia analiza dotyczy sprawdzenia, jak czêsto osoby na poszczególnych stanowiskach wykonuj¹ obowi¹zki poza standardowym czasem pracy oraz 
-- jak oceniaj¹ swoje zadowolenie zawodowe. Dla ka¿dej kategorii nadgodzin obliczamy liczbê respondentów, udzia³ procentowy w obrêbie stanowiska oraz œredni¹ ocenê zadowolenia z pracy.
WITH Dane AS
(
    SELECT
        o.stanowisko,
        w.jak_czêsto_zdarza_ci_siê_pracowaæ_po_godzinach_lub_w_weekendy AS Nadgodziny,
        TRY_CONVERT(DECIMAL(10,2), w.w_jaki_stopniu_jesteœ_zadowolona_y_ze_swojej_pracy) AS Zadowolenie
    FROM dbo.ogolne o
    INNER JOIN dbo.well_being w ON o.id = w.id
)
SELECT
    stanowisko,
    Nadgodziny,
    COUNT(Zadowolenie) AS LiczbaOdpowiedzi,
    CAST(
        100.0 * COUNT(Zadowolenie) / SUM(COUNT(Zadowolenie)) OVER (PARTITION BY stanowisko)
        AS DECIMAL(5,2)) AS UdzialProcentowy,
    AVG(Zadowolenie) AS SrednieZadowolenie
FROM Dane
WHERE Nadgodziny IS NOT NULL AND Zadowolenie IS NOT NULL
GROUP BY stanowisko, Nadgodziny
ORDER BY stanowisko, SrednieZadowolenie DESC;

-- Podsumowanie
-- Œrednie zadowolenie ze swojej pracy mieœci siê w przedziale od 6.50 do 7.21 na 10 punktów.
-- Najwy¿szy wynik uzyskali data scientist - 7.21.
-- Najni¿szy wynik wyst¹pi³ wœród business analyst - 6.50 oraz ml/ai engineer - 6.54.
-- Zadowolenie z work-life balance jest zró¿nicowane: najwy¿szy udzia³ zadowolonych odnotowano wœród analytics engineerów - 75%, a najni¿szy wœród ml/ai engineerów - 38.46%.
-- Analiza nadgodzin nie wykaza³a jednolitej zale¿noœci miêdzy ich czêstotliwoœci¹ a poziomem zadowolenia.

/* Perspektywy zawodowe - jak respondenci oceniaj¹ przysz³oœæ bran¿y? */
-- W tej czêœci przedstawione s¹ analizy, jak osoby pracuj¹ce w bran¿y danych postrzegaj¹ jej przysz³oœæ oraz jakie maj¹ plany dotycz¹ce swojej kariery zawodowej. Warto sprawdziæ, czy ocena perspektyw bran¿y ró¿ni siê w zale¿noœci od zajmowanego stanowiska i poziomu doœwiadczenia.

-- Ocena przysz³oœci bran¿y wed³ug stanowiska
-- Celem analizy jest œrednia ocena przysz³oœci bran¿y w skali 1-10 uwzglêdnieniem najni¿szej i najwy¿szej przyznanej oceny.
SELECT
    o.stanowisko,
    COUNT(*) AS LiczbaOsob,
    AVG(TRY_CONVERT(DECIMAL(10,2), p.jak_oceniasz_przysz³oœæ_bran¿y_data_it)) AS SredniaOcenaPrzyszlosci,
    MIN(TRY_CONVERT(DECIMAL(10,2), p.jak_oceniasz_przysz³oœæ_bran¿y_data_it)) AS MinimalnaOcena,
    MAX(TRY_CONVERT(DECIMAL(10,2), p.jak_oceniasz_przysz³oœæ_bran¿y_data_it)) AS MaksymalnaOcena
FROM dbo.ogolne o
INNER JOIN dbo.przyszlosc p ON o.id = p.id
GROUP BY o.stanowisko
ORDER BY SredniaOcenaPrzyszlosci DESC;

-- Chêæ zmiany pracy wed³ug stanowiska
-- Celem badania jest dowiedzenie siê, czy respondenci planuj¹ pozostaæ w obecnej pracy, aktywnie szukaj¹ nowego zatrudnienia, czy jedynie rozwa¿aj¹ zmianê bez presji czasu.
SELECT
    o.stanowisko,
    p.czy_obecnie_rozwa¿asz_zmianê_pracy AS ChecZmianyPracy,
    COUNT(*) AS LiczbaOsob,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY o.stanowisko) AS DECIMAL(5,2)) AS UdzialProcentowy
FROM dbo.ogolne o
INNER JOIN dbo.przyszlosc p ON o.id = p.id
GROUP BY o.stanowisko, p.czy_obecnie_rozwa¿asz_zmianê_pracy
ORDER BY o.stanowisko, LiczbaOsob DESC;

-- Ocena przysz³oœci bran¿y a stanowisko i seniority
-- Celem analizy jest porównanie œredniej oceny przysz³oœci bran¿y w obrêbie poszczególnych poziomów doœwiadczenia, a nastêpnie sprawdzamy, które stanowiska uzyskuj¹ najwy¿sze oceny w ka¿dej grupie poziomu doœwiadczenia.
-- Dziêki analizie mo¿na zauwa¿yæ, ¿e postrzeganie przysz³oœci bran¿y mo¿e ró¿niæ siê nie tylko miêdzy stanowiskami, ale równie¿ miêdzy osobami rozpoczynaj¹cymi karierê a bardziej doœwiadczonymi pracownikami.
WITH Dane AS
(
    SELECT
        o.stanowisko,
        o.poziom_stanowiska_seniority AS Seniority,
        TRY_CONVERT(DECIMAL(10,2), p.jak_oceniasz_przysz³oœæ_bran¿y_data_it ) AS OcenaPrzyszlosci
    FROM dbo.ogolne o
    INNER JOIN dbo.przyszlosc p ON o.id = p.id
	WHERE o.poziom_stanowiska_seniority IS NOT NULL
)
SELECT
    stanowisko,
    Seniority,
    COUNT(OcenaPrzyszlosci) AS LiczbaOcen,
    AVG(OcenaPrzyszlosci) AS SredniaOcena,
    RANK() OVER ( PARTITION BY Seniority ORDER BY AVG(OcenaPrzyszlosci) DESC) AS PozycjaWSwojejGrupieSeniority
FROM Dane
GROUP BY stanowisko, Seniority
ORDER BY Seniority, PozycjaWSwojejGrupieSeniority;

-- Podsumowanie
-- Œrednie oceny przysz³oœci bran¿y mieszcz¹ siê w przedziale od 6.00 do 6.91 na 10 punktów.
-- Najbardziej optymistycznie przysz³oœæ oceniaj¹ data engineerzy - 6.91.
-- Najni¿sza œrednia wystêpuje wœród ml/ai engineerów - 6.00.
-- W wiêkszoœci grup spora czêœæ respondentów rozgl¹da siê za now¹ prac¹, ale bez presji czasu.
-- Najwiêkszy udzia³ osób aktywnie szukaj¹cych pracy wystêpuje wœród ml/ai engineerów - 15.38%.
-- Ocena przysz³oœci bran¿y ró¿ni siê równie¿ w zale¿noœci od seniority, jednak ma³e liczebnoœci niektórych grup ograniczaj¹ mo¿liwoœæ wyci¹gania jednoznacznych wniosków.


-- Podsumowanie projektu - Stanowiska w bran¿y danych: wynagrodzenia, kompetencje i satysfakcja zawodowa
/*   
Przeprowadzona analiza pozwoli³a przyjrzeæ siê bran¿y danych z kilku perspektyw m.in. struktury zatrudnienia, wynagrodzeñ, kompetencji technicznych, organizacji pracy, satysfakcji zawodowej oraz perspektyw na przysz³oœæ.
Na podstawie 297 odpowiedzi badanych mo¿na zauwa¿yæ kilka istotnych wniosków:
- Bran¿a danych jest zró¿nicowana pod wzglêdem stanowisk i kompetencji. Data analyst, data scientist, data engineer czy ml/ai engineer wykonuj¹ odmienne zadania i korzystaj¹ z ró¿nych zestawów technologii.
- Wynagrodzenia ró¿ni¹ siê miêdzy stanowiskami i poziomami doœwiadczenia. Najwy¿sze œrednie odnotowano w obszarze ml/ai i data science, a ni¿sze na stanowisku data analyst.
- SQL i Python to istotne kompetencje w bran¿y danych. SQL jest szczególnie wa¿ny w analizie i pracy z bazami danych, natomiast Python odgrywa du¿¹ rolê w data science, ml/ai i data engineering.
- Praca w bran¿y danych wymaga zarówno samodzielnoœci, jak i wspó³pracy. Respondenci najczêœciej realizuj¹ 2-3 projekty i pracuj¹ w zespo³ach kilkuosobowych.
- Wysokie wynagrodzenie nie musi oznaczaæ wysokiej satysfakcji. Zadowolenie zale¿y równie¿ od innych aspektów pracy, takich jak organizacja obowi¹zków, work-life balance czy charakter wykonywanych zadañ. 
- Przysz³oœæ bran¿y jest oceniana umiarkowanie pozytywnie. Jednoczeœnie czêœæ respondentów rozwa¿a zmianê pracy, co pokazuje, ¿e rozwój zawodowy i poszukiwanie nowych mo¿liwoœci s¹ istotnym elementem rynku pracy.
- Ogólnie wyniki pokazuj¹, ¿e nie istnieje jeden uniwersalny model pracy w bran¿y danych. Poszczególne stanowiska ró¿ni¹ siê wymaganymi umiejêtnoœciami, wynagrodzeniem, zakresem odpowiedzialnoœci i doœwiadczeniami zawodowymi.
*/







