--1. vw_strommix_jahr 
-- View: public.vw_strommix_jahr

CREATE OR REPLACE VIEW vw_strommix_jahr AS
SELECT
    jahr,
    energietraeger,
    SUM(erzeugung_mwh) AS erzeugung_mwh,
    	ROUND((SUM(erzeugung_mwh) * 100.0) / NULLIF(SUM(SUM(erzeugung_mwh)) 
		OVER (PARTITION BY jahr), 0), 2) AS anteil_am_strommix
FROM erzeugung
GROUP BY
    jahr,
    energietraeger
ORDER BY
    jahr,
    energietraeger;


-- 3. View: vw_ersatz_kernenergie_vergleich_vor_nach

CREATE OR REPLACE VIEW vw_ersatz_kernenergie_vergleich_vor_nach AS
WITH erzeugung_monat AS (
    SELECT
        CASE WHEN datum_von < DATE '2023-05-01' THEN 'vor_atomausstieg' ELSE 'nach_atomausstieg' END AS periode,
        datum_von,
        SUM(erzeugung_mwh) AS gesamt_erzeugung_mwh,
        SUM(CASE WHEN energietraeger = 'Kernenergie' THEN erzeugung_mwh ELSE 0 END) AS kernenergie_mwh,
        SUM(CASE WHEN energietraeger = 'Erdgas' THEN erzeugung_mwh ELSE 0 END) AS erdgas_mwh,
        SUM(CASE WHEN energietraeger IN ('Biomasse', 'Wasserkraft', 'Wind offshore', 'Wind onshore', 'Photovoltaik', 'Sonstige Erneuerbare') THEN erzeugung_mwh ELSE 0 END) AS erneuerbare_mwh
    FROM erzeugung
    GROUP BY
        CASE WHEN datum_von < DATE '2023-05-01' THEN 'vor_atomausstieg' ELSE 'nach_atomausstieg' END,
        datum_von
),
aussenhandel_monat AS (
    SELECT
        CASE WHEN datum_von < DATE '2023-05-01' THEN 'vor_atomausstieg' ELSE 'nach_atomausstieg' END AS periode,
        datum_von,
        SUM(CASE WHEN handelsart = 'Import' AND land <> 'Gesamt' THEN ABS(handelsmenge_mwh) ELSE 0 END) AS importe_mwh,
        SUM(CASE WHEN handelsart = 'Export' AND land <> 'Gesamt' THEN handelsmenge_mwh ELSE 0 END) AS exporte_mwh
    FROM aussenhandel
    GROUP BY
        CASE WHEN datum_von < DATE '2023-05-01' THEN 'vor_atomausstieg' ELSE 'nach_atomausstieg' END,
        datum_von
),
basis AS (
    SELECT
        e.periode,
        e.datum_von,
        e.gesamt_erzeugung_mwh,
        e.kernenergie_mwh,
        e.erdgas_mwh,
        e.erneuerbare_mwh,
        a.importe_mwh,
        a.exporte_mwh,
        e.gesamt_erzeugung_mwh + a.importe_mwh - a.exporte_mwh AS berechneter_verbrauch_mwh
    FROM erzeugung_monat e
    JOIN aussenhandel_monat a
        ON e.periode = a.periode
       AND e.datum_von = a.datum_von
)
SELECT
    periode,
    ROUND(AVG(gesamt_erzeugung_mwh), 2) AS durchschnitt_gesamt_erzeugung_mwh,
    ROUND(AVG(berechneter_verbrauch_mwh), 2) AS durchschnitt_berechneter_verbrauch_mwh,
    ROUND(AVG(kernenergie_mwh), 2) AS durchschnitt_kernenergie_mwh,
    ROUND(AVG(erneuerbare_mwh), 2) AS durchschnitt_erneuerbare_mwh,
    ROUND(AVG(erdgas_mwh), 2) AS durchschnitt_erdgas_mwh,
    ROUND(AVG(importe_mwh), 2) AS durchschnitt_importe_mwh,
    ROUND(AVG(exporte_mwh), 2) AS durchschnitt_exporte_mwh,
    ROUND(AVG(kernenergie_mwh) / NULLIF(AVG(gesamt_erzeugung_mwh), 0) * 100, 2) AS kernenergie_anteil_prozent,
    ROUND(AVG(erneuerbare_mwh) / NULLIF(AVG(gesamt_erzeugung_mwh), 0) * 100, 2) AS erneuerbare_anteil_prozent,
    ROUND(AVG(erdgas_mwh) / NULLIF(AVG(gesamt_erzeugung_mwh), 0) * 100, 2) AS erdgas_anteil_prozent
FROM basis
GROUP BY periode
ORDER BY
    CASE WHEN periode = 'vor_atomausstieg' THEN 1 ELSE 2 END;


-- 7. View: vw_strompreise_insgesamt_halbjahr

CREATE OR REPLACE VIEW vw_strompreise_insgesamt_halbjahr AS
SELECT
    datum_von,
    jahr,
    halbjahr,
    CASE WHEN datum_von < DATE '2023-05-01' THEN 'vor_atomausstieg' ELSE 'nach_atomausstieg' END AS periode,
    strompreis_gesamt_eur_kwh * 100 AS strompreis_gesamt_cent_kwh
FROM strompreise
WHERE verbrauchskategorie = 'Insgesamt'
ORDER BY datum_von;


--9. View: vw_preisbestandteile_insgesamt

CREATE OR REPLACE VIEW vw_preisbestandteile_insgesamt AS
SELECT
    datum_von,
    jahr,
    ROUND(energie_und_vertrieb_eur_kwh * 100, 2) 
		AS energie_und_vertrieb_cent_kwh,
    ROUND(netzkosten_eur_kwh * 100, 2) 
		AS netzkosten_cent_kwh,
    ROUND(steuern_abgaben_umlagen_eur_kwh * 100, 2) 
		AS steuern_abgaben_umlagen_cent_kwh,
    ROUND(strompreis_gesamt_eur_kwh * 100, 2) 
		AS strompreis_gesamt_cent_kwh
FROM strompreisbestandteile
WHERE ist_gesamt = true
ORDER BY jahr;


-- 13.View: berechnet die prozentuale Veränderung der Brennstoffpreise im Vergleich zum jeweiligen Vorjahr

CREATE OR REPLACE VIEW vw_brennstoffpreise_vorjahr AS
SELECT
    jahr,
    brennstoffart,
    preisindex,
    ROUND(
        (preisindex - LAG(preisindex) OVER (PARTITION BY brennstoffart ORDER BY jahr))
        / LAG(preisindex) OVER (PARTITION BY brennstoffart ORDER BY jahr) * 100,
        2
    ) AS yoy_change
FROM brennstoffpreise;

