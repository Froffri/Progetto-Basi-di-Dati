DROP PROCEDURE IF EXISTS InOrdine;

DELIMITER $$

CREATE PROCEDURE InOrdine(IN _codOrdine INT, IN _orario TIMESTAMP, IN _stato VARCHAR(16), IN _account VARCHAR(30), IN _via VARCHAR(50), IN _numCivico VARCHAR(4), IN _Citta VARCHAR(50), IN _CAP NUMERIC(5))
BEGIN

CALL InserimentoIndirizzo(_via, _numCivico, _citta, _CAP);

INSERT INTO ORDINE VALUES(_codOrdine, _orario, 'In processazione', _account, _via, _numCivico, _citta);

IF _stato = 'In preparazione' OR _stato = 'Spedito' OR _stato = 'Evaso' THEN

    UPDATE ORDINE
    SET Stato = 'In preparazione'
    WHERE CodOrdine = _codOrdine;

    IF _stato = 'Spedito' OR _stato = 'Evaso' THEN

        UPDATE ORDINE
        SET Stato = 'Spedito'
        WHERE CodOrdine = _codOrdine;

        IF _stato = 'Evaso' THEN

            UPDATE ORDINE
            SET Stato = 'Evaso'
            WHERE CodOrdine = _codOrdine;

        END IF;

    END IF;

END IF;

END$$

DELIMITER ;



DROP PROCEDURE IF EXISTS InSpedizione;

DELIMITER $$

CREATE PROCEDURE InSpedizione(IN _codSpedizione INT, IN _dataPartenza DATE, IN _dataArrivo DATE, IN _dataPrevista DATE, IN _stato VARCHAR(11), IN _ordine INT)
BEGIN

INSERT INTO SPEDIZIONE VALUES(_codSpedizione, _dataPartenza, _dataArrivo, _dataPrevista, 'Spedita', _ordine);

IF _stato = 'In transito' OR _stato = 'In consegna' OR _stato = 'Consegnata' THEN

    UPDATE SPEDIZIONE
    SET Stato = 'In transito'
    WHERE CodSpedizione = _codSpedizione;

    IF _stato = 'In consegna' OR _stato = 'Consegnata' THEN

        UPDATE SPEDIZIONE
        SET Stato = 'In consegna'
        WHERE CodSpedizione = _codSpedizione;

        IF  _stato = 'Consegnata' THEN

            UPDATE SPEDIZIONE
            SET Stato = 'Consegnata'
            WHERE CodSpedizione = _codSpedizione;

        END IF;

    END IF;

END IF;

END$$

DELIMITER ;


/*Inserimenti Per l'operazione di inserimento unità, prenotazione intervento preventivo, */
INSERT INTO LINEA_PRODUZIONE(Sede, T) VALUES('Napoli', 77);

INSERT INTO LINEA_PRODUZIONE(Sede, T) VALUES('Roma', 52);

INSERT INTO LINEA_PRODUZIONE(Sede, T) VALUES('Milano', 135);

INSERT INTO PRODOTTO VALUES('8T', 'OnePlus', 100, 2, 870.69, NULL, 'Telefono OnePlus, ottima fattura. Supporta il 5Ged estremamente resistente.', NULL, NULL);

INSERT INTO PRODOTTO VALUES('Z3C25', 'Dyson', 50, 6, 299.99, 'Lavatrice salvaspazio Dyson', 'Lavatrice eccellente per monolocali. Ottimo risparmio di acqua e lavaggi di tutte le temperature.', NULL, NULL);

INSERT INTO PRODOTTO VALUES('ABC', 'Rowenta', 50, 2, 199.99, 'Aspirapolvere Rowenta', 'Rowenta, per chi non si accontenta', NULL, NULL);

INSERT INTO SEQUENZA(Descrizione, ModelloProd, MarcaProd) VALUES('Cambio strumenti: 70%. Rotazione: 30%.', '8T', 'OnePlus');

INSERT INTO SEQUENZA(Descrizione, ModelloProd, MarcaProd) VALUES('Cambio strumenti: 30%. Rotazione: 70%.', 'Z3C25', 'Dyson');

INSERT INTO SEQUENZA(Descrizione, ModelloProd, MarcaProd) VALUES('Cambio strumenti: 50%. Rotazione: 50%.', 'Z3C25', 'Dyson');

INSERT INTO SEQUENZA(Descrizione, ModelloProd, MarcaProd) VALUES('blablablablabla.', '8T', 'OnePlus');

INSERT INTO LOTTO(CodiceLotto, DurataPreventivata, DataInizioProd, Linea, Sequenza) VALUES(1 ,75, '2021-04-04 14:25:00', 2, 1);

INSERT INTO LOTTO(DurataPreventivata, DataInizioProd, Linea, Sequenza) VALUES(33, '2021-03-16 17:47:00', 3, 2);

INSERT INTO LOTTO(DurataPreventivata, DataInizioProd, Linea, Sequenza) VALUES(40, '2020-12-29 18:00:00', 1, 3);

INSERT INTO LOTTO(DurataPreventivata, DataInizioProd, DataFineProd, Linea, Sequenza) VALUES(31, '2021-1-25 10:30:00', '2021-1-27 09:13:00', 1, 2);

INSERT INTO LOTTO(DurataPreventivata, DataInizioProd, DataFineProd, Linea, Sequenza) VALUES(1, '2021-2-13 12:22:00', '2021-2-13 14:05:00', 3, 1);

INSERT INTO MAGAZZINO(Capienza, Predisposizione) VALUES(5000, 'Elettronica');

INSERT INTO STORICO_STOCCAGGIO(Lotto, Magazzino, Area, DataInizioStock) VALUES(4, 1, 'B52', '2021-1-27');

INSERT INTO STORICO_STOCCAGGIO(Lotto, Magazzino, Area, DataInizioStock, DataFineStock) VALUES(5, 1, 'B54', '2021-2-14', '2021-2-15');

INSERT INTO DOCUMENTO VALUES('AX1234567', 'Carta di identita', '2022-12-13', 'Comune');

INSERT INTO AREA_GEOGRAFICA VALUES(26, NULL);

INSERT INTO CODICE_POSTALE VALUES(12345, 26);

CALL InserimentoIndirizzo('Via dei frati', '4B', 'Salsomaggiore', 12345);

INSERT INTO UTENTE VALUES('MRZMRC96T13H720A', 'Marco', 'Marzolini', '1996-12-13', '2021-01-01', '1111111111', 'Via dei frati', '4B', 'Salsomaggiore', 'AX1234567');

INSERT INTO ACCOUNT VALUES('MarzKing', 'Qual è il nome della città che possiedi?', 'Marzolinia', '123pasitobailantemaria', 110.50, 'MRZMRC96T13H720A');

CALL InOrdine(1, '2021-02-05 12:33:25', 'Evaso', 'MarzKing', 'Via dei frati', '4B', 'Salsomaggiore', 12345);

CALL InSpedizione(1,'2021-02-06', '2021-02-10', '2021-02-11', 'Consegnata', 1);

INSERT INTO UNITA VALUES(15265,'2021-2-13','2021-02-06','8T', 'OnePlus',5,1,1);

INSERT INTO ACQUISTO VALUES('MarzKing', '8T', 'OnePlus');

/*
Aggiornamento storico stoccaggio(ho inserito un unità che non dovrebbe far si che lo storico si aggiornasse e una che lo fa aggiornare)
*/

INSERT INTO LOTTO VALUES(36, 25, '2021-4-19 17:52:00', '2021-4-20 11:17:00', 'Nuove', 2, 3);

INSERT INTO MAGAZZINO(Capienza, Predisposizione) VALUES(7398, 'Elettrodomestici');

INSERT INTO STORICO_STOCCAGGIO(Lotto, Magazzino, Area, DataInizioStock) VALUES(36, 2, 'F02', '2021-04-27');

INSERT INTO UNITA VALUES(255,'2021-04-20',NULL,'Z3C25', 'Dyson',36, NULL,NULL);

INSERT INTO LOTTO VALUES(10, 32, '2021-3-15 12:22:00', '2021-3-16 17:33:00', 'Nuove', 1, 1);

INSERT INTO STORICO_STOCCAGGIO(Lotto, Magazzino, Area, DataInizioStock) VALUES(10, 1, 'A05', '2021-3-17');

INSERT INTO DOCUMENTO VALUES('AX4040404', 'Carta di identita', '2024-05-02', 'Comune');

INSERT INTO AREA_GEOGRAFICA VALUES(35, NULL);

INSERT INTO CODICE_POSTALE VALUES(67890, 35);

CALL InserimentoIndirizzo('Piazza delle via', '74', 'Sava', 67890);

INSERT INTO UTENTE VALUES('BRDLND00E02I467J', 'Alejandro', 'Brodenzio', '2000-05-02', '2021-03-11', '1234567890', 'Piazza delle via', '74', 'Sava', 'AX4040404');

INSERT INTO ACCOUNT VALUES('Drw0if', 'Qual è?', 'Si', 'YESYESYESYES69', 0, 'BRDLND00E02I467J');

CALL InOrdine(30, '2021-03-17 11:11:12', 'Evaso', 'Drw0if', 'Piazza delle via', '74', 'Sava', 67890);

CALL InSpedizione(37,'2021-03-18', '2021-03-26', '2021-03-24', 'Consegnata', 30);

INSERT INTO UNITA VALUES(404,'2021-03-16','2021-03-18','8T', 'OnePlus',10, 37,30);

INSERT INTO ACQUISTO VALUES('Drw0if', '8T', 'OnePlus');

/*Inserimento per assistenza virtuale con codice errore*/

CALL InOrdine(36, '2021-04-20 23:31:15', 'Evaso', 'Drw0if', 'Piazza delle via', '74', 'Sava', 67890);

CALL InSpedizione(40,'2021-04-21', '2021-04-23', '2021-04-26', 'Consegnata', 36);

INSERT INTO UNITA VALUES(80,'2021-04-16','2021-04-21','Z3C25', 'Dyson',36, 40,36);

INSERT INTO ACQUISTO VALUES('Drw0if', 'Z3C25', 'Dyson');

INSERT INTO GUASTO VALUES(333, 'Motore fuori uso', 'blablablablablablablablablablablablablablablabla');

INSERT INTO CODICE_ERRORE VALUES(37, 'Z3C25', 'Dyson', 333);

INSERT INTO RIMEDIO VALUES(33, 'Descrizione rimedio 1');

INSERT INTO RIMEDIO VALUES(34, 'Descrizione rimedio 2');

INSERT INTO RIMEDIO VALUES(35, 'Descrizione rimedio 3');

INSERT INTO RIMEDIO VALUES(36, 'Descrizione rimedio 4');

INSERT INTO RIMEDIO VALUES(37, 'Descrizione rimedio 5');

INSERT INTO PROCEDURA VALUES(37, 33);

INSERT INTO PROCEDURA VALUES(37, 34);

INSERT INTO PROCEDURA VALUES(37, 35);

INSERT INTO PROCEDURA VALUES(37, 36);

INSERT INTO PROCEDURA VALUES(37, 37);

/*Inserimento richiesta di reso*/

INSERT INTO DOCUMENTO VALUES('AX5050505', 'Carta di identita', '2026-04-20', 'Comune');

INSERT INTO AREA_GEOGRAFICA VALUES(75, NULL);

INSERT INTO CODICE_POSTALE VALUES(52022, 75);

CALL InserimentoIndirizzo('Vicolo Corto', '5', 'Monopoli', 52022);

INSERT INTO UTENTE VALUES('MGNFNC98D20F376O', 'Francesco', 'Mignone', '1998-04-20', '2021-02-28', 9876545210, 'Vicolo Corto', '5', 'Monopoli', 'AX5050505');

INSERT INTO ACCOUNT VALUES('ilNerdChuck', 'Jotaro?', 'Dio', '+Caesar+', 0, 'MGNFNC98D20F376O');

CALL InOrdine(70, '2021-03-27 08:10:48', 'Evaso', 'ilNerdChuck', 'Vicolo Corto', '5', 'Monopoli', 52022);

CALL InSpedizione(67,'2021-03-29', '2021-04-20', '2021-04-02', 'Consegnata', 70);

INSERT INTO UNITA VALUES(777,'2021-03-16','2021-03-29','8T', 'OnePlus',10, 67,70);

INSERT INTO ACQUISTO VALUES('ilNerdChuck', '8T', 'OnePlus');

INSERT INTO MOTIVAZIONE VALUES(0,'Recesso', 'Diritto di recesso');

INSERT INTO MOTIVAZIONE VALUES(21,'Rovinato', 'Prodotto rovinato ma ancora utilizzabile');

/*INIZIO POPOLAMENTO DATA ANALYTICS*/
/*Inserimento delle successioni e delle operazioni*/

INSERT INTO MATERIALE VALUES('Ferro', 72.37);

INSERT INTO MATERIALE VALUES('Plastica', 5.50);

INSERT INTO PARTE VALUES(1, 'ParteOnePlus 1', 77.75, 10, 0.75, 70);

INSERT INTO PARTE VALUES(2, 'ParteOnePlus 2', 77.75, 10, 0.75, 70);

INSERT INTO PARTE VALUES(3, 'ParteOnePlus 3', 77.75, 10, 0.75, 70);

INSERT INTO PARTE VALUES(4, 'ParteOnePlus 4', 77.75, 10, 0.75, 70);

INSERT INTO PARTE VALUES(5, 'ParteOnePlus 5', 77.75, 10, 0.75, 70);

INSERT INTO OPERAZIONE VALUES(1, 'OperazioneOnePlus 1', 5, 1, 2, NULL, 1);

INSERT INTO OPERAZIONE VALUES(2, 'OperazioneOnePlus 2', 5, 2, 1, NULL, 2);

INSERT INTO OPERAZIONE VALUES(3, 'OperazioneOnePlus 3', 5, 1, 2, NULL, 3);

INSERT INTO OPERAZIONE VALUES(4, 'OperazioneOnePlus 4', 5, 2, 1, NULL, 4);

INSERT INTO OPERAZIONE VALUES(5, 'OperazioneOnePlus 5', 5, 1, 2, NULL, 5);

INSERT INTO SUCCESSIONE VALUES(1, 1, 1);

INSERT INTO SUCCESSIONE VALUES(2, 2, 1);

INSERT INTO SUCCESSIONE VALUES(3, 3, 1);

INSERT INTO SUCCESSIONE VALUES(4, 4, 1);

INSERT INTO SUCCESSIONE VALUES(5, 5, 1);

INSERT INTO SUCCESSIONE VALUES(1, 1, 4);

INSERT INTO SUCCESSIONE VALUES(3, 2, 4);

INSERT INTO SUCCESSIONE VALUES(5, 3, 4);

INSERT INTO SUCCESSIONE VALUES(2, 4, 4);

INSERT INTO SUCCESSIONE VALUES(4, 5, 4);

/*Inserimento dei lotti*/

INSERT INTO OPERAIO VALUES(1111, 'Maurizio', 'Smargiassi', '2000-04-25');

INSERT INTO OPERAIO VALUES(2222, 'Maurizia', 'Smargiassi', '2000-04-25');

INSERT INTO OPERAIO VALUES(3333, 'Carlino', 'Magalli', '1966-12-21');

INSERT INTO OPERAIO VALUES(4444, 'Minù', 'Barbetti', '1988-7-12');

INSERT INTO STAZIONE VALUES(1, 2, 1111);

INSERT INTO STAZIONE VALUES(2, 2, 2222);

INSERT INTO STAZIONE VALUES(1, 3, 3333);

INSERT INTO STAZIONE VALUES(2, 3, 4444);

INSERT INTO LOTTO VALUES(33, 6, '2021-03-22 17:00:00', '2021-03-25 12:33:33', 'Nuove', 3, 1);

INSERT INTO UNITA_PERSA VALUES(1, '2021-03-22 17:35:29', 1, 3, 33);

INSERT INTO UNITA_PERSA VALUES(2, '2021-03-23 11:40:31', 2, 3, 33);

INSERT INTO UNITA_PERSA VALUES(3, '2021-03-22 17:40:31', 2, 3, 33);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(666, '2021-03-25', '8T', 'OnePlus', 33);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(667, '2021-03-25', '8T', 'OnePlus', 33);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(668, '2021-03-25', '8T', 'OnePlus', 33);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(669, '2021-03-25', '8T', 'OnePlus', 33);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(670, '2021-03-25', '8T', 'OnePlus', 33);

INSERT INTO LOTTO VALUES(34, 7, '2021-02-21 17:00:00', '2021-02-26 12:33:33', 'Nuove', 2, 1);

INSERT INTO UNITA_PERSA VALUES(4, '2021-02-22 17:35:29', 1, 2, 34);

INSERT INTO UNITA_PERSA VALUES(5, '2021-02-24 11:40:31', 2, 2, 34);

INSERT INTO UNITA_PERSA VALUES(6, '2021-02-26 11:40:31', 2, 2, 34);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(671, '2021-02-26', '8T', 'OnePlus', 34);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(672, '2021-02-26', '8T', 'OnePlus', 34);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(673, '2021-02-26', '8T', 'OnePlus', 34);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(674, '2021-02-26', '8T', 'OnePlus', 34);

INSERT INTO LOTTO VALUES(35, 3, '2021-01-22 17:00:00', '2021-01-23 11:25:33', 'Nuove', 3, 4);

INSERT INTO UNITA_PERSA VALUES(7, '2021-01-22 17:35:29', 1, 3, 35);

INSERT INTO UNITA_PERSA VALUES(8, '2021-01-23 11:15:31', 2, 3, 35);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(675, '2021-01-23', '8T', 'OnePlus', 35);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(676, '2021-01-23', '8T', 'OnePlus', 35);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(677, '2021-01-23', '8T', 'OnePlus', 35);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(678, '2021-01-23', '8T', 'OnePlus', 35);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(679, '2021-01-23', '8T', 'OnePlus', 35);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(680, '2021-01-23', '8T', 'OnePlus', 35);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(681, '2021-01-23', '8T', 'OnePlus', 35);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(682, '2021-01-23', '8T', 'OnePlus', 35);

INSERT INTO LOTTO VALUES(37, 4, '2021-01-25 12:00:00', '2021-01-26 12:33:33', 'Nuove', 2, 4);

INSERT INTO UNITA_PERSA VALUES(9, '2021-01-25 17:35:29', 1, 2, 37);

INSERT INTO UNITA_PERSA VALUES(10, '2021-01-26 11:15:31', 2, 2, 37);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(683, '2021-01-26', '8T', 'OnePlus', 37);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(684, '2021-01-26', '8T', 'OnePlus', 37);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(685, '2021-01-26', '8T', 'OnePlus', 37);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(686, '2021-01-26', '8T', 'OnePlus', 37);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(687, '2021-01-26', '8T', 'OnePlus', 37);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(688, '2021-01-26', '8T', 'OnePlus', 37);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(689, '2021-01-26', '8T', 'OnePlus', 37);

INSERT INTO UNITA(CodSer, DataProduzione, ModelloProd, MarcaProd, Lotto) VALUES(690, '2021-01-26', '8T', 'OnePlus', 37);

/*POPOLAMENTO CBR*/

INSERT INTO SINTOMO VALUES(1, 'Sintomo 1');

INSERT INTO SINTOMO VALUES(2, 'Sintomo 2');

INSERT INTO SINTOMO VALUES(3, 'Sintomo 3');

INSERT INTO SINTOMO VALUES(4, 'Sintomo 4');

INSERT INTO SINTOMO VALUES(5, 'Sintomo 5');

INSERT INTO SINTOMO VALUES(6, 'Sintomo 6');

INSERT INTO SINTOMO VALUES(7, 'Sintomo 7');

INSERT INTO SINTOMO VALUES(8, 'Sintomo 8');

INSERT INTO SINTOMO VALUES(9, 'Sintomo 9');

INSERT INTO SINTOMO VALUES(10, 'Sintomo 10');

INSERT INTO RIMEDIO VALUES(38, 'Descrizione rimedio 6');

INSERT INTO RIMEDIO VALUES(39, 'Descrizione rimedio 7');

INSERT INTO RIMEDIO VALUES(40, 'Descrizione rimedio 8');

INSERT INTO RIMEDIO VALUES(41, 'Descrizione rimedio 9');

INSERT INTO RIMEDIO VALUES(42, 'Descrizione rimedio 10');

CALL InOrdine(999, '2021-02-07 08:10:48', 'Evaso', 'ilNerdChuck', 'Vicolo Corto', '5', 'Monopoli', 52022);

CALL InSpedizione(555,'2021-03-01', '2021-03-02', '2021-03-02', 'Consegnata', 999);

INSERT INTO UNITA VALUES(2512,'2021-01-01','2021-03-01','Z3C25', 'Dyson',36, 555,999);

INSERT INTO ACQUISTO VALUES('ilNerdChuck', 'Z3C25', 'Dyson');

INSERT INTO ASSISTENZA VALUES(1, NULL, '2021-03-15', 'Fisica', 2512, NULL, NULL);

INSERT INTO INTERVENTO_PREVENTIVO VALUES(1, TRUE, 220, '2021-03-16', '9:00:00', NULL);

INSERT INTO SINTOMI_INDIVIDUATI VALUES(1,1);

INSERT INTO SINTOMI_INDIVIDUATI VALUES(1,2);

INSERT INTO SINTOMI_INDIVIDUATI VALUES(1,5);

INSERT INTO CASO VALUES(1, 333);

INSERT INTO RAPPRESENTAZIONE VALUES(1, 1);

INSERT INTO RAPPRESENTAZIONE VALUES(1, 3);

INSERT INTO RAPPRESENTAZIONE VALUES(1, 5);

INSERT INTO RAPPRESENTAZIONE VALUES(1, 7);

INSERT INTO RAPPRESENTAZIONE VALUES(1, 9);

INSERT INTO SOLUZIONE VALUES(1, 38);

INSERT INTO SOLUZIONE VALUES(1, 40);

INSERT INTO SOLUZIONE VALUES(1, 42);

INSERT INTO CASO VALUES(2, 333);

INSERT INTO RAPPRESENTAZIONE VALUES(2, 1);

INSERT INTO RAPPRESENTAZIONE VALUES(2, 2);

INSERT INTO RAPPRESENTAZIONE VALUES(2, 5);

INSERT INTO SOLUZIONE VALUES(2, 38);

INSERT INTO SOLUZIONE VALUES(2, 41);

INSERT INTO SOLUZIONE VALUES(2, 42);

INSERT INTO CASO VALUES(3, NULL);

INSERT INTO RAPPRESENTAZIONE VALUES(3, 1);

INSERT INTO RAPPRESENTAZIONE VALUES(3, 5);

INSERT INTO RAPPRESENTAZIONE VALUES(3, 6);

INSERT INTO SOLUZIONE VALUES(3, 38);

INSERT INTO SOLUZIONE VALUES(3, 40);

INSERT INTO SOLUZIONE VALUES(3, 39);

INSERT INTO CASO VALUES(4, NULL);

INSERT INTO RAPPRESENTAZIONE VALUES(4, 2);

INSERT INTO RAPPRESENTAZIONE VALUES(4, 4);

INSERT INTO RAPPRESENTAZIONE VALUES(4, 6);

INSERT INTO RAPPRESENTAZIONE VALUES(4, 8);

INSERT INTO RAPPRESENTAZIONE VALUES(4, 10);

INSERT INTO SOLUZIONE VALUES(4, 39);

INSERT INTO SOLUZIONE VALUES(4, 41);

INSERT INTO SOLUZIONE VALUES(4, 42);
