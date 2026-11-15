CREATE TABLE erzeugung (
	datum_von DATE,
	datum_bis DATE,
	energietraeger TEXT,
	erzeugung_mwh NUMERIC,
	jahr INT,
	monat INT
);


CREATE TABLE aussenhandel (
	datum_von DATE,
	datum_bis DATE,
	jahr INT,
	monat INT,
	land TEXT,
	handelsart TEXT,
	handelsmenge_mwh NUMERIC,
	handelsmenge_abs_mwh NUMERIC,
	ist_gesamt BOOLEAN
);

CREATE TABLE strompreise (
	datum_von DATE,
	jahr INT,
	halbjahr TEXT,
	verbrauchskategorie TEXT,
	strompreis_ohne_steuern_eur_kwh NUMERIC,
	strompreis_ohne_ust_eur_kwh NUMERIC,
	strompreis_gesamt_eur_kwh NUMERIC
);

CREATE TABLE strompreisbestandteile (
	datum_von DATE,
	jahr INT,
	verbrauchskategorie TEXT,
	energie_und_vertrieb_eur_kwh NUMERIC,
	netzkosten_eur_kwh NUMERIC,
	steuern_abgaben_umlagen_eur_kwh NUMERIC,
	strompreis_gesamt_eur_kwh NUMERIC,
	ist_gesamt BOOLEAN
);

SELECT * FROM erzeugung;
SELECT * FROM aussenhandel;
SELECT * FROM strompreise;
SELECT * FROM strompreisbestandteile;



SELECT COUNT(*) FROM erzeugung;
SELECT COUNT(*) FROM aussenhandel;
SELECT COUNT(*) FROM strompreise;
SELECT COUNT(*) FROM strompreisbestandteile;