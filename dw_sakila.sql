
#Dimensão Cliente
CREATE  VIEW SAKILA.dim_cliente as (
		SELECT 
		c.customer_id as id_cliente,
		CONCAT(c.first_name, " ", c.last_name) as nome,
		c.active as ativo,
		ci.city as cidade, co.country as pais
	FROM 
		SAKILA.customer c, SAKILA.address a, SAKILA.city ci, SAKILA.country co
	WHERE
		c.address_id = a.address_id AND 
		a.city_id = ci.city_id AND
		ci.country_id = co.country_id
        );

#Dimensão Filme
CREATE  VIEW SAKILA.dim_filme as (
	SELECT
		f.film_id as id_filme,
		f.title as titulo,
		f.release_year as ano_lanc,
		f.rental_duration as dur_aluguel,
		f.rental_rate as taxa_aluguel,
		CASE
			 WHEN f.rating = "G" THEN "Livre"
			 WHEN f.rating = "PG" THEN "12 anos"
			 WHEN f.rating = "PG-13" THEN "14 anos"
			 WHEN f.rating = "R" THEN "16 anos"
			 WHEN f.rating = "NC-17" THEN "18 anos"
		END AS faixa_etaria,
		c.name as categoria
	FROM
		SAKILA.film f, SAKILA.film_category fc, SAKILA.category c
	WHERE
		f.film_id = fc.film_id AND
		fc.category_id = c.category_id);
    
#Dimensão  Auxiliar Loja (Irá se referenciar à Dimensão Gerente)
CREATE VIEW SAKILA.dim_loja as (
	SELECT
		s.store_id as id_loja,
		st.staff_id as id_gerente,
		ci.city as cidade,
		co.country as pais
	FROM
		SAKILA.store s, SAKILA.staff st, SAKILA.address a, SAKILA.city ci, SAKILA.country co
	WHERE
		s.manager_staff_id = st.staff_id AND
		s.address_id = a.address_id AND
		a.city_id = ci.city_id AND
		ci.country_id = co.country_id);
        
#Dimensão Gerente
CREATE VIEW SAKILA.dim_gerente as (
	SELECT
		st.staff_id as id_gerente,
		CONCAT(st.first_name, " ", st.last_name) as nome_funcionario,
		st.active as ativo,
		ci.city as cidade,
		co.country as pais
	FROM
		SAKILA.staff st, SAKILA.address a, SAKILA.city ci, SAKILA.country co
	WHERE
		st.address_id = a.address_id AND
		a.city_id = ci.city_id AND
		ci.country_id = co.country_id);


#Fato_Pagamento
CREATE VIEW SAKILA.fato_pagamento as (
SELECT
		p.payment_id as id_pagamento,
		p.customer_id as id_cliente,
		p.staff_id as id_gerente,
		i.film_id as id_filme,
		DATE(P.payment_date) as data_pagamento,
        CASE
			WHEN DATE(r.return_date) IS NULL THEN  DATE(P.payment_date)
            ELSE DATE(r.return_date)
        END as data_retorno,
		p.amount as valor
FROM
	SAKILA.payment p, SAKILA.rental r, SAKILA.inventory i
WHERE
	p.rental_id = r.rental_id AND
	r.inventory_id = i.inventory_id
);

#Criando o esquema do DW
CREATE SCHEMA dw_sakila;

CREATE TABLE dw_sakila.dim_cliente as 
	SELECT * FROM sakila.dim_cliente;
    
CREATE TABLE dw_sakila.dim_filme as 
	SELECT * FROM sakila.dim_filme;

CREATE TABLE dw_sakila.dim_gerente as 
	SELECT * FROM sakila.dim_gerente;
    
CREATE TABLE dw_sakila.dim_loja as 
	SELECT * FROM sakila.dim_loja;

CREATE TABLE dw_sakila.fato_pagamento as
SELECT * FROM sakila.fato_pagamento;

#Dimensão Tempo
CREATE  TABLE dw_sakila.Dim_Tempo (
    data_completa DATE,
    ano INT,
    nr_mes INT,
    nm_mes VARCHAR(20),
    trimestre INT,
    nr_dia INT,	
    nm_dia_semana VARCHAR(20)
    );

#Procedure para alimentar a Dim_Tempo
DELIMITER //
CREATE PROCEDURE dw_sakila.carrega_dim_tempo (IN data_inicio DATE, IN data_fim DATE)
BEGIN
	DECLARE data_controle  DATE;
    SET data_controle = data_inicio;
    WHILE data_controle <= data_fim DO
		INSERT INTO Dim_Tempo VALUES (
            DATE(data_controle),
            YEAR(data_controle),
            MONTH(data_controle),
            MONTHNAME(data_controle),
            QUARTER(data_controle),
            DAY(data_controle),
            DAYNAME(data_controle));
		SET data_controle = ADDDATE(data_controle, INTERVAL 1 DAY);
    END WHILE;
END//

#Chamando a procedure
CALL dw_sakila.carrega_dim_tempo("2000-01-01", "2010-01-01");

ALTER TABLE dw_sakila.dim_cliente ADD CONSTRAINT pk_id_cliente PRIMARY KEY (id_cliente);
ALTER TABLE dw_sakila.fato_pagamento ADD CONSTRAINT fk_id_cliente FOREIGN KEY (id_cliente) REFERENCES dw_sakila.dim_cliente(id_cliente);

ALTER TABLE dw_sakila.dim_filme ADD CONSTRAINT pk_id_filme PRIMARY KEY (id_filme);
ALTER TABLE dw_sakila.fato_pagamento ADD CONSTRAINT fk_id_filme FOREIGN KEY (id_filme) REFERENCES dw_sakila.dim_filme(id_filme);

ALTER TABLE dw_sakila.dim_gerente ADD CONSTRAINT pk_id_gerente PRIMARY KEY (id_gerente);
ALTER TABLE dw_sakila.dim_loja ADD CONSTRAINT pk_id_loja PRIMARY KEY (id_loja);
ALTER TABLE dw_sakila.dim_loja ADD CONSTRAINT fk_id_gerente FOREIGN KEY (id_gerente) REFERENCES dw_sakila.dim_gerente(id_gerente);
ALTER TABLE dw_sakila.fato_pagamento ADD CONSTRAINT fk_id_gerente2 FOREIGN KEY (id_gerente) REFERENCES dw_sakila.dim_gerente(id_gerente);

ALTER TABLE dw_sakila.dim_tempo ADD CONSTRAINT pk_data_completa PRIMARY KEY (data_completa);
ALTER TABLE dw_sakila.fato_pagamento ADD CONSTRAINT fk_data_completa FOREIGN KEY (data_pagamento) REFERENCES dw_sakila.dim_tempo(data_completa);
ALTER TABLE dw_sakila.fato_pagamento ADD CONSTRAINT fk_data_completa2 FOREIGN KEY (data_retorno) REFERENCES dw_sakila.dim_tempo(data_completa);

ALTER TABLE dw_sakila.fato_pagamento ADD CONSTRAINT pk_fato_pagamento PRIMARY KEY (id_cliente, id_filme, id_gerente, data_pagamento, data_retorno);











    




    


    



	

    

	