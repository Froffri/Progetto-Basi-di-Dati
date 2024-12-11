/*-------------------------------------------------------------------*/
/*
Analisi dell'efficienza di sequenza
Chiamata per verificarne il funzionamento:

CALL AggiornaEfficienza(@esito);

SELECT * FROM MV_EFFICIENZA;
*/
/*-------------------------------------------------------------------*/

DROP TABLE IF EXISTS MV_EFFICIENZA;
CREATE TABLE MV_EFFICIENZA (
    Sequenza INT PRIMARY KEY,
    ModelloProdotto VARCHAR(10) NOT NULL,
    MarcaProdotto VARCHAR(20) NOT NULL,
    NumRotazioni TINYINT NOT NULL,
    MediaUnitaPerse FLOAT NOT NULL,
    DurataMediaProduzione FLOAT NOT NULL,  /*In giorni*/
    Score FLOAT NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE OR REPLACE VIEW NumRotazioni AS
    WITH OperazioniSequenza AS(
        SELECT S.CodSequenza, O.CodiceOp, SC.Ordine, O.FacciaAppoggio
        FROM sequenza S
        INNER JOIN successione SC ON S.CodSequenza = SC.Sequenza
        INNER JOIN operazione O ON O.CodiceOp = SC.Operazione
    )
    SELECT OS1.CodSequenza, COUNT(*) AS Rotazioni
    FROM OperazioniSequenza OS1
    INNER JOIN OperazioniSequenza OS2 ON (OS1.CodSequenza = OS2.CodSequenza AND OS1.Ordine = OS2.Ordine + 1)
    WHERE OS1.FacciaAppoggio <> OS2.FacciaAppoggio
    GROUP BY(OS1.CodSequenza);

CREATE OR REPLACE VIEW MediaUnitaPerse AS
    WITH LottiPerSequenza AS (
        SELECT S.CodSequenza, L.CodiceLotto
        FROM Sequenza S
        INNER JOIN Lotto L ON L.Sequenza = S.CodSequenza
        WHERE L.DataFineProd IS NOT NULL
        AND L.Tipologia = 'Nuove'
    ),
    UnitaPersePerLotto AS (
        SELECT L.CodiceLotto, COUNT(*) AS NumPerse
        FROM lotto L
        INNER JOIN unita_persa UP ON UP.Lotto = L.CodiceLotto
        WHERE L.DataFineProd IS NOT NULL
        AND L.Tipologia = 'Nuove'
        GROUP BY(L.CodiceLotto)
    ),
    UnitaPerLotto AS (
        SELECT U.Lotto, COUNT(*) AS NumUnita
        FROM unita U
        GROUP BY(U.Lotto)
    )
    SELECT LPS.CodSequenza, AVG(UPPL.NumPerse/UPL.NumUnita) AS MediaPerse
    FROM LottiPerSequenza LPS
    NATURAL JOIN UnitaPersePerLotto UPPL
    INNER JOIN UnitaPerLotto UPL ON UPL.Lotto = LPS.CodiceLotto
    GROUP BY(LPS.CodSequenza);

CREATE OR REPLACE VIEW MediaDurata AS
    WITH LottiPerSequenza AS (
        SELECT S.CodSequenza, L.CodiceLotto, (DATEDIFF(L.DataFineProd, L.DataInizioProd)) AS Durata
        FROM Sequenza S
        INNER JOIN Lotto L ON L.Sequenza = S.CodSequenza
        WHERE L.DataFineProd IS NOT NULL
        AND L.Tipologia = 'Nuove'
    )
    SELECT LPS.CodSequenza, AVG(LPS.Durata) AS Durata
    FROM LottiPerSequenza LPS
    GROUP BY(LPS.CodSequenza);

INSERT INTO MV_EFFICIENZA
    SELECT NR.CodSequenza, S.ModelloProd, S.MarcaProd, NR.Rotazioni, MUP.MediaPerse, MD.Durata, ((NR.Rotazioni * 0.33) + (MUP.MediaPerse * 10) + (MD.Durata * 0.5))
    FROM NumRotazioni NR
    NATURAL JOIN MediaUnitaPerse MUP
    NATURAL JOIN MediaDurata MD
    NATURAL JOIN sequenza S;

DROP PROCEDURE iF EXISTS AggiornaEfficienza;

DELIMITER $$

CREATE PROCEDURE AggiornaEfficienza(OUT _esito BOOLEAN)
BEGIN

DECLARE _esito BOOLEAN DEFAULT(TRUE);

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
    SET _esito = FALSE;
    SELECT 'Errore! Materialized view non aggiornata.';
END;

TRUNCATE TABLE MV_EFFICIENZA;

INSERT INTO MV_EFFICIENZA
    SELECT NR.CodSequenza, S.ModelloProd, S.MarcaProd, NR.Rotazioni, MUP.MediaPerse, MD.Durata, ((NR.Rotazioni * 0.33) + (MUP.MediaPerse * 10) + (MD.Durata * 0.5))
    FROM NumRotazioni NR
    NATURAL JOIN MediaUnitaPerse MUP
    NATURAL JOIN MediaDurata MD
    NATURAL JOIN sequenza S;

END$$

DELIMITER ;

DROP EVENT IF EXISTS DeferredRefreshEfficienza;

DELIMITER $$

CREATE EVENT DeferredRefreshEfficienza
ON SCHEDULE EVERY 7 DAY
STARTS '2021-04-26 23:00:00'
DO
BEGIN
    SET @result = TRUE;

    CALL AggiornaEfficienza(@result);

    IF @result = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore nel refresh di efficienza.';
    END IF;

END$$

DELIMITER ;

/*-------------------------------------------------------------------*/
/*
Case Based Reasoning (CBR)
Chiamata per verificarne il funzionamento:

CALL RetrieveReuse(1);

CALL Revise(1);

/*Inserimento di rimedi per il caso, di cui uno nuovo*/ /*

CALL InserisciNuovoRimedio(1,'NuovoRimedio1');

CALL InserisciRimedio(1, 38);

CALL InserisciRimedio(1, 42);

CALL Retain(1);
*/
/*-------------------------------------------------------------------*/

DROP TABLE IF EXISTS CASO;
CREATE TABLE CASO (
    NumCaso INT PRIMARY KEY AUTO_INCREMENT,
    Guasto INT REFERENCES GUASTO(CodGuasto) ON DELETE SET NULL ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS SINTOMO;
CREATE TABLE SINTOMO (
    CodSintomo INT PRIMARY KEY AUTO_INCREMENT,
    Descrizione VARCHAR(500)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS RAPPRESENTAZIONE;
CREATE TABLE RAPPRESENTAZIONE (
    Caso INT REFERENCES CASO(NumCaso) ON DELETE CASCADE ON UPDATE CASCADE,
    Sintomo INT REFERENCES SINTOMO(CodSintomo) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Caso, Sintomo)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS SOLUZIONE;
CREATE TABLE SOLUZIONE (
    Caso INT REFERENCES CASO(NumCaso) ON DELETE CASCADE ON UPDATE CASCADE,
    Rimedio INT REFERENCES RIMEDIO(CodRimedio) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Caso, Rimedio)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS SINTOMI_INDIVIDUATI;
CREATE TABLE SINTOMI_INDIVIDUATI (
    Ticket INT REFERENCES INTERVENTO_PREVENTIVO(Ticket) ON DELETE NO ACTION ON UPDATE CASCADE,
    Sintomo INT REFERENCES SINTOMO(CodSintomo) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Ticket, Sintomo)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*---------------------------------------------------------*/

DROP PROCEDURE IF EXISTS InserisciSintomo;

DELIMITER $$

CREATE PROCEDURE InserisciSintomo(IN _ticket INT, IN _sintomo INT)
BEGIN 

INSERT INTO SINTOMI_INDIVIDUATI VALUES(_ticket, _sintomo);

END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS InserisciNuovoSintomo;

DELIMITER $$

CREATE PROCEDURE InserisciNuovoSintomo(IN _ticket INT, IN _descrizione VARCHAR(500))
BEGIN 

SET @sintomo = NULL;

SELECT S.CodSintomo INTO @sintomo
FROM sintomo S
WHERE S.Descrizione = _descrizione;

IF @sintomo IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Sintomo già inserito in precedenza';
END IF;

INSERT INTO SINTOMO(Descrizione) VALUES(_descrizione);

SELECT S.CodSintomo INTO @sintomo
FROM sintomo S
WHERE S.Descrizione = _descrizione;

CALL InserisciSintomo(_ticket, @sintomo);

END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS RetrieveReuse;

DELIMITER $$

CREATE PROCEDURE RetrieveReuse(IN _ticket INT)
BEGIN

WITH SintomiAttuali AS (
    SELECT SI.Sintomo
    FROM sintomi_individuati SI
    WHERE SI.Ticket = _ticket
),
SintomiUgualiPerCaso AS (
    SELECT R.Caso, COUNT(*) AS NumSintomiCondivisi
    FROM SintomiAttuali SA
    INNER JOIN rappresentazione R ON R.Sintomo = SA.Sintomo
    GROUP BY(R.Caso)
),
NumeroSintomiPerCaso AS (
    SELECT R.Caso, COUNT(*) AS Numero
    FROM rappresentazione R
    GROUP BY R.Caso
),
CasiSimili AS (
    SELECT SUPC.Caso, (SUPC.NumSintomiCondivisi / NSPC.Numero) * 100 AS PercentualeSomiglianza
    FROM SintomiUgualiPerCaso SUPC 
    NATURAL JOIN NumeroSintomiPerCaso NSPC
    WHERE SUPC.NumSintomiCondivisi / NSPC.Numero >= 0.5
)
SELECT DISTINCT R.CodRimedio, R.Descrizione, CS.PercentualeSomiglianza
FROM CasiSimili CS
NATURAL JOIN soluzione S
INNER JOIN rimedio R ON S.Rimedio = R.CodRimedio
WHERE CS.PercentualeSomiglianza >= ALL (
    SELECT CS1.PercentualeSomiglianza
    FROM CasiSimili CS1
    NATURAL JOIN soluzione S1
    INNER JOIN rimedio R1 ON S1.Rimedio = R1.CodRimedio
    WHERE R1.CodRimedio = R.CodRimedio
)
ORDER BY CS.PercentualeSomiglianza DESC;

END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS Revise;

DELIMITER $$

CREATE PROCEDURE Revise(IN _ticket INT)
BEGIN

WITH SintomiAttuali AS (
    SELECT SI.Sintomo
    FROM sintomi_individuati SI
    WHERE SI.Ticket = _ticket
),
SintomiUgualiPerCaso AS (
    SELECT R.Caso, COUNT(*) AS NumSintomiCondivisi
    FROM SintomiAttuali SA
    INNER JOIN rappresentazione R ON R.Sintomo = SA.Sintomo
    GROUP BY(R.Caso)
),
NumeroSintomiPerCaso AS (
    SELECT R.Caso, COUNT(*) AS Numero
    FROM rappresentazione R
    GROUP BY R.Caso
),
CasiSimili AS (
    SELECT SUPC.Caso, (SUPC.NumSintomiCondivisi / NSPC.Numero) * 100 AS PercentualeSomiglianza
    FROM SintomiUgualiPerCaso SUPC 
    NATURAL JOIN NumeroSintomiPerCaso NSPC
    WHERE SUPC.NumSintomiCondivisi / NSPC.Numero >= 0.5
)
SELECT R.CodRimedio, R.Descrizione
FROM CasiSimili CS 
INNER JOIN Caso C ON CS.Caso = C.NumCaso 
NATURAL JOIN codice_errore CE
INNER JOIN Procedura P ON P.CodiceErrore = CE.CodErrore
INNER JOIN Rimedio R ON R.CodRimedio = P.Rimedio
WHERE R.CodRimedio NOT IN (
    SELECT R1.CodRimedio
    FROM CasiSimili CS1
    NATURAL JOIN soluzione S1
    INNER JOIN rimedio R1 ON S1.Rimedio = R1.CodRimedio
);


END$$

DELIMITER ;

DROP TABLE IF EXISTS RIMEDI_INDIVIDUATI;
CREATE TABLE RIMEDI_INDIVIDUATI (
    Ticket INT REFERENCES INTERVENTO_PREVENTIVO(Ticket) ON DELETE NO ACTION ON UPDATE CASCADE,
    Rimedio INT REFERENCES RIMEDIO(CodRimedio) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Ticket, Rimedio)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP PROCEDURE IF EXISTS InserisciRimedio;

DELIMITER $$

CREATE PROCEDURE InserisciRimedio(IN _ticket INT, IN _rimedio INT)
BEGIN 

INSERT INTO RIMEDI_INDIVIDUATI VALUES(_ticket, _rimedio);

END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS InserisciNuovoRimedio;

DELIMITER $$

CREATE PROCEDURE InserisciNuovoRimedio(IN _ticket INT, IN _descrizione VARCHAR(500))
BEGIN 

SET @rimedio = NULL;

SELECT R.CodRimedio INTO @rimedio
FROM rimedio R
WHERE R.Descrizione = _descrizione;

IF @rimedio IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Rimedio già inserito in precedenza';
END IF;

INSERT INTO RIMEDIO(Descrizione) VALUES(_descrizione);

SELECT R.CodRimedio INTO @rimedio
FROM rimedio R
WHERE R.Descrizione = _descrizione;

CALL InserisciRimedio(_ticket, @rimedio);

END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS Retain;

DELIMITER $$

CREATE PROCEDURE Retain(IN _ticket INT)
BEGIN 

DECLARE finito BOOLEAN DEFAULT(FALSE);
DECLARE dato INT DEFAULT(0);

DECLARE cursoreSintomi CURSOR FOR
    SELECT SI.Sintomo
    FROM sintomi_individuati SI
    WHERE SI.Ticket = _ticket;

DECLARE cursoreRimedi CURSOR FOR
    SELECT RI.Rimedio
    FROM rimedi_individuati RI
    WHERE RI.Ticket = _ticket;

DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finito = TRUE;

SET @somiglianzaMax = NULL;

WITH SintomiAttuali AS (
    SELECT SI.Sintomo
    FROM sintomi_individuati SI
    WHERE SI.Ticket = _ticket
),
SintomiUgualiPerCaso AS (
    SELECT R.Caso, COUNT(*) AS NumSintomiCondivisi
    FROM SintomiAttuali SA
    INNER JOIN rappresentazione R ON R.Sintomo = SA.Sintomo
    GROUP BY(R.Caso)
),
NumeroSintomiPerCaso AS (
    SELECT R.Caso, COUNT(*) AS Numero
    FROM rappresentazione R
    GROUP BY R.Caso
),
CasiSimiliSintomi AS (
    SELECT SUPC.Caso, (SUPC.NumSintomiCondivisi / NSPC.Numero) * 100 AS PercentualeSomiglianzaSintomi
    FROM SintomiUgualiPerCaso SUPC 
    NATURAL JOIN NumeroSintomiPerCaso NSPC
    WHERE SUPC.NumSintomiCondivisi / NSPC.Numero >= 0.5
),
RimediAttuali AS (
    SELECT RI.Rimedio
    FROM rimedi_individuati RI
    WHERE RI.Ticket = _ticket
),
RimediUgualiPerCaso AS (
    SELECT S.Caso, COUNT(*) AS NumRimediCondivisi
    FROM RimediAttuali RA
    INNER JOIN soluzione S ON S.Rimedio = RA.Rimedio
    GROUP BY(S.Caso)
),
NumeroRimediPerCaso AS (
    SELECT S.Caso, COUNT(*) AS Numero
    FROM soluzione S
    GROUP BY S.Caso
),
CasiSimiliRimedi AS (
    SELECT RUPC.Caso, (RUPC.NumRimediCondivisi / NRPC.Numero) * 100 AS PercentualeSomiglianzaRimedi
    FROM RimediUgualiPerCaso RUPC 
    NATURAL JOIN NumeroRimediPerCaso NRPC
    WHERE RUPC.NumRimediCondivisi / NRPC.Numero >= 0.5
),
ConfrontoRimediSintomi AS (
    SELECT CSR.Caso, ((CSR.PercentualeSomiglianzaRimedi + CSS.PercentualeSomiglianzaSintomi) / 2) AS PercentualeSomiglianza
    FROM CasiSimiliRimedi CSR
    NATURAL JOIN CasiSimiliSintomi CSS
)
SELECT MAX(CRS.PercentualeSomiglianza) INTO @somiglianzaMax
FROM ConfrontoRimediSintomi CRS;

IF @somiglianzaMax <= 50 THEN

    SELECT MAX(NumCaso) + 1 INTO @aux
    FROM CASO;

    INSERT INTO CASO VALUES(@aux, NULL);

    OPEN cursoreRimedi;

    preleva1: LOOP

        FETCH cursoreRimedi INTO dato;
        IF finito THEN
            LEAVE preleva1;
        END IF;

        INSERT INTO SOLUZIONE VALUES(@aux, dato);

    END LOOP preleva1;

    CLOSE cursoreRimedi;

    SET finito = FALSE;

    OPEN cursoreSintomi;

    preleva2: LOOP

        FETCH cursoreSintomi INTO dato;
        IF finito THEN
            LEAVE preleva2;
        END IF;

        INSERT INTO RAPPRESENTAZIONE VALUES(@aux, dato);

    END LOOP preleva2;

    CLOSE cursoreSintomi;

END IF;

END$$

DELIMITER ;