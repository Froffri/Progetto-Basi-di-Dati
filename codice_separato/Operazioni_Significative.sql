/*---------------------------------------------------------------------------------------------------------------------------*/

/*Creazione di un intervento preventivo*/

/*
Chiamate per verificare il funzionamento:
CALL NuovoPreventivo(15265, '2021-05-02', '12:00:00', 'MarzKing'); chiamata funzionante
CALL NuovoPreventivo(15265, '2021-05-02', '12:00:00', 'Drw0if'); chiamata non funzionante dato che l'utente non ha acquistato il prodotto
*/

DROP PROCEDURE IF EXISTS NuovoPreventivo;

DELIMITER $$

CREATE PROCEDURE NuovoPreventivo(IN _unitaGuasta INT, IN _data DATE, IN _orario TIME, IN _account VARCHAR(30))
BEGIN

IF _orario NOT BETWEEN '08:00:00' AND '19:00:00' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Orario non accettato.";
END IF;

SELECT COUNT(*) INTO @controlloOrdine
FROM unita U
INNER JOIN ordine O ON U.Ordine = O.CodOrdine
WHERE O.Account = _account
AND U.CodSer = _unitaGuasta;

IF @controlloOrdine = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "L'utente non ha acquistato il prodotto";
END IF;

SET @arrivo = NULL;

SELECT S.DataArrivo INTO @arrivo
FROM unita U
INNER JOIN spedizione S ON U.Spedizione = S.CodSpedizione
WHERE U.CodSer = _unitaGuasta;

IF @arrivo IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Il prodotto non e' ancora arrivato";
END IF;

INSERT INTO ASSISTENZA(Data, Tipologia, Unita) VALUES(CURRENT_DATE, 'Fisica', _unitaGuasta);

SELECT A.Ticket INTO @ticket
FROM assistenza A
WHERE A.Unita = _unitaGuasta
AND A.Data = CURRENT_DATE
AND A.Tipologia = 'Fisica';

INSERT INTO INTERVENTO_PREVENTIVO(Ticket, DataPrev, OrarioPrev) VALUES(@ticket, _data, _orario);

END$$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Creazione di una recensione*/

/*
Chiamate per verificare il funzionamento:
CALL NuovaRecensione('Drw0if', 5, 5, 5, 5, 5, '', '8T', 'OnePlus'); chiamata funzionante
CALL NuovaRecensione('Drw0if', 5, 5, 5, 5, 5, '', 'ABC', 'Rowenta'); chiamata non funzionante dato che l'utente non ha acquistato il prodotto
*/

DROP PROCEDURE IF EXISTS NuovaRecensione;

DELIMITER $$

CREATE PROCEDURE NuovaRecensione(IN _user VARCHAR(30), IN _aff TINYINT, IN _perf TINYINT, IN _exp TINYINT, IN _asp TINYINT, IN _rqp TINYINT, IN _desc VARCHAR(2000), IN _modello VARCHAR(10), IN _marca VARCHAR(20))
BEGIN

SELECT COUNT(*) INTO @valido
FROM acquisto A
WHERE A.Account = _user
AND A.ModelloProd = _modello
AND A.MarcaProd = _marca;

IF @valido = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "L'utente non ha acquistato il prodotto oppure esso non esiste";
END IF;

IF _desc = '' THEN 

    INSERT INTO RECENSIONE(ModelloProd, MarcaProd, Account, Affidabilita, EsperienzaUso, Performance, Aspetto, RapportoQualitaPrezzo)
    VALUES (_modello, _marca, _user, _aff, _exp, _perf, _asp, _rqp);

ELSE

    INSERT INTO RECENSIONE(ModelloProd, MarcaProd, Account, Affidabilita, EsperienzaUso, Performance, Aspetto, RapportoQualitaPrezzo, Descrizione)
    VALUES (_modello, _marca, _user, _aff, _exp, _perf, _asp, _rqp, _desc);

END IF;

END$$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Ricerca e scrittura di un indirizzo (Stored procedure di utility)*/



DROP PROCEDURE IF EXISTS InserimentoIndirizzo;

DELIMITER $$

CREATE PROCEDURE InserimentoIndirizzo(IN _via VARCHAR(50), IN _numCivico VARCHAR(4), IN _Citta VARCHAR(50), IN _CAP NUMERIC(5))
BEGIN

SELECT COUNT(*) INTO @risultato
FROM indirizzo I
WHERE I.Via = _via
AND I.NumCivico = _numCivico
AND I.Citta = _citta;

IF @risultato = 0 THEN
    INSERT INTO INDIRIZZO VALUES(_via, _numCivico, _citta, _CAP);
END IF;

END$$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Effettuazione di un ordine*/

/*
Chiamate per verificare il funzionamento:
CALL NuovoOrdine('MarzKing', 'Via dei frati', '4B', 'Salsomaggiore', 12345, @ordine); creazione dell'ordine
CALL AcquistoUnita(@ordine, 'Z3C25', 'Dyson'); chiamata che associa un prodotto disponibile all'ordine
CALL AcquistoUnita(@ordine, 'ABC', 'Rowenta'); chiamata che crea un'istanza in prodotto_pendente
*/

/*Creazione dell'ordine*/

DROP PROCEDURE IF EXISTS NuovoOrdine;

DELIMITER $$

CREATE PROCEDURE NuovoOrdine(IN _user VARCHAR(30), IN _via VARCHAR(50), IN _numCivico VARCHAR(4), IN _citta VARCHAR(50), IN _CAP NUMERIC(5), OUT _codOrdine INT)
BEGIN


CALL InserimentoIndirizzo(_via, _numCivico, _citta, _CAP);

SET @orario = CURRENT_TIMESTAMP;

INSERT INTO ORDINE(Orario, Account, Via, NumCivico, Citta) VALUES(@orario, _user, _via, _numCivico, _citta);

SELECT O.CodOrdine INTO _codOrdine
FROM ordine O
WHERE O.Account = _user
AND O.Orario = @orario
AND O.Stato = 'In processazione';

END$$

DELIMITER ;

/*Ricerca delle unità per l’ordine*/

DROP PROCEDURE IF EXISTS AcquistoUnita;

DELIMITER $$

CREATE PROCEDURE AcquistoUnita(IN _CodOrdine INT, IN _modello VARCHAR(10), IN _marca VARCHAR(20))
BEGIN

DECLARE numero INT DEFAULT(NULL);
DECLARE unita INT DEFAULT(NULL);

SELECT MAX(PP.Numero) INTO numero
FROM prodotto_pendente PP
WHERE PP.ModelloProd = _modello
AND PP.MarcaProd = _marca
AND PP.Ordine = _codOrdine
AND PP.DataDisponibile IS NULL;

IF numero IS NULL THEN

	SELECT U.CodSer INTO unita
	FROM unita U 
	WHERE U.ModelloProd = _modello
	AND U.MarcaProd = _marca
	AND U.Ordine IS NULL
	ORDER BY U.DataProduzione
	LIMIT 1;

    IF unita IS NOT NULL THEN

        UPDATE UNITA
        SET Ordine = _codOrdine
        WHERE CodSer = unita;

    ELSE

        INSERT INTO PRODOTTO_PENDENTE(ModelloProd, MarcaProd, Ordine, Numero) VALUES(_modello, _marca, _codOrdine, 1);

        UPDATE ORDINE
        SET Stato = 'Pendente'
        WHERE CodOrdine = _codOrdine;

    END IF;

ELSE

    INSERT INTO PRODOTTO_PENDENTE(ModelloProd, MarcaProd, Ordine, Numero) VALUES(_modello, _marca, _codOrdine, numero + 1);

END IF;

END$$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Aggiornamento di Storico Stoccaggio*/

/*
Chiamate per verificare il funzionamento:
CALL AggiornaStorico(); si attiverà automaticamente alle 23:55:00 del 26-04-2021
*/

DROP PROCEDURE IF EXISTS AggiornaStorico;

DELIMITER $$

CREATE PROCEDURE AggiornaStorico()
BEGIN

DECLARE finito BOOLEAN DEFAULT FALSE;
DECLARE lottoAttuale INTEGER;

DECLARE cursoreLotti CURSOR FOR
    SELECT SS.Lotto
    FROM storico_stoccaggio SS
    WHERE SS.DataFineStock IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM unita U
        WHERE U.Lotto = SS.Lotto
        AND U.DataSpedizione IS NULL
    );

DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finito = TRUE;

OPEN cursoreLotti;

preleva: LOOP 

    FETCH cursoreLotti INTO lottoAttuale;
    IF finito THEN
        LEAVE preleva;
    END IF;

    UPDATE STORICO_STOCCAGGIO
    SET DataFineStock = CURRENT_DATE
    WHERE Lotto = lottoAttuale;

END LOOP preleva;

CLOSE cursoreLotti;

END$$

DELIMITER ;

DROP EVENT IF EXISTS AggiornaStoricoStoccaggio;

DELIMITER $$

CREATE EVENT AggiornaStoricoStoccaggio
ON SCHEDULE EVERY 1 DAY
STARTS '2021-04-26 23:55:00'
DO
BEGIN
    CALL AggiornaStorico();
END$$

DELIMITER ;
/*---------------------------------------------------------------------------------------------------------------------------*/
/*Richiesta di assistenza virtuale con codice di errore*/

/*
Chiamate per verificare il funzionamento:
CALL AssistenzaCodErrore(37, 80, 'Drw0if', @rimedi); chiamata funzionante
SELECT @rimedi; i rimedi sono suddivisi con ritorno a capo, ma nella visualizzazione nel select non si vede
*/

DROP PROCEDURE IF EXISTS AssistenzaCodErrore;

DELIMITER $$

CREATE PROCEDURE AssistenzaCodErrore(IN _codErrore INT, IN _unita INT, IN _account VARCHAR(30), INOUT _rimedi VARCHAR(10000))
BEGIN

DECLARE finito BOOLEAN DEFAULT FALSE;
DECLARE rimedio VARCHAR(50) DEFAULT "";

DECLARE contatore INT DEFAULT 0;

DECLARE cursoreRimedi CURSOR FOR 
    SELECT R.Descrizione
    FROM procedura P
    INNER JOIN rimedio R ON R.CodRimedio = P.Rimedio
    WHERE P.CodiceErrore = _codErrore;

DECLARE CONTINUE HANDLER 
FOR NOT FOUND SET finito = TRUE;

SET _rimedi = '';

SELECT COUNT(*) INTO @controlloOrdine
FROM unita U
INNER JOIN ordine O ON U.Ordine = O.CodOrdine
WHERE O.Account = _account
AND U.CodSer = _unita;

IF @controlloOrdine = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "L'utente non ha acquistato il prodotto";
END IF;

SET @arrivo = NULL;

SELECT S.DataArrivo INTO @arrivo
FROM unita U
INNER JOIN spedizione S ON U.Spedizione = S.CodSpedizione
WHERE U.CodSer = _unita;

IF @arrivo IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Il prodotto non e' ancora arrivato";
END IF;

INSERT INTO ASSISTENZA(Data, Tipologia, Unita, CodiceErrore) VALUES(CURRENT_DATE, 'Virtuale', _unita, _codErrore);

OPEN cursoreRimedi;

preleva: LOOP

    FETCH cursoreRimedi INTO rimedio;
    IF finito THEN
        LEAVE preleva;
    END IF;

    SET contatore = contatore + 1;
    
	/*-----------------------------------------------------------------------------------------------------------------------------*/
    SET _rimedi = CONCAT( _rimedi, "Rimedio ", contatore , ": " , rimedio , "." , CHAR(13));
    /*-----------------------------------------------------------------------------------------------------------------------------*/

END LOOP preleva;

CLOSE cursoreRimedi;

END$$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Effettuazione di una richiesta di reso*/

/*
Chiamate per verificare il funzionamento:
CALL RichiestaReso(21, 777, 'ilNerdChuck'); chiamata funzionante

se si vuole verificare il trigger sul diritto di recesso scrivere questo codice

UPDATE RICHIESTA_RESO
    SET Accettata = FALSE
    WHERE CodReso = 1;

CALL RichiestaReso(1, 777, 'ilNerdChuck');
*/

DROP PROCEDURE IF EXISTS RichiestaReso;

DELIMITER $$

CREATE PROCEDURE RichiestaReso(IN _mot INT, IN _unita INT, IN _account VARCHAR(30))
BEGIN

SELECT COUNT(*) INTO @controlloOrdine
FROM unita U
INNER JOIN ordine O ON U.Ordine = O.CodOrdine
WHERE O.Account = _account
AND U.CodSer = _unita;

IF @controlloOrdine = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "L'utente non ha acquistato il prodotto";
END IF;

SET @arrivo = NULL;

SELECT S.DataArrivo INTO @arrivo
FROM unita U
INNER JOIN spedizione S ON U.Spedizione = S.CodSpedizione
WHERE U.CodSer = _unita;

IF @arrivo IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Il prodotto non è ancora arrivato";
END IF;

INSERT INTO RICHIESTA_RESO(Unita, Motivazione) VALUES(_unita, _mot);

END$$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Iscrizione di un utente*/

/*
Chiamata per verificare il funzionamento:
CALL IscrizioneUtente('PPPPPPPPPPPPPPPP', 'Nome', 'Cognome', '2000-01-01', 5555555555, 'Via', '5A', 'Citta', 52022, 'NumDooc', 'Patente', '2022-01-01', 'Ente rilascio', 'NomeAccount', 'Domanda di sicurezza', 'Risposta di sicurezza', 'Password'); chiamata funzionante
*/

DROP PROCEDURE IF EXISTS IscrizioneUtente;

DELIMITER $$

CREATE PROCEDURE IscrizioneUtente(IN _codFiscale CHAR(16), IN _nome VARCHAR(20), IN _cognome VARCHAR(30) , IN _dataNascita DATE , IN _numTel NUMERIC(10), IN _via VARCHAR(50), IN _numCivico VARCHAR(4), IN _citta VARCHAR(50), IN _CAP NUMERIC(5), IN _numDoc VARCHAR(10) , IN _tipo VARCHAR(20), IN _scadenza DATE, IN _enteRilascio VARCHAR(50),IN _account VARCHAR(30), IN _domSic VARCHAR(50), IN _rispSic VARCHAR(30), IN _password VARCHAR(30))
BEGIN

SET @numdoc = NULL;

SET @codfiscale = NULL;

SET @username = NULL;

SELECT TRUE INTO @numdoc
FROM documento D
WHERE D.NumDoc = _numDoc;

SELECT TRUE INTO @codfiscale
FROM utente U
WHERE U.CodFiscale = _codFiscale;

SELECT TRUE INTO @username
FROM account A
WHERE A.Username = _account;

IF @numdoc OR @codfiscale OR @username THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Iscrizione fallita.";
END IF;

CALL InserimentoIndirizzo(_via, _numCivico, _citta, _CAP);

INSERT INTO DOCUMENTO VALUES(_numDoc, _tipo, _scadenza, _enteRilascio);

INSERT INTO UTENTE(CodFiscale, Nome, Cognome, DataNascita, NumTel, Via, NumCivico, Citta, Documento) VALUES(_codFiscale, _nome, _cognome, _dataNascita, _numTel, _via, _numCivico, _citta, _numDoc);

INSERT INTO ACCOUNT(Username, DomSic, RispSic, Password, Utente) VALUES(_account, _domSic, _rispSic, _password, _codFiscale);

END$$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Inserimento delle unità di un lotto nel database*/

/*
Chiamate per verificare il funzionamento:
CALL InserimentoUnita(1, 30); chiamata funzionante
CALL InserimentoUnita(4, 3); non funziona perché il lotto è già stato riempito
*/

DROP PROCEDURE IF EXISTS InserimentoUnita;

DELIMITER $$

CREATE PROCEDURE InserimentoUnita(IN _codLotto INT, IN _numeroUnita SMALLINT)
BEGIN

DECLARE counter INT DEFAULT 0;

IF _numeroUnita <= 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Numero unità negativo o nullo.';
END IF;

SET @tipo = NULL;

SELECT L.Tipologia INTO @tipo
FROM lotto L
WHERE L.CodiceLotto = _codLotto;

IF @tipo <> 'Nuove' THEN
BEGIN
	SET @text = CONCAT('Impossibile inserire nuove unità in un lotto di tipologia [', @tipo, '].');
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = @text;
END;
END IF;

SET @data = NULL;

SELECT L.DataFineProd INTO @data
FROM lotto L
WHERE L.CodiceLotto = _codLotto;

IF @data IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Il lotto è già stato riempito';
END IF;

UPDATE LOTTO
SET DataFineProd = CURRENT_TIMESTAMP
WHERE CodiceLotto = _codLotto;

SET @modello = NULL;

SELECT S.ModelloProd INTO @modello
FROM lotto L
INNER JOIN sequenza S ON L.Sequenza = S.CodSequenza
WHERE L.CodiceLotto = _codLotto;

SET @marca = NULL;

SELECT S.MarcaProd INTO @marca
FROM lotto L
INNER JOIN sequenza S ON L.Sequenza = S.CodSequenza
WHERE L.CodiceLotto = _codLotto;

WHILE _numeroUnita > counter
DO

    INSERT INTO UNITA(ModelloProd, MarcaProd, Lotto) VALUES(@modello, @marca, _codLotto);

    SET counter = counter + 1;

END WHILE;

END$$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/


DROP PROCEDURE IF EXISTS AssegnaTecnici;

DELIMITER $$

CREATE PROCEDURE AssegnaTecnici()
BEGIN
	
    DECLARE finito boolean DEFAULT(FALSE);
    DECLARE intervento INT;
    
    DECLARE cursorePreventivi CURSOR FOR
		SELECT IP.Ticket
        FROM intervento_preventivo IP
        WHERE IP.DataPrev BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL 6 DAY;
        
	DECLARE cursoreRiparativi CURSOR FOR
		SELECT IR.Ticket
        FROM intervento_riparativo IR
        WHERE IR.DataRip BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL 6 DAY;
        
	DECLARE CONTINUE HANDLER
    FOR NOT FOUND SET finito = TRUE;
    
    OPEN cursorePreventivi;
    
    assPrev: LOOP
    
		FETCH cursorePreventivi INTO intervento;
        IF finito THEN
			LEAVE assPrev;
		END IF;
        
        SELECT IP.DataPrev INTO @data
        FROM intervento_preventivo IP
        WHERE IP.Ticket = intervento;
        
        SELECT IP.OrarioPrev INTO @orario
        FROM intervento_preventivo IP
        WHERE IP.Ticket = intervento;
        
        SELECT CP.AreaGeografica INTO @areaG
        FROM assistenza A
        INNER JOIN unita U ON A.Unita = U.CodSer
        INNER JOIN ordine O ON O.CodOrdine = U.Ordine
        INNER JOIN account ACC ON ACC.Username = O.Account
        INNER JOIN utente UT ON UT.CodFiscale = ACC.Utente
        INNER JOIN indirizzo I ON (I.Via = UT.Via AND I.NumCivico = UT.NumCivico AND I.Citta = UT.Citta)
        INNER JOIN codice_postale CP ON CP.CAP = I.CAP
        WHERE A.Ticket = intervento;
        
        SET @tecnico = NULL;
        
        SELECT T.ID INTO @tecnico
        FROM tecnico T
        WHERE T.AreaGeografica = @areaG
        AND NOT EXISTS (
			SELECT 1
            FROM intervento_preventivo IP
            WHERE IP.Tecnico = T.ID
			AND IP.DataPrev = @data
			AND IP.OrarioPrev BETWEEN @orario AND @orario + INTERVAL 1 HOUR
        )
        LIMIT 1;
        
        IF @tecnico IS NOT NULL THEN
			UPDATE intervento_preventivo
            SET Tecnico = @tecnico
            WHERE Ticket = intervento;
		END IF;
    
    END LOOP assPrev;
    
    CLOSE cursorePreventivi;
    
    SET finito = FALSE;
    
    OPEN cursoreRiparativi;
    
    assRip: LOOP
    
		FETCH cursoreRiparativi INTO intervento;
        IF finito THEN
			LEAVE assRip;
		END IF;
        
        SELECT IR.DataRip INTO @data
        FROM intervento_riparativo IR
        WHERE IR.Ticket = intervento;
        
        SELECT IR.OrarioRip INTO @orario
        FROM intervento_riparativo IR
        WHERE IR.Ticket = intervento;
        
        SELECT CP.AreaGeografica INTO @areaG
        FROM assistenza A
        INNER JOIN unita U ON A.Unita = U.CodSer
        INNER JOIN ordine O ON O.CodOrdine = U.Ordine
        INNER JOIN account ACC ON ACC.Username = O.Account
        INNER JOIN utente UT ON UT.CodFiscale = ACC.Utente
        INNER JOIN indirizzo I ON (I.Via = UT.Via AND I.NumCivico = UT.NumCivico AND I.Citta = UT.Citta)
        INNER JOIN codice_postale CP ON CP.CAP = I.CAP
        WHERE A.Ticket = intervento;
        
        SET @tecnico = NULL;
        
        SELECT T.ID INTO @tecnico
        FROM tecnico T
        WHERE T.AreaGeografica = @areaG
        AND NOT EXISTS (
			SELECT 1
            FROM intervento_riparativo IR
            WHERE IR.Tecnico = T.ID
			AND IR.DataRip = @data
			AND IR.OrarioRip BETWEEN @orario AND @orario + INTERVAL 2 HOUR
        )
        LIMIT 1;
        
        IF @tecnico IS NOT NULL THEN
			UPDATE intervento_riparativo
            SET Tecnico = @tecnico
            WHERE Ticket = intervento;
		END IF;
    
    END LOOP assRip;
    
    CLOSE cursoreRiparativi;
    
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS EfficienzaLinea;

DELIMITER $$

CREATE PROCEDURE EfficienzaLinea(IN _linea INT, OUT score INT)
BEGIN
	
    WITH numPerse AS (
		SELECT L.CodiceLotto, COUNT(*) AS NumeroPerse
        FROM lotto L
        INNER JOIN unita_persa UP ON L.CodiceLotto = UP.Lotto
        WHERE L.Linea = _linea
        GROUP BY L.CodiceLotto
    ),
    numTot AS (
		SELECT L.CodiceLotto, COUNT(*) AS NumeroTot
        FROM lotto L
        INNER JOIN unita U ON L.CodiceLotto = U.Lotto
		WHERE L.Linea = _linea
        GROUP BY L.CodiceLotto
    )
    SELECT AVG(NP.NumeroPerse/NT.NumeroTot) * 100 INTO score
    FROM numPerse NP
    NATURAL JOIN numTot NT;
    
END$$

DELIMITER ;