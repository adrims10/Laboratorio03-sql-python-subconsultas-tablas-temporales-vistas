## Ejercicio 1. Queries Generales

1.1. Calcula el promedio más bajo y más alto de temperatura.

select max(temperatura) as temperatura_max, min(temperatura) as temperatura_min
from clima c ;

1.2. Obtén los municipios en los cuales coincidan las medias de la sensación térmica y de la temperatura. 

select m.id_municipio ,c.temperatura,c.sensacion 
from municipios m 
inner join clima c 
on m.id_municipio = c.municipio_id 
where temperatura =temperatura and sensacion =sensacion;


1.3. Obtén el local más cercano de cada municipio

select l.nombre,l.distancia,m.nombre 
from locales l 
inner join municipios m 
on l.id_municipio = m.id_municipio 
order by l.distancia 

1.4. Localiza los municipios que posean algún localizador a una distancia mayor de 2000 y que posean al menos 25 locales.

select count(m.id_municipio),l.nombre,count(distancia) as distancia_k
from municipios m 
inner join locales l 
on m.id_municipio = l.id_municipio
group by l.nombre 
order by distancia_k desc

1.5. Teniendo en cuenta que el viento se considera leve con una velocidad media de entre 6 y 20 km/h, moderado con una media de entre 21 y 40 km/h,
fuerte con media de entre 41 y 70 km/h y muy fuerte entre 71 y 120 km/h. Calcula cuántas rachas de cada tipo tenemos en cada uno de los días.
Este ejercicio debes solucionarlo con la sentencia CASE de SQL (no la hemos visto en clase, por lo que tendrás que buscar la documentación). 

select racha_max, 
CASE WHEN racha_max > 71 THEN 'High'
        WHEN racha_max <= 70 AND racha_max > 41 THEN 'Moderate'
        ELSE 'Low'
    END AS temperature_category
from clima c 

select temperature_category
from(select racha_max, 
CASE WHEN racha_max > 71 THEN 'High'
        WHEN racha_max <= 70 AND racha_max > 41 THEN 'Moderate'
        ELSE 'Low'
    END AS temperature_category
from clima c) as tabla_category
where temperature_category = 'Low'

select temperature_category
from(select racha_max, 
CASE WHEN racha_max > 71 THEN 'High'
        WHEN racha_max <= 70 AND racha_max > 41 THEN 'Moderate'
        ELSE 'Low'
    END AS temperature_category
from clima c) as tabla_category
where temperature_category = 'High'

select temperature_category
from(select racha_max, 
CASE WHEN racha_max > 71 THEN 'High'
        WHEN racha_max <= 70 AND racha_max > 41 THEN 'Moderate'
        ELSE 'Low'
    END AS temperature_category
from clima c) as tabla_category
where temperature_category = 'Moderate'


## Ejercicio 2. Vistas

2.1. Crea una vista que muestre la información de los locales que tengan incluido el código postal en su dirección. 

create view Tabla_codigos_postales as
SELECT direccion
FROM locales
WHERE direccion ~ '\d{5}';

2.2. Crea una vista con los locales que tienen más de una categoría asociada.

create view Tabla_categorias as
select nombre,count(categoria) over (partition by categoria) as "cat" 
from locales l ;

2.3. Crea una vista que muestre el municipio con la temperatura más alta de cada día
create view Tabla_temperaturasmax as
select m.id_municipio,max(c.temperatura)
from municipios m 
inner join clima c 
on m.id_municipio = c.municipio_id 
group by m.id_municipio 


2.4. Crea una vista con los municipios en los que haya una probabilidad de precipitación mayor del 100% durante mínimo 7 horas.


2.5. Obtén una lista con los parques de los municipios que tengan algún castillo.

create view castillo as
select l.categoria,m.nombre 
from locales l 
inner join municipios m 
on l.id_municipio = m.id_municipio 
where categoria ='Castle'
 
## Ejercicio 3. Tablas Temporales

3.1. Crea una tabla temporal que muestre cuántos días han pasado desde que se obtuvo la información de la tabla AEMET.

CREATE TEMPORARY TABLE dias_desde_actualizacion AS
select municipio_id, CURRENT_DATE - fecha AS dias_transcurridos
from clima;

3.2. Crea una tabla temporal que muestre los locales que tienen más de una categoría asociada e indica el conteo de las mismas

CREATE TEMPORARY TABLE locales_multicategoria AS
select id_local,nombre, COUNT(categoria)
from locales
GROUP by id_local, nombre
having COUNT(categoria) > 1;


3.3. Crea una tabla temporal que muestre los tipos de cielo para los cuales la probabilidad de precipitación mínima de los promedios de cada día es 5.

CREATE TEMPORARY TABLE tiposprecipitacion AS
select cielo, AVG(precipitacion) AS promedio_prob_precipitacion
from clima
GROUP by cielo
having AVG(precipitacion) >= 5;


3.4. Crea una tabla temporal que muestre el tipo de cielo más y menos repetido por municipio.

CREATE TEMPORARY TABLE cielo_repetido AS
WITH conteo_cielo AS (
select municipio_id,cielo,COUNT(*) AS total
from clima
GROUP by municipio_id, cielo),
ranking AS (SELECT
        municipio_id,
        cielo,
        total,
        ROW_NUMBER() OVER (PARTITION BY municipio_id ORDER BY total DESC) AS rango_mas_repetido,
        ROW_NUMBER() OVER (PARTITION BY municipio_id ORDER BY total ASC) AS rango_menos_repetido
    	FROM
        conteo_cielo)
		SELECT
    	municipio_id,
  		 MAX(CASE WHEN rango_mas_repetido = 1 THEN cielo END) AS cielo_mas_repetido,
    	MAX(CASE WHEN rango_menos_repetido = 1 THEN cielo END) AS cielo_menos_repetido
		from ranking
		GROUP By municipio_id;
	
	
## Ejercicio 4. SUBQUERIES

4.1. Necesitamos comprobar si hay algún municipio en el cual no tenga ningún local registrado.

select m.id_municipio, m.nombre
from  municipios m
where m.id_municipio NOT IN ( select l.id_municipio from locales l);

4.2. Averigua si hay alguna fecha en la que el cielo se encuente "Muy nuboso con tormenta".

SELECT fecha
FROM clima
WHERE cielo = 'Muy nuboso con tormenta'
AND EXISTS (SELECT 1 FROM clima c WHERE c.cielo = 'Muy nuboso con tormenta');


4.3. Encuentra los días en los que los avisos sean diferentes a "Sin riesgo".
SELECT DISTINCT fecha
FROM clima
WHERE  aviso <> 'Sin riesgo'
AND EXISTS (SELECT 1 FROM  clima c
WHERE c.aviso <> 'Sin riesgo' AND c.fecha = clima.fecha);				He dropeado la columna avisos

4.4. Selecciona el municipio con mayor número de locales.

SELECT  m.id_municipio, m.nombre
FROM municipios m
WHERE (SELECT COUNT(*) 
FROM locales l 
WHERE l.id_municipio = m.id_municipio) = (SELECT MAX(local_count) FROM (SELECT COUNT(*) AS local_count FROM locales
GROUP BY id_municipio) AS subquery);


4.5. Obtén los municipios muya media de sensación térmica sea mayor que la media total.

SELECT  m.id_municipio,m.nombre
FROM municipios m
WHERE (SELECT  AVG(c.sensacion) FROM  clima c
WHERE c.municipio_id = m.id_municipio) > (SELECT AVG(sensacion)FROM clima);


4.6. Selecciona los municipios con más de dos fuentes.

no tengo fuentes....

4.7. Localiza la dirección de todos los estudios de cine que estén abiertod en el municipio de "Madrid".

SELECT l.direccion
FROM locales l
WHERE  l.categoria = 'Estudio de cine' AND l.estado = 'Abierto'AND l.id_municipio IN (
SELECT m.id_municipio
FROM municipios m
where m.nombre = 'Madrid')

4.8. Encuentra la máxima temperatura para cada tipo de cielo.

SELECT cielo, MAX(temperatura) AS max_temperatura
FROM clima
GROUP BY cielo;

4.9. Muestra el número de locales por categoría que muy probablemente se encuentren abiertos.

SELECT l.categoria,COUNT(*) AS num_locales
FROM locales l
WHERE l.estado IN ('Abierto', 'Probablemente abierto')
GROUP BY l.categoria;

BONUS. 4.10. Encuentra los municipios que tengan más de 3 parques, los cuales se encuentren a una distancia menor de las coordenadas de su municipio correspondiente que la del Parque Pavia. Además, el cielo debe estar despejado a las 12.


