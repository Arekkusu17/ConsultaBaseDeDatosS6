------------------------------------
-- CASO 1: Reportería de Asesorías
------------------------------------

SELECT 
       t.id_profesional                                                         AS "ID",
       (
        SELECT INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre)
        FROM profesional p
        WHERE p.id_profesional = t.id_profesional
        )                                                                       AS "PROFESIONAL",
       SUM(t.c_banca)                                                           AS "NRO ASESORIA BANCA",
       TO_CHAR(SUM(t.h_banca),'$999G999G999')                                   AS "MONTO_TOTAL_BANCA",
       SUM(t.c_retail)                                                          AS "NRO ASESORIA RETAIL",
       TO_CHAR(SUM(t.h_retail),'$999G999G999')                                  AS "MONTO_TOTAL_RETAIL",
       (SUM(t.c_banca) + SUM(t.c_retail))                                       AS "TOTAL ASESORIAS",
       TO_CHAR((SUM(t.h_banca) + SUM(t.h_retail)),'$999G999G999')               AS "TOTAL HONORARIOS"
FROM (
       -- Registros Banca
       SELECT a.id_profesional,
              COUNT(*) AS c_banca,
              SUM(a.honorario) AS h_banca,
              0 AS c_retail,
              0 AS h_retail
       FROM asesoria a
       JOIN empresa e ON a.cod_empresa = e.cod_empresa
       WHERE e.cod_sector = 3  --codigo de sector banca
       GROUP BY a.id_profesional

       UNION ALL 

       -- Registros Retail
       SELECT a.id_profesional,
              0 AS c_banca,
              0 AS h_banca,
              COUNT(*) AS c_retail,
              SUM(a.honorario) AS h_retail
       FROM asesoria a
       JOIN empresa e ON a.cod_empresa = e.cod_empresa
       WHERE e.cod_sector = 4 -- codigo de sector retail
       GROUP BY a.id_profesional
) t
-- profesionales con asesorías en ambos sectores
HAVING SUM(t.c_banca) > 0
   AND SUM(t.c_retail) > 0
GROUP BY t.id_profesional
ORDER BY t.id_profesional ASC;


--Other approach for case 1 could be:
SELECT
  p.id_profesional AS ID,
  p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS PROFESIONAL,
  (SELECT COUNT(*) 
     FROM asesoria a 
     JOIN empresa e ON a.cod_empresa = e.cod_empresa 
    WHERE a.id_profesional = p.id_profesional 
      AND e.cod_sector = 3) AS "NRO ASESORIA BANCA",
  TO_CHAR((SELECT NVL(SUM(a.honorario), 0)
     FROM asesoria a 
     JOIN empresa e ON a.cod_empresa = e.cod_empresa 
    WHERE a.id_profesional = p.id_profesional 
      AND e.cod_sector = 3),'$99G999G999') AS "MONTO_TOTAL_BANCA",
  (SELECT COUNT(*) 
     FROM asesoria a 
     JOIN empresa e ON a.cod_empresa = e.cod_empresa 
    WHERE a.id_profesional = p.id_profesional 
      AND e.cod_sector = 4) AS "NRO ASESORIA RETAIL",
  TO_CHAR((SELECT NVL(SUM(a.honorario), 0)
     FROM asesoria a 
     JOIN empresa e ON a.cod_empresa = e.cod_empresa 
    WHERE a.id_profesional = p.id_profesional 
      AND e.cod_sector = 4),'$99G999G999') AS "MONTO_TOTAL_RETAIL",
  (
    (SELECT COUNT(*) 
       FROM asesoria a 
       JOIN empresa e ON a.cod_empresa = e.cod_empresa 
      WHERE a.id_profesional = p.id_profesional 
        AND e.cod_sector = 3) +
    (SELECT COUNT(*) 
       FROM asesoria a 
       JOIN empresa e ON a.cod_empresa = e.cod_empresa 
      WHERE a.id_profesional = p.id_profesional 
        AND e.cod_sector = 4)
  ) AS "TOTAL ASESORIAS",
  TO_CHAR((
    (SELECT NVL(SUM(a.honorario), 0)
       FROM asesoria a 
       JOIN empresa e ON a.cod_empresa = e.cod_empresa 
      WHERE a.id_profesional = p.id_profesional 
        AND e.cod_sector = 3) +
    (SELECT NVL(SUM(a.honorario), 0)
       FROM asesoria a 
       JOIN empresa e ON a.cod_empresa = e.cod_empresa 
      WHERE a.id_profesional = p.id_profesional 
        AND e.cod_sector = 4)
  ),'$99G999G999') AS "TOTAL HONORARIOS"
FROM profesional p
WHERE p.id_profesional IN (
  SELECT id_profesional FROM (
    SELECT id_profesional
    FROM asesoria a
    JOIN empresa e ON a.cod_empresa = e.cod_empresa
    WHERE e.cod_sector = 3
    INTERSECT
    SELECT id_profesional
    FROM asesoria a
    JOIN empresa e ON a.cod_empresa = e.cod_empresa
    WHERE e.cod_sector = 4
  )
)
ORDER BY ID ASC;



------------------------------------
-- CASO 2: Reportería de Mes
------------------------------------
--DROP TABLE REPORTE_MES;
CREATE TABLE REPORTE_MES (
    ID_PROF   NUMBER(10),
    NOMBRE_COMPLETO  VARCHAR2(60),
    NOMBRE_PROFESION        VARCHAR2(40),
    NOM_COMUNA           VARCHAR2(40),
    NRO_ASESORIAS   NUMBER(6),
    MONTO_TOTAL_HONORARIOS      NUMBER(12),
    PROMEDIO_HONORARIO       NUMBER(12),
    HONORARIO_MINIMO        NUMBER(12),
    HONORARIO_MAXIMO        NUMBER(12)
);

INSERT INTO REPORTE_MES
SELECT 
    p.id_profesional                                                            AS "ID_PROF",
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre)               AS "NOMBRE_COMPLETO",
    pr.nombre_profesion                                                         AS "NOMBRE_PROFESION",
    c.nom_comuna                                                                AS "NOM_COMUNA",
    COUNT(*)                                                                    AS "NRO ASESORIAS",
    ROUND(SUM(a.honorario))                                                     AS "MONTO_TOTAL_HONORARIOS",
    ROUND(AVG(a.honorario))                                                     AS "PROMEDIO_HONORARIO",
    ROUND(MIN(a.honorario))                                                     AS "HONORARIO_MINIMO",
    ROUND(MAX(a.honorario))                                                     AS "HONORARIO_MAXIMO"
FROM 
    asesoria a
JOIN 
    profesional p ON p.id_profesional = a.id_profesional
JOIN 
    profesion pr ON pr.cod_profesion = p.cod_profesion
JOIN 
    comuna c ON c.cod_comuna = p.cod_comuna
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 4
  AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY p.id_profesional, 
         p.appaterno, p.apmaterno, p.nombre,
         pr.nombre_profesion,
         c.nom_comuna
ORDER BY p.id_profesional ASC;
COMMIT;

SELECT * FROM REPORTE_MES;


------------------------------------
-- CASO 3: Modificación de Honorarios
------------------------------------

--ANTES

SELECT 
    NVL((
        SELECT ROUND(SUM(a.honorario))
        FROM asesoria a
        WHERE a.id_profesional = p.id_profesional
          AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
          AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
    ),0)                                                                                AS "HONORARIO",
    p.id_profesional                                                                    AS "ID_PROFESIONAL",
    p.numrun_prof                                                                       AS "NUMRUN_PROF",
    p.sueldo                                                                            AS "SUELDO"
FROM profesional p
JOIN 
    asesoria a ON a.id_profesional = p.id_profesional
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 3
  AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY 
    p.id_profesional, 
    p.numrun_prof, 
    p.sueldo
ORDER BY p.id_profesional;

-- UPDATE

UPDATE profesional p
SET p.sueldo =
    (
        SELECT 
            CASE 
                WHEN NVL(SUM(a.honorario),0) < 1000000 
                    THEN ROUND(p.sueldo * 1.10)
                ELSE ROUND(p.sueldo * 1.15)
            END
        FROM asesoria a
        WHERE a.id_profesional = p.id_profesional
          AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
          AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
        GROUP BY a.id_profesional
    )
WHERE EXISTS (
    SELECT 1
    FROM asesoria a
    WHERE a.id_profesional = p.id_profesional
      AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
      AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
);

COMMIT;

-- despues
SELECT 
    NVL((
        SELECT ROUND(SUM(a.honorario))
        FROM asesoria a
        WHERE a.id_profesional = p.id_profesional
          AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
          AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
    ),0)                                                                                AS "HONORARIO",
    p.id_profesional                                                                    AS "ID_PROFESIONAL",
    p.numrun_prof                                                                       AS "NUMRUN_PROF",
    p.sueldo                                                                            AS "SUELDO"
FROM profesional p
JOIN asesoria a ON a.id_profesional = p.id_profesional
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 3
  AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY 
    p.id_profesional, 
    p.numrun_prof, 
    p.sueldo
ORDER BY p.id_profesional;

