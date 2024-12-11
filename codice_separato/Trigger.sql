DROP TRIGGER IF EXISTS FacciaValida;

/*Un’operazione non può agire o poggiare su una faccia che il prodotto a cui si riferisce non ha.*/

DELIMITER $$

CREATE TRIGGER FacciaValida 
BEFORE INSERT ON PERTINENZA
FOR EACH ROW
BEGIN

SET @facciaOp = NULL;

/*Prendo la faccia su cui opera l'operazione*/
SELECT O.FacciaOp INTO @facciaOp
FROM operazione O
WHERE O.CodiceOp = NEW.Operazione;

SET @facceProd = NULL;

/*Prendo il numero di facce del prodotto*/
SELECT P.Facce INTO @facceProd
FROM prodotto P
WHERE P.Modello = NEW.ModelloProd
AND P.Marca = NEW.MarcaProd;

SET @facciaAppoggio = NULL;

SELECT O.FacciaAppoggio INTO @facciaAppoggio
FROM operazione O
WHERE O.CodiceOp = NEW.Operazione;

IF (@facciaOp > @facceProd OR @facciaAppoggio > @facceProd) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Operazione non agisce su faccia valida';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*Un utente deve avere un’età compresa tra 18 e 120*/

DROP TRIGGER IF EXISTS EtaValidaUtente;

DELIMITER $$

CREATE TRIGGER EtaValidaUtente
BEFORE INSERT ON UTENTE
FOR EACH ROW
BEGIN

IF (NEW.DataNascita > CURRENT_DATE - INTERVAL 18 YEAR OR NEW.DataNascita < CURRENT_DATE - INTERVAL 120 YEAR) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Eta utente non valida';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*
Lo stato di un ordine passa attraverso i seguenti valori: [“In processazione”, “In preparazione”, “Spedito”, “Evaso”, "Pendente"]. 
Un ordine deve necessariamente seguire la precedente sequenza di stati
*/

/*Inserimento*/

DROP TRIGGER IF EXISTS StatoNuovoOrdine;

DELIMITER $$

CREATE TRIGGER StatoNuovoOrdine
BEFORE INSERT ON ORDINE
FOR EACH ROW
BEGIN

IF NEW.Stato <> 'In processazione' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato iniziale non valido';
END IF;

END $$

DELIMITER ;

/*Aggiornamento*/

DROP TRIGGER IF EXISTS SequenzaStatoOrdine;

DELIMITER $$

CREATE TRIGGER SequenzaStatoOrdine
BEFORE UPDATE ON ORDINE
FOR EACH ROW
BEGIN

IF OLD.Stato = 'In processazione' AND (NEW.Stato <> 'In preparazione' AND NEW.Stato <> 'Pendente') THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato successivo non valido';
END IF;

IF OLD.Stato = 'In preparazione' AND NEW.Stato <> 'Spedito' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato successivo non valido';
END IF;

IF OLD.Stato = 'Pendente' AND NEW.Stato <> 'In processazione' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato successivo non valido';
END IF;

IF OLD.Stato = 'Spedito' AND NEW.Stato <> 'Evaso' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato successivo non valido';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*
Lo stato di una spedizione passa attraverso i seguenti valori: [“Spedita”, “In transito”, “In consegna”, “Consegnata”]. 
Una spedizione deve necessariamente seguire la precedente sequenza di stati
*/

/*Inserimento*/

DROP TRIGGER IF EXISTS StatoNuovaSpedizione;

DELIMITER $$

CREATE TRIGGER StatoNuovaSpedizione
BEFORE INSERT ON SPEDIZIONE
FOR EACH ROW
BEGIN

IF NEW.Stato <> 'Spedita' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato iniziale non valido';
END IF;

END $$

DELIMITER ;

/*Aggiornamento*/

DROP TRIGGER IF EXISTS SequenzaStatoSpedizione;

DELIMITER $$

CREATE TRIGGER SequenzaStatoSpedizione
BEFORE UPDATE ON SPEDIZIONE
FOR EACH ROW
BEGIN

IF OLD.Stato = 'Spedita' AND NEW.Stato <> 'In transito' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato successivo non valido';
END IF;

IF OLD.Stato = 'In transito' AND NEW.Stato <> 'In consegna' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato successivo non valido';
END IF;

IF OLD.Stato = 'In consegna' AND NEW.Stato <> 'Consegnata' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Stato successivo non valido';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*
Per ciascuna stazione di montaggio, la somma delle durate di tutte le operazioni
eseguite su di essa non può superare il T della linea di produzione cui la stazione appartiene.
*/

DROP TRIGGER IF EXISTS ControlloDurata;

DELIMITER $$

CREATE TRIGGER ControlloDurata
BEFORE INSERT ON ESECUZIONE
FOR EACH ROW
BEGIN

SET @sommaDurate = NULL;

SELECT SUM(O.DurataOp) INTO @sommaDurate
FROM esecuzione E 
INNER JOIN operazione O ON O.CodiceOp = E.Operazione
WHERE E.NumStazione = NEW.Stazione
AND E.Linea = NEW.Linea;

SET @T = NULL;

SELECT LP.T INTO @T
FROM Linea_Produzione LP
WHERE LP.CodLinea = NEW.Linea;

IF @T < @sommaDurate THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'La durata eccede T';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*La tipologia di assistenza deve essere coerente.*/

/*Inserimento di assistenza*/

DROP TRIGGER IF EXISTS ControlloInserimentoAssistenza;

DELIMITER $$

CREATE TRIGGER ControlloInserimentoAssistenza
BEFORE INSERT ON ASSISTENZA
FOR EACH ROW
BEGIN

IF NEW.Tipologia = 'Fisica' AND (NEW.Casistica IS NOT NULL OR NEW.CodiceErrore IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Assegnamento errato';
END IF;

IF NEW.Casistica IS NOT NULL AND NEW.CodiceErrore IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Assegnamento errato';
END IF;

END $$

DELIMITER ;

/*Aggiornamento di assistenza*/

DROP TRIGGER IF EXISTS ControlloAggiornamentoAssistenza;

DELIMITER $$

CREATE TRIGGER ControlloAggiornamentoAssistenza
BEFORE UPDATE ON ASSISTENZA
FOR EACH ROW
BEGIN

IF (OLD.Tipologia = 'Virtuale' AND NEW.Tipologia = 'Fisica') OR (OLD.Tipologia = 'Fisica' AND NEW.Tipologia = 'Virtuale') THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Impossibile cambiare tipologia di assistenza';
END IF;

IF OLD.Tipologia = 'Fisica' AND (NEW.Casistica IS NOT NULL OR NEW.CodiceErrore IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Impossibile collegare metodi di assistenza virtuale a una procedura fisica';
END IF;

IF OLD.Tipologia = 'Virtuale' AND ((NEW.Casistica IS NOT NULL AND NEW.CodiceErrore IS NOT NULL) OR (OLD.Casistica IS NOT NULL AND NEW.CodiceErrore IS NOT NULL) OR (NEW.Casistica IS NOT NULL AND OLD.CodiceErrore IS NOT NULL)) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Impossibile aggiornare';
END IF;

END $$

DELIMITER ;

/*Inserimento su intervento preventivo*/

DROP TRIGGER IF EXISTS ControlloInserimentoIntPrev;

DELIMITER $$

CREATE TRIGGER ControlloInserimentoIntPrev
BEFORE INSERT ON INTERVENTO_PREVENTIVO
FOR EACH ROW
BEGIN

SET @tipologia = NULL;

SELECT A.Tipologia INTO @tipologia
FROM assistenza A
WHERE A.Ticket = NEW.Ticket;

IF @tipologia = 'Virtuale' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Impossibile collegare metodi di assistenza fisica a una procedura virtuale';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*
La data di un ordine delle parti non può essere posta prima dell’intervento preventivo 
e neanche dopo la consegna (prevista e effettiva) di esse
*/

/*Inserimento su ORDINE_PARTI*/

DROP TRIGGER IF EXISTS ControlloInserimentoOrdineParti;

DELIMITER $$

CREATE TRIGGER ControlloInserimentoOrdineParti
BEFORE INSERT ON ORDINE_PARTI
FOR EACH ROW
BEGIN

SET @dataPreventivo = NULL;

SELECT IP.DataPrev INTO @dataPreventivo
FROM intervento_preventivo IP
WHERE IP.Ticket = NEW.Ticket;

IF @dataPreventivo > NEW.Data THEN  /*AVEVAMO SBAGLIATO*/
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data ordine non valida';
END IF;

END $$

DELIMITER ;

/*Aggiornamento di ORDINE_PARTI*/

DROP TRIGGER IF EXISTS ControlloAggiornamentoOrdineParti;

DELIMITER $$

CREATE TRIGGER ControlloAggiornamentoOrdineParti
BEFORE UPDATE ON ORDINE_PARTI
FOR EACH ROW
BEGIN

IF NEW.DataConsEff < OLD.Data THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data consegna effettiva non valida';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*Un tecnico non può effettuare più interventi nello stesso orario*/

DROP TRIGGER IF EXISTS ControlloInterventiPrevTecnici;

DELIMITER $$

CREATE TRIGGER ControlloInterventiPrevTecnici
BEFORE UPDATE ON INTERVENTO_PREVENTIVO
FOR EACH ROW
BEGIN

SELECT COUNT(*) INTO @interventiSovrapposti
FROM intervento_preventivo IP
WHERE IP.Tecnico = NEW.Tecnico
AND IP.DataPrev = OLD.DataPrev
AND IP.OrarioPrev = OLD.OrarioPrev;  /*NON PROPRIAMENTE GIUSTO*/


IF @interventiSovrapposti <> 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Orario sovrapposto';
END IF;

END $$

DELIMITER ;

DROP TRIGGER IF EXISTS ControlloInterventiRipTecnici;

DELIMITER $$

CREATE TRIGGER ControlloInterventiRipTecnici
BEFORE UPDATE ON INTERVENTO_RIPARATIVO
FOR EACH ROW
BEGIN

SELECT COUNT(*) INTO @interventiSovrapposti
FROM intervento_riparativo IR
WHERE IR.Tecnico = NEW.Tecnico
AND IR.DataRip = OLD.DataRip
AND IR.OrarioRip = OLD.OrarioRip; /*NON PROPRIAMENTE GIUSTO*/


IF @interventiSovrapposti <> 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Orario sovrapposto';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*Il costo di un intervento riparativo non può essere maggiore del 150% del preventivo ad esso relativo.*/

DROP TRIGGER IF EXISTS ControlloCostoIntervento;

DELIMITER $$

CREATE TRIGGER ControlloCostoIntervento
BEFORE INSERT ON RICEVUTA
FOR EACH ROW
BEGIN

SET @preventivo = NULL;

SELECT IP.Preventivo INTO @preventivo
FROM intervento_preventivo IP
WHERE IP.Ticket = NEW.Ticket;

IF 1.5 * @preventivo < NEW.Costo THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Il costo supera il tetto massimo';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*
Se l’utente fa una richiesta di reso su un prodotto che gli è arrivato fino a 30 giorni prima,
la richiesta è automaticamente accettata per il diritto di recesso,
a patto che il cliente lo specifichi come motivazione
*/

DROP TRIGGER IF EXISTS DirittoRecesso;

DELIMITER $$

CREATE TRIGGER DirittoRecesso
BEFORE INSERT ON RICHIESTA_RESO
FOR EACH ROW
BEGIN

SELECT M.CodMotivazione INTO @recesso
FROM motivazione M
WHERE M.Nome = 'Recesso';

IF NEW.Motivazione = @recesso THEN

    SET @dataArrivo = NULL;

    SELECT S.DataArrivo INTO @dataArrivo
    FROM unita U
    INNER JOIN spedizione S ON U.Spedizione = S.CodSpedizione
    WHERE U.CodSer = NEW.Unita;

    IF (@dataArrivo IS NOT NULL AND @dataArrivo >= CURRENT_DATE - INTERVAL 30 DAY) THEN
        SET @risultato = TRUE;
    ELSE
        SET @risultato = FALSE;
    END IF;

    SET NEW.Accettata = @risultato;

END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Per fare un intervento riparativo, il preventivo deve essere accettato.*/

DROP TRIGGER IF EXISTS ControlloRiparativo;

DELIMITER $$

CREATE TRIGGER ControlloRiparativo
BEFORE INSERT ON INTERVENTO_RIPARATIVO
FOR EACH ROW
BEGIN

SET @accettato = NULL;

SELECT IP.Accettato INTO @accettato
FROM intervento_preventivo IP
WHERE IP.Ticket = NEW.Ticket;

IF IFNULL(@accettato , FALSE) = FALSE THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Preventivo non accettato';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Il prezzo di un’unità ricondizionata non può essere maggiore del prezzo di listino dell’unità nuova.*/

DROP TRIGGER IF EXISTS ControlloPrezzoUnitaRicondizionata;

DELIMITER $$

CREATE TRIGGER ControlloPrezzoUnitaRicondizionata
BEFORE INSERT ON UNITA_RICONDIZIONATA
FOR EACH ROW
BEGIN

SET @prezzoNuovo = NULL;

SELECT P.Prezzo INTO @prezzoNuovo
FROM unita U 
INNER JOIN prodotto P ON (U.ModelloProd = P.Modello AND U.MarcaProd = P.Marca)
WHERE U.CodSer = NEW.Unita;

IF @prezzoNuovo <= NEW.Prezzo THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Prezzo troppo alto';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*
Se un tipo di prodotto ricondizionato prevede una suddivisione in due categorie
(una che include le unità che hanno anche ricevuto un ricondizionamento estetico, l’altra quelle che non lo hanno ricevuto),
le unità della prima categoria devono avere un prezzo inferiore a quello di listino del prodotto,
ma superiore a quelle della seconda categoria
*/
DROP TRIGGER IF EXISTS ControlloPrezzoCategoria;

DELIMITER $$

CREATE TRIGGER ControlloPrezzoCategoria
BEFORE INSERT ON UNITA_RICONDIZIONATA
FOR EACH ROW
BEGIN

SET @modello = NULL;

SELECT U.ModelloProd INTO @modello
FROM unita U
WHERE U.CodSer = NEW.Unita;

SET @marca = NULL;

SELECT U.MarcaProd INTO @marca
FROM unita U
WHERE U.CodSer = NEW.Unita;

SET @risultato = TRUE;

IF NEW.Categoria = 'A' THEN

    SET @prezzoMaxB = NULL;

    SELECT MAX(UR.Prezzo) INTO @prezzoMaxB
    FROM unita_ricondizionata UR
    INNER JOIN unita U ON U.CodSer = UR.Unita
    WHERE @modello = U.ModelloProd
    AND @marca = U.MarcaProd
    AND UR.Categoria = 'B';

    IF NEW.Prezzo <= @prezzoMaxB THEN
        SET @risultato = FALSE;
    END IF;

ELSE IF NEW.Categoria = 'B' THEN

    SET @prezzoMinA = NULL;

    SELECT MIN(UR.Prezzo) INTO @prezzoMinA
    FROM unita_ricondizionata UR
    INNER JOIN unita U ON U.CodSer = UR.Unita
    WHERE @modello = U.ModelloProd
    AND @marca = U.MarcaProd
    AND UR.Categoria = 'A';

    IF NEW.Prezzo >= @prezzoMinA THEN
        SET @risultato = FALSE;
    END IF;


	END IF;
END IF;


IF @risultato = FALSE THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Prezzo categoria non valido';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Il documento dell’utente non deve essere scaduto.*/

DROP TRIGGER IF EXISTS ControlloScadenzaDocumento;

DELIMITER $$

CREATE TRIGGER ControlloScadenzaDocumento
BEFORE INSERT ON DOCUMENTO
FOR EACH ROW
BEGIN

IF NEW.Scadenza < CURRENT_DATE THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Documento scaduto';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Un prodotto non può essere prodotto in una data posteriore alla data odierna.*/

DROP TRIGGER IF EXISTS ControlloDataProduzioneUnita;

DELIMITER $$

CREATE TRIGGER ControlloDataProduzioneUnita
BEFORE INSERT ON UNITA
FOR EACH ROW
BEGIN

IF NEW.DataProduzione > CURRENT_DATE THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data produzione non valida';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Il prezzo di una parte non può essere inferiore alla somma dei prezzi complessivi dei materiali che la compongono (relativi alla loro quantità).*/

DROP TRIGGER IF EXISTS ControlloPrezzoParte;

DELIMITER $$

CREATE TRIGGER ControlloPrezzoParte
AFTER INSERT ON PARTE
FOR EACH ROW
BEGIN

SET @sommaPrezziMateriali = NULL;

SELECT SUM((C.Quantita / 1000) * M.ValoreAlKg) INTO @sommaPrezziMateriali
FROM composizione C
INNER JOIN materiale M ON M.NomeMateriale = C.Materiale
WHERE C.Parte = NEW.CodParte;

IF @sommaPrezziMateriali > NEW.Prezzo THEN
    UPDATE PARTE
    SET Prezzo = @sommaPrezziMateriali
    WHERE CodParte = NEW.CodParte;
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Un operaio deve avere almeno 18 anni.*/

DROP TRIGGER IF EXISTS ControlloEtaOperaio;

DELIMITER $$

CREATE TRIGGER ControlloEtaOperaio
BEFORE INSERT ON OPERAIO
FOR EACH ROW
BEGIN

IF NEW.DataNascita > CURRENT_DATE - INTERVAL 18 YEAR THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Operaio non maggiorenne';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Un tecnico deve avere almeno 18 anni.*/

DROP TRIGGER IF EXISTS ControlloEtaTecnico;

DELIMITER $$

CREATE TRIGGER ControlloEtaTecnico
BEFORE INSERT ON TECNICO
FOR EACH ROW
BEGIN

IF NEW.DataNascita > CURRENT_DATE - INTERVAL 18 YEAR THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Tecnico non maggiorenne';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Una spedizione non può arrivare a destinazione prima di essere partita.*/

DROP TRIGGER IF EXISTS ControlloArrivoSpedizione;

DELIMITER $$

CREATE TRIGGER ControlloArrivoSpedizione
BEFORE UPDATE ON SPEDIZIONE
FOR EACH ROW
BEGIN

IF (NEW.DataArrivo IS NOT NULL AND NEW.DataArrivo < OLD.DataPartenza) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data di arrivo non valida';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Nel processo di tracking ogni data che viene inserita non deve essere precedente alle date già presenti relative alla stessa spedizione.*/

DROP TRIGGER IF EXISTS ControlloTracking;

DELIMITER $$

CREATE TRIGGER ControlloTracking
BEFORE INSERT ON TRACKING
FOR EACH ROW
BEGIN

SET @ultimoTransito = NULL;

SELECT MAX(T.DataTransito) INTO @ultimoTransito
FROM tracking T 
WHERE T.Spedizione = NEW.Spedizione;

IF (@ultimoTransito IS NOT NULL AND @ultimoTransito >= NEW.DataTransito) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data e orario transito non validi';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Un’unità non può essere persa fuori dal tempo di produzione del lotto a cui appartiene.*/

/*Inserimento dell'unità persa*/
DROP TRIGGER IF EXISTS ControlloOrarioUnitaPersa;

DELIMITER $$

CREATE TRIGGER ControlloOrarioUnitaPersa
BEFORE INSERT ON UNITA_PERSA
FOR EACH ROW
BEGIN

SET @dataInizioProd = NULL;

SELECT L.DataInizioProd INTO @dataInizioProd
FROM lotto L
WHERE NEW.Lotto = L.CodiceLotto;

IF @dataInizioProd >= NEW.Orario THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data e orario non validi';
END IF;

END $$

DELIMITER ;

/*Aggiornamento del Lotto per l'inserimento di DataFineProd*/

DROP TRIGGER IF EXISTS ControlloInserimentoDataFineProdLotto;

DELIMITER $$

CREATE TRIGGER ControlloInserimentoDataFineProdLotto
BEFORE UPDATE ON LOTTO
FOR EACH ROW
BEGIN

SET @ultimaPersa = NULL;

SELECT MAX(UP.Orario) INTO @ultimaPersa
FROM unita_persa UP
WHERE UP.Lotto = OLD.CodiceLotto;

IF (@ultimaPersa IS NOT NULL AND @ultimaPersa >= NEW.DataFineProd) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data e orario non validi';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*I tempi minimi, massimi e medie di operazioni campione devono essere coerenti*/

/*Inserimento delle operazioni campione*/
DROP TRIGGER IF EXISTS ControlloInserimentoCampione;

DELIMITER $$

CREATE TRIGGER ControlloInserimentoCampione
BEFORE INSERT ON CAMPIONE
FOR EACH ROW
BEGIN

IF (NEW.TempoMin > NEW.TempoMed OR NEW.TempoMin > NEW.TempoMax) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Tempo minimo non valido';
END IF;

IF (NEW.TempoMax < NEW.TempoMed OR NEW.TempoMax < NEW.TempoMin) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Tempo massimo non valido';
END IF;

IF NEW.TempoMed NOT BETWEEN NEW.TempoMin AND NEW.TempoMax THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Tempo medio non valido';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Quando si vuole rimuovere dal database una certa formula di estensione di garanzia, essa non deve essere attualmente attiva su nessuna unità*/

DROP TRIGGER IF EXISTS EliminazioneEstensioneGaranzia;

DELIMITER $$

CREATE TRIGGER EliminazioneEstensioneGaranzia
BEFORE DELETE ON ESTENSIONE_GARANZIA
FOR EACH ROW
BEGIN

SET @ultimaEstensione = NULL;

SELECT MAX(I.DataInizio) INTO @ultimaEstensione
FROM incremento I
WHERE I.EstGaranzia = OLD.CodEstensione;

IF (@ultimaEstensione IS NOT NULL AND @ultimaEstensione + INTERVAL OLD.Mesi MONTH >= CURRENT_DATE) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Estensione ancora legata a una o piu' unita'";
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Le parti sostituite in un'unità ricondizionata devono far parte della struttura di quel prodotto*/

DROP TRIGGER IF EXISTS ControlloValiditaSostituzione;

DELIMITER $$

CREATE TRIGGER ControlloValiditaSostituzione
BEFORE INSERT ON SOSTITUZIONE
FOR EACH ROW
BEGIN

SET @modello = NULL;

SELECT U.ModelloProd INTO @modello
FROM unita U
WHERE U.CodSer = NEW.UnitaRicondizionata;

SET @marca = NULL;

SELECT U.MarcaProd INTO @marca
FROM unita U
WHERE U.CodSer = NEW.UnitaRicondizionata;

SELECT COUNT(*) INTO @risultato
FROM struttura S
WHERE S.Parte = NEW.Parte
AND S.ModelloProd = @modello
AND S.MarcaProd = @marca;

IF @risultato = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Parte non presente nella struttura del prodotto';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Le date di Lotto devono essere coerenti*/

DROP TRIGGER IF EXISTS ControlloDateLotto;

DELIMITER $$

CREATE TRIGGER ControlloDateLotto
BEFORE UPDATE ON LOTTO
FOR EACH ROW
BEGIN

IF (NEW.DataFineProd IS NOT NULL AND NEW.DataFineProd <= OLD.DataInizioProd) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Data fine produzione non valida';
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Un’unità non può essere sottoposta ad alcuna procedura di assistenza se c’è su di essa una richiesta di reso accettata oppure sotto valutazione da parte dell’azienda.*/

DROP TRIGGER IF EXISTS ControlloAssistenza;

DELIMITER $$

CREATE TRIGGER ControlloAssistenza
BEFORE INSERT ON ASSISTENZA
FOR EACH ROW
BEGIN

SELECT COUNT(*) INTO @risultato
FROM richiesta_reso RR
WHERE RR.Unita = NEW.Unita
AND IFNULL(RR.Accettata, TRUE) = TRUE;

IF @risultato = 1 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Unita' sotto procedura di reso";
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Un’unità non può essere sottoposta a più di una richiesta di reso allo stesso tempo*/

DROP TRIGGER IF EXISTS ControlloRichiestaReso;

DELIMITER $$

CREATE TRIGGER ControlloRichiestaReso
BEFORE INSERT ON RICHIESTA_RESO
FOR EACH ROW
BEGIN

SELECT COUNT(*) INTO @risultato
FROM richiesta_reso RR
WHERE RR.Unita = NEW.Unita
AND IFNULL(RR.Accettata, TRUE) = TRUE;

IF @risultato = 1 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Unita' sotto procedura di reso";
END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Un’operazione non può comparire in una sequenza di assemblaggio di un prodotto rispetto al quale essa non è pertinente.*/

DROP TRIGGER IF EXISTS ControlloPertinenzaOperazione;

DELIMITER $$

CREATE TRIGGER ControlloPertinenzaOperazione
BEFORE INSERT ON SUCCESSIONE
FOR EACH ROW
BEGIN

SET @modelloOperazione = NULL;

SELECT P.ModelloProd INTO @modelloOperazione
FROM pertinenza P
WHERE P.Operazione = NEW.Operazione;

SET @marcaOperazione = NULL;

SELECT P.MarcaProd INTO @marcaOperazione
FROM pertinenza P
WHERE P.Operazione = NEW.Operazione;

SET @modelloSequenza = NULL;

SELECT S.ModelloProd INTO @modelloSequenza
FROM sequenza S
WHERE S.CodSequenza = NEW.Sequenza;

SET @marcaSequenza = NULL;

SELECT S.MarcaProd INTO @marcaSequenza
FROM sequenza S
WHERE S.CodSequenza = NEW.Sequenza;

IF (@modelloOperazione <> @modelloSequenza OR @marcaOperazione <> @marcaSequenza) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Operazione non pertinente";
END IF;
    
END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/
/*Aggiornamento della relazione ridondante ACQUISTO*/

DROP TRIGGER IF EXISTS AggiornaAcquisto;

DELIMITER $$

CREATE TRIGGER AggiornaAcquisto
BEFORE UPDATE ON UNITA
FOR EACH ROW
BEGIN

SET @account = NULL;

SELECT O.Account INTO @account
FROM ordine O
WHERE O.CodOrdine = NEW.Ordine;

SELECT COUNT(*) INTO @presenza
FROM acquisto A
WHERE A.Account = @account
AND A.ModelloProd = NEW.ModelloProd
AND A.MarcaProd = NEW.MarcaProd;

IF @presenza = 0 THEN

    INSERT INTO ACQUISTO VALUES(@account, OLD.ModelloProd, OLD.MarcaProd);

END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*Aggiornamento dell'attributo ridondante DataSpedizione*/

DROP TRIGGER IF EXISTS AggiornaDataSpedizione;

DELIMITER $$

CREATE TRIGGER AggiornaDataSpedizione
AFTER UPDATE ON UNITA
FOR EACH ROW
BEGIN

IF (OLD.Spedizione IS NULL AND NEW.Spedizione IS NOT NULL) THEN

    SET @partenza = NULL;

    SELECT S.DataPartenza INTO @partenza
    FROM spedizione S
    WHERE S.CodSpedizione = NEW.Spedizione;

    UPDATE UNITA
    SET DataSpedizione = @partenza
    WHERE CodSer = NEW.CodSer;

END IF;

END $$

DELIMITER ;

/*---------------------------------------------------------------------------------------------------------------------------*/

/*Un ordine di parti di ricambio non può essere effettuato prima che il cliente abbia accettato il preventivo di riparazione.*/

DROP TRIGGER IF EXISTS ControlloOrdineParti;

DELIMITER $$

CREATE TRIGGER ControlloOrdineParti
BEFORE INSERT ON ORDINE_PARTI
FOR EACH ROW
BEGIN

SET @risultato = NULL;

SELECT IP.Accettato INTO @risultato
FROM intervento_preventivo IP
WHERE IP.Ticket = NEW.Ticket;

IF IFNULL(@risultato, FALSE) = FALSE THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = "Preventivo non accettato";
END IF;

END $$

DELIMITER ;