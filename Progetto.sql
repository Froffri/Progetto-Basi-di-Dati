BEGIN;
DROP DATABASE IF EXISTS Progetto;
CREATE DATABASE Progetto;
COMMIT;

USE Progetto;

DROP TABLE IF EXISTS ACCOUNT;
CREATE TABLE ACCOUNT (
    Username VARCHAR(30) PRIMARY KEY,
    DomSic VARCHAR(50) NOT NULL,
    RispSic VARCHAR(30) NOT NULL,
    Password VARCHAR(30) NOT NULL,
    Credito NUMERIC(8,2) DEFAULT(0) NOT NULL,
    Utente CHAR(16) NOT NULL REFERENCES UTENTE(CodFiscale) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK(Credito>=0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS PRODOTTO;
CREATE TABLE PRODOTTO (
    Modello VARCHAR(10),
    Marca VARCHAR(20),
    Soglia SMALLINT NOT NULL,
    Facce TINYINT NOT NULL,
    Prezzo NUMERIC(8,2) NOT NULL,
    NomeProd VARCHAR(30),
    Descrizione VARCHAR(100) NOT NULL,
    ModelloOriginale VARCHAR(10),
    MarcaOriginale VARCHAR(20),
    PRIMARY KEY(Modello,Marca),
    FOREIGN KEY(ModelloOriginale, MarcaOriginale) REFERENCES PRODOTTO(Modello,Marca) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK(Soglia > 0 AND Prezzo > 0 AND Facce > 0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS ACQUISTO;
CREATE TABLE ACQUISTO (
    Account VARCHAR(30) REFERENCES ACCOUNT(Username) ON DELETE CASCADE ON UPDATE CASCADE,
    ModelloProd VARCHAR(10),
    MarcaProd VARCHAR(20),
    PRIMARY KEY(Account, ModelloProd, MarcaProd),
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS APPLICAZIONE;
CREATE TABLE APPLICAZIONE (
    ModelloProd VARCHAR(10),
    MarcaProd VARCHAR(20),
    EstGaranzia INT REFERENCES ESTENSIONE_GARANZIA(CodEstensione) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(ModelloProd, MarcaProd, EstGaranzia),
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS AREA_GEOGRAFICA;
CREATE TABLE AREA_GEOGRAFICA (
    CodArea INT PRIMARY KEY AUTO_INCREMENT,
    CentroRip INT /*NOT NULL*/ REFERENCES CENTRO_RIPARAZIONE(CodCentro) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS ASSISTENZA;
CREATE TABLE ASSISTENZA (
    Ticket INT PRIMARY KEY AUTO_INCREMENT,
    Sistemato BOOLEAN DEFAULT(NULL),
    Data DATE NOT NULL DEFAULT(CURRENT_DATE),
    Tipologia VARCHAR(8) NOT NULL,
    Unita INT NOT NULL REFERENCES UNITA(CodSer) ON DELETE NO ACTION ON UPDATE NO ACTION,
    Casistica INT REFERENCES CASISTICA(CodCasistica) ON DELETE SET NULL ON UPDATE CASCADE,
    CodiceErrore INT REFERENCES CODICE_ERRORE(CodErrore) ON DELETE SET NULL ON UPDATE CASCADE,
	CHECK(Tipologia='Virtuale' OR Tipologia='Fisica')
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS AUTODIAGNOSI;
CREATE TABLE AUTODIAGNOSI (
    CodDiagnoasi INT PRIMARY KEY AUTO_INCREMENT,
    Testo VARCHAR(50) NOT NULL,
    Ordine TINYINT NOT NULL,
    Casistica INT NOT NULL REFERENCES CASISTICA(CodCasistica) ON DELETE CASCADE ON UPDATE CASCADE,
    NextSi INT REFERENCES AUTODIAGNOSI(CodDiagnosi) ON DELETE SET NULL ON UPDATE CASCADE,
    NextNo INT REFERENCES AUTODIAGNOSI(CodDiagnosi) ON DELETE SET NULL ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS CAMPIONE;
CREATE TABLE CAMPIONE (
    Operaio INT REFERENCES OPERAIO(ID) ON DELETE CASCADE ON UPDATE CASCADE,
    OperazioneSig INT REFERENCES OPERAZIONE_SIGNIFICATIVA(CodiceOpSig) ON DELETE CASCADE ON UPDATE CASCADE,
    TempoMed SMALLINT NOT NULL,
    TempoMax SMALLINT NOT NULL,
    TempoMin SMALLINT NOT NULL,
    PRIMARY KEY(Operaio, OperazioneSig),
    CHECK(TempoMed>0 AND TempoMax>0 AND TempoMin>0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS CARATTERISTICA;
CREATE TABLE CARATTERISTICA (
    CodCaratteristica INT,
    ElemGiunzione INT REFERENCES ELEMENTO_GIUNZIONE(CodGiunzione) ON DELETE CASCADE ON UPDATE CASCADE,
    Descrizione VARCHAR(50) NOT NULL,
    Valore NUMERIC(5,2) NOT NULL,
    UDM VARCHAR(10) NOT NULL,
    PRIMARY KEY(CodCaratteristica, ElemGiunzione),
    CHECK(Valore>0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS CASISTICA;
CREATE TABLE CASISTICA (
    CodCasistica INT PRIMARY KEY AUTO_INCREMENT,
    Testo VARCHAR(50) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS INDIRIZZO;
CREATE TABLE INDIRIZZO (
    Via VARCHAR(50),
    NumCivico VARCHAR(4),
    Citta VARCHAR(50),
    CAP NUMERIC(5) NOT NULL REFERENCES CODICE_POSTALE(CAP) ON DELETE NO ACTION ON UPDATE CASCADE,
    PRIMARY KEY(Via, NumCivico, Citta)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS CENTRO_RIPARAZIONE;
CREATE TABLE CENTRO_RIPARAZIONE (
    CodCentro INT PRIMARY KEY AUTO_INCREMENT,
    Via VARCHAR(50) NOT NULL,
    NumCivico VARCHAR(4) NOT NULL,
    Citta VARCHAR(50) NOT NULL,
    FOREIGN KEY(Via, NumCivico, Citta) REFERENCES INDIRIZZO(Via, NumCivico, Citta) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS CODICE_ERRORE;
CREATE TABLE CODICE_ERRORE (
    CodErrore INT PRIMARY KEY AUTO_INCREMENT,
    ModelloProd VARCHAR(10) NOT NULL,
    MarcaProd VARCHAR(20) NOT NULL,
    Guasto INT NOT NULL REFERENCES GUASTO(CodGuasto) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS CODICE_POSTALE;
CREATE TABLE CODICE_POSTALE (
    CAP NUMERIC(5) PRIMARY KEY,
    AreaGeografica INT NOT NULL REFERENCES AREA_GEOGRAFICA(CodArea) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS COINVOLGIMENTO;
CREATE TABLE COINVOLGIMENTO (
    Guasto INT REFERENCES GUASTO(CodGuasto) ON DELETE CASCADE ON UPDATE CASCADE,
    Parte INT REFERENCES PARTE(CodParte) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Guasto, Parte)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS COMPOSIZIONE;
CREATE TABLE COMPOSIZIONE (
    Parte INT REFERENCES PARTE(CodParte) ON DELETE NO ACTION ON UPDATE CASCADE,
    Materiale VARCHAR(20) REFERENCES MATERIALE(NomeMateriale) ON DELETE NO ACTION ON UPDATE CASCADE,
    Quantita INTEGER NOT NULL,
    PRIMARY KEY(Parte, Materiale),
    CHECK(Quantita>0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS COPERTURA;
CREATE TABLE COPERTURA (
    EstensioneGaranzia INT REFERENCES ESTENSIONE_GARANZIA(CodEstensione) ON DELETE CASCADE ON UPDATE CASCADE,
    Guasto INT REFERENCES GUASTO(CodGuasto) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(EstensioneGaranzia, Guasto)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS DIAGNOSTICA;
CREATE TABLE DIAGNOSTICA (
    Intervento INT REFERENCES INTERVENTO_PREVENTIVO(Ticket) ON DELETE CASCADE ON UPDATE CASCADE,
    Guasto INT REFERENCES GUASTO(CodGuasto) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Intervento, Guasto)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS DOCUMENTO;
CREATE TABLE DOCUMENTO (
    NumDoc VARCHAR(10) PRIMARY KEY,
    Tipo VARCHAR(20) NOT NULL,
    Scadenza DATE NOT NULL,
    EnteRilascio VARCHAR(50) NOT NULL,
    CHECK(Tipo = 'Carta di identita' OR Tipo = 'Patente' OR Tipo = 'Passaporto')
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS ELEMENTO_GIUNZIONE;
CREATE TABLE ELEMENTO_GIUNZIONE (
    CodGiunzione INT PRIMARY KEY AUTO_INCREMENT,
    Tipo VARCHAR(30) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS SUCCESSIONE;
CREATE TABLE SUCCESSIONE (
    Operazione INT REFERENCES OPERAZIONE(CodiceOp) ON DELETE CASCADE ON UPDATE CASCADE,
    Ordine TINYINT,
    Sequenza INT REFERENCES SEQUENZA(CodSequenza) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Operazione, Ordine, Sequenza),
    CHECK(Ordine > 0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS STAZIONE;
CREATE TABLE STAZIONE (
    NumStazione SMALLINT,
    Linea INT REFERENCES LINEA_PRODUZIONE(CodLinea) ON DELETE CASCADE ON UPDATE CASCADE,
    Operaio INT NOT NULL REFERENCES OPERAIO(ID) ON DELETE NO ACTION ON UPDATE CASCADE,
    PRIMARY KEY(NumStazione,Linea),
    CHECK(NumStazione > 0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS ESECUZIONE;
CREATE TABLE ESECUZIONE (
    Operazione INT,
    Ordine TINYINT,
    Sequenza INT,
    Stazione SMALLINT,
    Linea INT,
    PRIMARY KEY(Operazione, Ordine, Sequenza, Stazione, Linea),
    FOREIGN KEY(Operazione, Ordine, Sequenza) REFERENCES SUCCESSIONE(Operazione, Ordine, Sequenza) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(Stazione, Linea) REFERENCES STAZIONE(NumStazione, Linea) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS ESTENSIONE_GARANZIA;
CREATE TABLE ESTENSIONE_GARANZIA (
    CodEstensione INT PRIMARY KEY AUTO_INCREMENT,
    Costo NUMERIC(7,2) NOT NULL,
    Mesi TINYINT DEFAULT(12) NOT NULL,
    CHECK(Costo>0 AND Mesi>0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS FISSAGGIO;
CREATE TABLE FISSAGGIO (
    Operazione INT REFERENCES OPERAZIONE(CodiceOp) ON DELETE CASCADE ON UPDATE CASCADE,
    Giunzione INT REFERENCES ELEMENTO_GIUNZIONE(CodGiunzione) ON DELETE NO ACTION ON UPDATE CASCADE,
    PRIMARY KEY(Operazione, Giunzione)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS GUASTO;
CREATE TABLE GUASTO (
    CodGuasto INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(20) NOT NULL,
    Descrizione VARCHAR(50) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS HUB;
CREATE TABLE HUB (
    CodiceHub INT PRIMARY KEY AUTO_INCREMENT,
    Via VARCHAR(50) NOT NULL,
    NumCivico VARCHAR(4) NOT NULL,
    Citta VARCHAR(50) NOT NULL,
    FOREIGN KEY(Via, NumCivico, Citta) REFERENCES INDIRIZZO(Via, NumCivico, Citta) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS INCREMENTO;
CREATE TABLE INCREMENTO (
    Unita INT REFERENCES UNITA(CodSer) ON DELETE CASCADE ON UPDATE CASCADE,
    EstGaranzia INT REFERENCES ESTENSIONE_GARANZIA(CodEstensione) ON DELETE CASCADE ON UPDATE CASCADE,
    DataInizio DATE DEFAULT(CURRENT_DATE),
    PRIMARY KEY(Unita, EstGaranzia, DataInizio)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS INTERVENTO_PREVENTIVO;
CREATE TABLE INTERVENTO_PREVENTIVO (
    Ticket INT PRIMARY KEY AUTO_INCREMENT REFERENCES ASSISTENZA(Ticket) ON DELETE NO ACTION ON UPDATE CASCADE,
    Accettato BOOLEAN DEFAULT(NULL),
    Preventivo INTEGER DEFAULT(NULL),
    DataPrev DATE NOT NULL,
    OrarioPrev TIME NOT NULL,
    Tecnico INT DEFAULT(NULL) REFERENCES TECNICO(Matricola) ON DELETE SET NULL ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS INTERVENTO_RIPARATIVO;
CREATE TABLE INTERVENTO_RIPARATIVO (
    Ticket INT PRIMARY KEY AUTO_INCREMENT REFERENCES INTERVENTO_PREVENTIVO(Ticket) ON DELETE CASCADE ON UPDATE CASCADE,
    DataRip DATE NOT NULL,
    OrarioRip TIME NOT NULL,
    Tecnico INT REFERENCES TECNICO(Matricola) ON DELETE SET NULL ON UPDATE CASCADE,
    CentroRip INT REFERENCES CENTRO_RIPARAZIONE(CodCentro) ON DELETE SET NULL ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS LINEA_PRODUZIONE;
CREATE TABLE LINEA_PRODUZIONE (
    CodLinea INT PRIMARY KEY AUTO_INCREMENT,
    Sede VARCHAR(50) NOT NULL,
    T SMALLINT NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS LOG;
CREATE TABLE LOG (
    UnitaResa INT REFERENCES UNITA_RESA(Unita) ON DELETE NO ACTION ON UPDATE CASCADE,
    Test INT REFERENCES TEST(CodiceTest) ON DELETE CASCADE ON UPDATE CASCADE,
    Parte INT REFERENCES PARTE(CodParte) ON DELETE NO ACTION ON UPDATE CASCADE,
    Successo BOOLEAN NOT NULL,
    PRIMARY KEY(UnitaResa, Test, Parte)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS LOTTO;
CREATE TABLE LOTTO (
    CodiceLotto INT PRIMARY KEY AUTO_INCREMENT,
    DurataPreventivata TINYINT,                /*In ore*/
    DataInizioProd TIMESTAMP DEFAULT(CURRENT_TIMESTAMP) NOT NULL,
    DataFineProd TIMESTAMP DEFAULT(NULL),
    Tipologia VARCHAR(14) NOT NULL DEFAULT('Nuove'),
    Linea INT REFERENCES LINEA_PRODUZIONE(CodLinea) ON DELETE SET NULL ON UPDATE CASCADE,
    Sequenza INT REFERENCES SEQUENZA(CodSequenza) ON DELETE SET NULL ON UPDATE CASCADE,
    CHECK(Tipologia = 'Nuove' OR Tipologia = 'Rese' OR Tipologia = 'Ricondizionate')
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS MAGAZZINO;
CREATE TABLE MAGAZZINO (
    CodMagazzino INT PRIMARY KEY AUTO_INCREMENT,
    Capienza SMALLINT NOT NULL,
    Predisposizione VARCHAR(100) NOT NULL,
    CHECK(Capienza>0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS MATERIALE;
CREATE TABLE MATERIALE (
    NomeMateriale VARCHAR(20) PRIMARY KEY,
    ValoreAlKg NUMERIC(8,2) NOT NULL,
    CHECK(ValoreAlKg>0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS MOTIVAZIONE;
CREATE TABLE MOTIVAZIONE (
    CodMotivazione INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(20) NOT NULL UNIQUE,
    Descrizione VARCHAR(50) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS OPERAIO;
CREATE TABLE OPERAIO (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(20) NOT NULL,
    Cognome VARCHAR(30) NOT NULL,
    DataNascita DATE NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS OPERAZIONE;
CREATE TABLE OPERAZIONE (
    CodiceOp INT PRIMARY KEY AUTO_INCREMENT,
    NomeOp VARCHAR(50) NOT NULL,
    Durata SMALLINT NOT NULL,
    FacciaOp TINYINT NOT NULL,
    FacciaAppoggio TINYINT NOT NULL,
    OperazioneSignificativa INT REFERENCES OPERAZIONE_SIGNIFICATIVA(CodiceOpSig) ON DELETE SET NULL ON UPDATE CASCADE,
    Parte INT NOT NULL REFERENCES PARTE(CodParte) ON DELETE NO ACTION ON UPDATE CASCADE,
    CHECK(Durata > 0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS OPERAZIONE_MANCANTE;
CREATE TABLE OPERAZIONE_MANCANTE (
    Operazione INT REFERENCES OPERAZIONE(CodiceOp) ON DELETE CASCADE ON UPDATE CASCADE,
    UnitaPersa INT REFERENCES UNITA_PERSA(CodPersa) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Operazione, UnitaPersa)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS OPERAZIONE_SIGNIFICATIVA;
CREATE TABLE OPERAZIONE_SIGNIFICATIVA (
    CodiceOpSig INT PRIMARY KEY AUTO_INCREMENT,
    NomeOpSig VARCHAR(50) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS ORDINE;
CREATE TABLE ORDINE (
    CodOrdine INT PRIMARY KEY AUTO_INCREMENT,
    Orario TIMESTAMP NOT NULL,
    Stato VARCHAR(16) DEFAULT('In processazione') NOT NULL,
    Account VARCHAR(30) REFERENCES ACCOUNT(Username) ON DELETE SET NULL ON UPDATE CASCADE,
    Via VARCHAR(50) NOT NULL,
    NumCivico VARCHAR(4) NOT NULL,
    Citta VARCHAR(50) NOT NULL,
    FOREIGN KEY(Via, NumCivico, Citta) REFERENCES INDIRIZZO(Via, NumCivico, Citta)ON DELETE NO ACTION ON UPDATE CASCADE,
    CHECK(Stato='In processazione' OR Stato='In preparazione' OR Stato='Spedito' OR Stato='Evaso' OR Stato='Pendente')
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS ORDINE_PARTI;
CREATE TABLE ORDINE_PARTI (
    CodOrdParti INT PRIMARY KEY AUTO_INCREMENT,
    Data DATE NOT NULL DEFAULT(CURRENT_DATE),
    DataConsPrev DATE NOT NULL,
    DataConsEff DATE DEFAULT(NULL),
    Ticket INT NOT NULL REFERENCES INTERVENTO_PREVENTIVO(Ticket) ON DELETE NO ACTION ON UPDATE CASCADE,
    CHECK(Data < DataConsPrev)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS PRODOTTO_PENDENTE;
CREATE TABLE PRODOTTO_PENDENTE (
    ModelloProd VARCHAR(10),
    MarcaProd VARCHAR(20),
    Ordine INT REFERENCES ORDINE(CodOrdine) ON DELETE CASCADE ON UPDATE CASCADE,
    Numero TINYINT,
    DataDisponibile DATE DEFAULT(NULL),
    PRIMARY KEY(ModelloProd, MarcaProd, Ordine, Numero),
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE NO ACTION ON UPDATE CASCADE,
    CHECK(Numero > 0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS PARTE;
CREATE TABLE PARTE (
    CodParte INT PRIMARY KEY AUTO_INCREMENT,
    NomeParte VARCHAR(30) NOT NULL,
    Prezzo NUMERIC(6,2) NOT NULL,
    Peso INTEGER NOT NULL,                /*Peso in grammi*/
    CoeffSvalutazione NUMERIC(3,2) NOT NULL,       /*Valore compreso tra 0 e 1*/
    PercentualeSost TINYINT DEFAULT(70) NOT NULL,
    CHECK(Prezzo > 0 AND Peso > 0 AND CoeffSvalutazione BETWEEN 0 AND 1 AND PercentualeSost BETWEEN 0 AND 100)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS PERTINENZA;
CREATE TABLE PERTINENZA (
    Operazione INT REFERENCES OPERAZIONE(CodiceOp) ON DELETE CASCADE ON UPDATE CASCADE,
    ModelloProd VARCHAR(10),
    MarcaProd VARCHAR(20),
    PRIMARY KEY(Operazione, ModelloProd, MarcaProd),
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS PROBLEMA;
CREATE TABLE PROBLEMA (
    Casistica INT REFERENCES CASISTICA(CodCasistica) ON DELETE CASCADE ON UPDATE CASCADE,
    ModelloProd VARCHAR(10),
    MarcaProd VARCHAR(20),
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Casistica, ModelloProd, MarcaProd)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS PROCEDURA;
CREATE TABLE PROCEDURA (
    CodiceErrore INT REFERENCES CODICE_ERRORE(CodErrore) ON DELETE CASCADE ON UPDATE CASCADE,
    Rimedio INT REFERENCES RIMEDIO(CodRimedio) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(CodiceErrore, Rimedio)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS RECENSIONE;
CREATE TABLE RECENSIONE (
    CodRecensione INT PRIMARY KEY AUTO_INCREMENT,
    ModelloProd VARCHAR(10) NOT NULL,
    MarcaProd VARCHAR(20) NOT NULL,
    Account VARCHAR(30) REFERENCES ACCOUNT(Username) ON DELETE SET NULL ON UPDATE CASCADE,
    Affidabilita TINYINT NOT NULL,
    EsperienzaUso TINYINT NOT NULL,
    Performance TINYINT NOT NULL,
    Aspetto TINYINT NOT NULL,
    RapportoQualitaPrezzo TINYINT NOT NULL,
    Descrizione VARCHAR(2000),
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK(Affidabilita BETWEEN 1 AND 5 AND EsperienzaUso BETWEEN 1 AND 5 AND Performance BETWEEN 1 AND 5 AND Aspetto BETWEEN 1 AND 5 AND RapportoQualitaPrezzo BETWEEN 1 AND 5)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS RICAMBIO;
CREATE TABLE RICAMBIO (
    OrdineParti INT REFERENCES ORDINE_PARTI(CodOrdineParti) ON DELETE CASCADE ON UPDATE CASCADE,
    Parte INT REFERENCES PARTE(CodParte) ON DELETE CASCADE ON UPDATE CASCADE,
    Numero TINYINT NOT NULL,
    PRIMARY KEY(OrdineParti, Parte),
    CHECK(Numero > 0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS RICEVUTA;
CREATE TABLE RICEVUTA (
    CodRicevuta INT PRIMARY KEY AUTO_INCREMENT,
    Costo NUMERIC(6,2) NOT NULL,
    VociDiCosto VARCHAR(300) NOT NULL,
    ModPagamento VARCHAR(16) NOT NULL,
    Ticket INT REFERENCES INTERVENTO_RIPARATIVO(Ticket) ON DELETE NO ACTION ON UPDATE CASCADE,
    CHECK(Costo > 0 AND (ModPagamento='Contanti' OR ModPagamento='Carta di debito' OR ModPagamento='Carta di credito' OR ModPagamento='Assegno' OR ModPagamento='Bonifico'))
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS RICHIESTA_RESO;
CREATE TABLE RICHIESTA_RESO (
    CodReso INT PRIMARY KEY AUTO_INCREMENT,
    Accettata BOOLEAN DEFAULT(NULL),
    Data DATE DEFAULT(CURRENT_DATE) NOT NULL,
    Unita INT NOT NULL REFERENCES UNITA(CodSer) ON DELETE NO ACTION ON UPDATE CASCADE,
    Motivazione INT NOT NULL REFERENCES MOTIVAZIONE(CodMotivazione) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS RIMEDIO;
CREATE TABLE RIMEDIO (
    CodRimedio INT PRIMARY KEY AUTO_INCREMENT,
    Descrizione VARCHAR(500) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS SEQUENZA;
CREATE TABLE SEQUENZA (
    CodSequenza INT PRIMARY KEY AUTO_INCREMENT,
    Descrizione VARCHAR(200) NOT NULL,
    ModelloProd VARCHAR(10) NOT NULL,
    MarcaProd VARCHAR(20) NOT NULL,
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS SOSTITUZIONE;
CREATE TABLE SOSTITUZIONE (
    Parte INT REFERENCES PARTE(CodParte) ON DELETE NO ACTION ON UPDATE CASCADE,
    UnitaRicondizionata INT REFERENCES UNITA_RICONDIZIONATA(Unita) ON DELETE CASCADE ON UPDATE CASCADE,
    Numero TINYINT NOT NULL DEFAULT(1),
    PRIMARY KEY(Parte, UnitaRicondizionata)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS SPEDIZIONE;
CREATE TABLE SPEDIZIONE (
    CodSpedizione INT PRIMARY KEY AUTO_INCREMENT,
    DataPartenza DATE DEFAULT(CURRENT_DATE) NOT NULL,
    DataArrivo DATE DEFAULT(NULL),
    DataPrevista DATE NOT NULL,
    Stato VARCHAR(11) DEFAULT('Spedita') NOT NULL,
    Ordine INT NOT NULL REFERENCES ORDINE(CodOrdine) ON DELETE NO ACTION ON UPDATE CASCADE,
    CHECK(Stato='Spedita' OR Stato='In transito' OR Stato='In consegna' OR Stato='Consegnata')
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS STORICO_STOCCAGGIO;
CREATE TABLE STORICO_STOCCAGGIO (
    Lotto INT REFERENCES LOTTO(CodiceLotto) ON DELETE NO ACTION ON UPDATE CASCADE,
    Magazzino INT REFERENCES MAGAZZINO(CodMagazzino) ON DELETE NO ACTION ON UPDATE CASCADE,
    Area VARCHAR(3) NOT NULL,                      /*A11,B12,C35*/
    DataInizioStock DATE NOT NULL,
    DataFineStock DATE DEFAULT(NULL),
    PRIMARY KEY(Lotto, Magazzino)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS STRUMENTO;
CREATE TABLE STRUMENTO (
    Operazione INT REFERENCES OPERAZIONE(CodiceOp) ON DELETE CASCADE ON UPDATE CASCADE,
    Utensile VARCHAR(30) REFERENCES UTENSILE(NomeUtensile) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(Operazione, Utensile)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS STRUTTURA;
CREATE TABLE STRUTTURA (
    Parte INT REFERENCES PARTE(CodParte) ON DELETE NO ACTION ON UPDATE CASCADE,
    ModelloProd VARCHAR(10),
    MarcaProd VARCHAR(20),
    Numero TINYINT NOT NULL DEFAULT(1),
    PRIMARY KEY(ModelloProd, MarcaProd, Parte),
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS TECNICO;
CREATE TABLE TECNICO (
    Matricola INT PRIMARY KEY AUTO_INCREMENT,
    AreaGeografica INT NOT NULL REFERENCES AREA_GEOGRAFICA(CodArea) ON DELETE SET NULL ON UPDATE CASCADE,
    CostoManodopera NUMERIC(4,2) NOT NULL,
    DataNascita DATE NOT NULL,
    CHECK(CostoManodopera > 15)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS TEST;
CREATE TABLE TEST (
    CodiceTest INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(30) NOT NULL,
    Ordine TINYINT NOT NULL,
    TestPadre INT REFERENCES TEST(CodiceTest) ON DELETE CASCADE ON UPDATE CASCADE,
    ModelloProd VARCHAR(10),
    MarcaProd VARCHAR(20),
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK(Ordine > 0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS TRACKING;
CREATE TABLE TRACKING (
    Spedizione INT REFERENCES SPEDIZIONE(CodSpedizione) ON DELETE CASCADE ON UPDATE CASCADE,
    Hub INT REFERENCES HUB(CodiceHub) ON DELETE CASCADE ON UPDATE CASCADE,
    DataTransito TIMESTAMP DEFAULT(CURRENT_TIMESTAMP) NOT NULL,
    PRIMARY KEY(Spedizione, Hub)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS UNITA;
CREATE TABLE UNITA (
    CodSer INT PRIMARY KEY AUTO_INCREMENT,
    DataProduzione DATE DEFAULT(CURRENT_DATE) NOT NULL,
    DataSpedizione DATE DEFAULT(NULL),
    ModelloProd VARCHAR(10) NOT NULL,
    MarcaProd VARCHAR(20) NOT NULL,
    Lotto INT NOT NULL REFERENCES LOTTO(CodiceLotto) ON DELETE NO ACTION ON UPDATE CASCADE,
    Spedizione INT REFERENCES SPEDIZIONE(CodSpedizione) ON DELETE NO ACTION ON UPDATE CASCADE,
    Ordine INT REFERENCES ORDINE(CodOrdine) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY(ModelloProd,MarcaProd) REFERENCES PRODOTTO(Modello,Marca) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS UNITA_PERSA;
CREATE TABLE UNITA_PERSA (
    CodPersa INT PRIMARY KEY AUTO_INCREMENT,
    Orario TIMESTAMP NOT NULL,
    NumStazione SMALLINT NOT NULL,
    Linea INT NOT NULL,
    Lotto INT NOT NULL REFERENCES LOTTO(CodiceLotto) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(NumStazione, Linea) REFERENCES STAZIONE(NumStazione, Linea) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS UNITA_RESA;
CREATE TABLE UNITA_RESA (
    Unita INT PRIMARY KEY AUTO_INCREMENT REFERENCES UNITA(CodSer) ON DELETE CASCADE ON UPDATE CASCADE,
    DataStoccaggio DATE NOT NULL,
    Lotto INT NOT NULL REFERENCES LOTTO(CodiceLotto) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS UNITA_RICONDIZIONATA;
CREATE TABLE UNITA_RICONDIZIONATA (
    Unita INT PRIMARY KEY AUTO_INCREMENT REFERENCES UNITA(CodSer) ON DELETE CASCADE ON UPDATE CASCADE,
    Categoria CHAR,
    Prezzo NUMERIC(8,2) NOT NULL,
    CHECK(Prezzo > 0 AND (Categoria = 'A' OR Categoria = 'B' OR Categoria IS NULL))
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS UTENSILE;
CREATE TABLE UTENSILE (
    NomeUtensile VARCHAR(30) PRIMARY KEY
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS UTENTE;
CREATE TABLE UTENTE (
    CodFiscale CHAR(16) PRIMARY KEY,
    Nome VARCHAR(20) NOT NULL,
    Cognome VARCHAR(30) NOT NULL,
    DataNascita DATE NOT NULL,
    DataIscrizione DATE DEFAULT(CURRENT_DATE) NOT NULL,
    NumTel NUMERIC(10) NOT NULL,
    Via VARCHAR(50) NOT NULL,
    NumCivico VARCHAR(4) NOT NULL,
    Citta VARCHAR(50) NOT NULL,
    Documento VARCHAR(10) NOT NULL REFERENCES DOCUMENTO(NumDoc) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY(Via, NumCivico, Citta) REFERENCES INDIRIZZO(Via, NumCivico, Citta) ON DELETE NO ACTION ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS VINCOLO;
CREATE TABLE VINCOLO (
    OpPrecedente INT REFERENCES OPERAZIONE(CodiceOp) ON DELETE CASCADE ON UPDATE CASCADE,
    OpSuccessiva INT REFERENCES OPERAZIONE(CodiceOp) ON DELETE CASCADE ON UPDATE CASCADE,
    Peso SMALLINT,
    PRIMARY KEY(OpPrecedente, OpSuccessiva),
    CHECK(Peso > 0)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;

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

IF @dataPreventivo > NEW.Data THEN /*AVEVAMO SBAGLIATO*/
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
AND IP.OrarioPrev = OLD.OrarioPrev;


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
AND IR.OrarioRip = OLD.OrarioRip;


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

/*---------------------------------------------------------------------------------------------------------------------------*/

/*Creazione di un intervento preventivo*/

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

/*USE Progetto;*/

/*Efficienza di sequenza*/

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

COMMIT;