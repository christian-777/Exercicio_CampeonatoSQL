CREATE DATABASE Exercicio_Campeonato;
go

use Exercicio_Campeonato;
GO

create table TimeFutebol(
    Id int IDENTITY(1,1) not null, 
    Nome VARCHAR(50) not null, 
    Apelido VARCHAR(50) null,
    DataCriacao DATETIME not null,
    GolsContra int, 
    GolsPro int, 
    Pontuacao int,
    Vitoria int,

    CONSTRAINT PK_TimeFutebol PRIMARY KEY (Id),
    CONSTRAINT UN_TimeFutebol UNIQUE (Nome)
)
GO

CREATE TABLE Jogo(
    Id int IDENTITY(1,1)  not null,
    Mandante int not null,
    Visitante INT not NULL,
    GolsMandante int, 
    GolsVisitante int, 
    TotalGols int,

    CONSTRAINT PK_Jogo PRIMARY KEY (Id),
    CONSTRAINT UN_Jogo UNIQUE (Mandante, Visitante),
    CONSTRAINT FK_Jogo_Mandante FOREIGN KEY (Mandante) REFERENCES TimeFutebol(Id),
    CONSTRAINT FK_Jogo_Visitante FOREIGN KEY (Visitante) REFERENCES TimeFutebol(Id)
)
GO

--PROCEDURE para inserção de times com gols e pontuação zerados
create or alter PROCEDURE InsereTime @Nome VARCHAR(50), @dataCriacao DATETIME
AS
BEGIN
    INSERT into TimeFutebol (Nome, DataCriacao, GolsContra, GolsPro, Pontuacao, Vitoria) VALUES (@Nome, @dataCriacao, 0, 0, 0, 0)
end
GO

--procedure para colocaar um apelido ao time
create or alter PROCEDURE InsereApelido @Nome VARCHAR(50), @apelido VARCHAR(50)
AS
BEGIN
    DECLARE @id int
    SELECT @id=id from TimeFutebol where Nome=@Nome
    UPDATE TimeFutebol set Apelido=@apelido where id=@id
end
GO

--procedure para impedir que um time jogue contra ele mesmo e inserir uma partida na tabela jogo
create or ALTER PROCEDURE InserirJogo @time1 int, @time2 int,  @golsMandante int, @golsVisitante int 
as 
BEGIN
    if(@time1!=@time2)
        INSERT into Jogo (Mandante, Visitante, GolsMandante, GolsVisitante) values (@time1, @time2, @golsMandante, @golsVisitante)
    ELSE
        PRINT('invalido! um time nao joga contra ele mesmo')
END
GO

--trigger que controla os gols e os pontos tanto da tabela jogo quanto da TimeFutebol
create or alter TRIGGER TGR_Gols_Pontos on Jogo after INSERT 
as
BEGIN
    DECLARE @Mandante int, @Visitante int, @golsMandante int, @golsVisitante int

    select @Mandante=Mandante, @Visitante=Visitante, @golsMandante=GolsMandante, @golsVisitante=GolsVisitante FROM inserted

    update Jogo set TotalGols=(@golsMandante + @golsVisitante) where Mandante=@Mandante and Visitante=@Visitante

    If(@golsMandante>@golsVisitante)
        UPDATE TimeFutebol set Vitoria+=1 WHERE Id=@Mandante
    If(@golsMandante<@golsVisitante)
        UPDATE TimeFutebol set Vitoria+=1 WHERE Id=@Visitante

    UPDATE TimeFutebol set GolsPro+=@golsMandante, GolsContra+=@golsVisitante, 
    Pontuacao+= case 
                    when(@golsMandante=@golsVisitante) then 1
                    when (@golsMandante>@golsVisitante) then 3
                    else 0 
                end
    where Id=@Mandante

    UPDATE TimeFutebol set GolsPro+=@golsVisitante, GolsContra+=@golsMandante, 
    Pontuacao+= case 
                    when(@golsMandante=@golsVisitante) then 1
                    when (@golsMandante<@golsVisitante) then 5
                    else 0 
                end
    where Id=@Visitante
END
GO

--procedure para mostrar o ganhador
create or alter PROCEDURE MostrarGanhador
AS
BEGIN
    DECLARE @ponts int, @id int, @aux int, @vitoria int

    SELECT top 1 @ponts=pontuacao , @id=id from TimeFutebol ORDER by Pontuacao DESC

    SELECT @aux=id from TimeFutebol where pontuacao=@ponts

    if(@id!=@aux)
    BEGIN
        SELECT top 1 @vitoria=Vitoria , @id=id from TimeFutebol ORDER by Pontuacao DESC
        SELECT @aux=id from TimeFutebol where Vitoria=@vitoria

        if(@id!=@aux)
            SELECT top 1 nome, pontuacao from TimeFutebol where pontuacao=@ponts order by (GolsPro-GolsContra) desc
        else
            SELECT top 1 nome, pontuacao from TimeFutebol where pontuacao=@ponts order by Vitoria desc
    END
    else
        SELECT top 1 nome, pontuacao from TimeFutebol ORDER by Pontuacao DESC
END
GO

--procedure para mostrar a Classificao
create or alter PROCEDURE MostrarRank
AS
BEGIN
    SELECT nome, pontuacao, (GolsPro-GolsContra) as saldoGol, Vitoria from TimeFutebol order by pontuacao desc, saldoGol desc, vitoria desc
END
GO

--procedure para mostrar quem fez mais gols
create or alter PROCEDURE MostrarMaisGols
AS
BEGIN
    SELECT top 1 nome, GolsPro from TimeFutebol ORDER by GolsPro DESC
END
GO

--procedure para mostrar quem tomou mais gols
create or alter PROCEDURE MostrarMaisGolsContra
AS
BEGIN
    SELECT top 1 nome, GolsContra from TimeFutebol ORDER by GolsContra DESC
END
GO

--procedure para mostrar o jogo que teve mais gols
create or alter PROCEDURE MostrarJogoMaisGols
AS
BEGIN
    SELECT top 1 nome as NomeMandante , (select top 1 nome from Jogo join TimeFutebol on TimeFutebol.Id=Jogo.Visitante ORDER by TotalGols DESC) as NomeVisitante, TotalGols from Jogo join TimeFutebol on TimeFutebol.Id=Jogo.Mandante ORDER by TotalGols DESC
END
GO

--procedure para mostrar o jogo que teve mais gols de cada time
create or alter PROCEDURE MostrarTimeMaisGols 
AS
BEGIN
    DECLARE @aux VARCHAR(20)
    SELECT nome, (select top 1 GolsMandante from jogo where Mandante=TimeFutebol.id order by GolsMandante desc) as GolsMandante, 
    (select top 1 GolsVisitante from jogo where Visitante=TimeFutebol.id order by  GolsVisitante desc) as golsVisitante 
    from TimeFutebol; 
END
GO

--inserts na tabela TimeFutebl
EXEC.InsereTime 'chris fc', '2002-06-04'
EXEC.InsereApelido 'chris fc', 'Ferreira'
EXEC.InsereTime 'papine fc', '2001-01-01'
EXEC.InsereTime 'pestana fc', '2002-02-02'
EXEC.InsereTime 'giovani fc', '2003-03-03'
EXEC.InsereTime 'ana fc', '2004-04-04'


--Inserts na tabela jogo
EXEC.InserirJogo 1,2,3,2 
EXEC.InserirJogo 1,3,2,1 
EXEC.InserirJogo 1,4,0,2
EXEC.InserirJogo 1,5,1,2

EXEC.InserirJogo 2,1,4,3 
EXEC.InserirJogo 2,3,7,2 
EXEC.InserirJogo 2,4,1,3
EXEC.InserirJogo 2,5,0,4

EXEC.InserirJogo 3,1,1,0 
EXEC.InserirJogo 3,2,4,1 
EXEC.InserirJogo 3,4,0,3
EXEC.InserirJogo 3,5,1,4

EXEC.InserirJogo 4,1,5,1 
EXEC.InserirJogo 4,2,7,0 
EXEC.InserirJogo 4,3,3,4
EXEC.InserirJogo 4,5,2,5

EXEC.InserirJogo 5,1,5,1 
EXEC.InserirJogo 5,2,7,1 
EXEC.InserirJogo 5,3,1,7
EXEC.InserirJogo 5,4,0,1

--Tabela de tinmes
select * from TimeFutebol
GO

--Tabela de Jogos
SELECT * from Jogo
GO

--Mostrado o Ganhador
EXEC.MostrarGanhador

--Mostrando a classificacao
EXEC.MostrarRank

--Mostrando o Time que mais fez gols
EXEC.MostrarMaisGols

--Mostrando o Time que mais sofreu gols
EXEC.MostrarMaisGolsContra

--Mostra o jogo que mais teve gols
EXEC.MostrarJogoMaisGols

--Mostrando jogo com mais gols de cada time 
EXEC.MostrarTimeMaisGols
GO