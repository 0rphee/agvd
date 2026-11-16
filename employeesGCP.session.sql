USE employees;

------------------------
-- fase 1
------------------------

-- 1.1 nuevo employee id 999999 con salario 
-- inicial titulo profesional y departamento asignado
-- fecha inicio 2002-12-01
-- marketing es d001

select * from departments; 

SELECT * FROM employees WHERE emp_no = 999999;

INSERT INTO employees (emp_no, birth_date, first_name, last_name, gender, hire_date)
VALUES (999999, '1980-12-01', 'Rodrigo', 'Rodriguez', 'M',  '2002-12-01');

INSERT INTO salaries (emp_no, salary, from_date, to_date)
VALUES (999999, 50000, '2002-12-01', '9999-01-01');

INSERT INTO titles (emp_no, title, from_date, to_date)
VALUES (999999, "Marketero Experto", "2002-12-01", "9999-01-01");

INSERT INTO dept_emp (emp_no, dept_no, from_date, to_date)
VALUES (999999, "d001", "2002-12-01", "9999-01-01");

SELECT * FROM employees WHERE emp_no = 999999;


-- 1.2 Tenure de Management: ¿Cuánto tiempo real de liderazgo tenemos? 
-- Calcule el tiempo promedio (en años) que los gerentes permanecen en 
-- su posición. Tip: Usar CASE para tratar la fecha '9999-01-01' como
-- '2002-12-01' Sólo si es necesario.


-- para quienes siguen en cargo, tomamos fecha actual como 2002-12-01
SELECT AVG(
    CASE 
        WHEN to_date = '9999-01-01' THEN DATEDIFF('2002-12-01', from_date) / 365
        ELSE DATEDIFF(to_date, from_date) / 365
    END) AS prom_tenure_management
FROM dept_manager;

-- 1.3 Identificación de Pioneros: Encuentre el nombre y la fecha de contratación 
-- de los 10 empleados con mayor antigüedad en la firma.

-- interpreto que son los que siguen contratados
SELECT e.first_name, e.last_name, e.hire_date, s.to_date  FROM employees AS e
INNER JOIN salaries as s
    ON e.emp_no = s.emp_no 
WHERE s.to_date = '9999-01-01'
ORDER BY e.hire_date
LIMIT 10;

------------------------
-- fase 2
------------------------

-- 2.4 Progresión de Carrera: Identifique a los empleados que han tenido 
-- más de dos títulos en la empresa y muestre exclusivamente su puesto más
--  reciente al día de hoy.

-- interpreto que "al dia de hoy" significa que solo nos interesan
-- empleados que siguen en la empresa
SELECT e.emp_no, e.first_name, e.last_name, t.title, t.from_date, t.to_date FROM employees AS e
INNER JOIN titles AS t 
    ON e.emp_no = t.emp_no
WHERE t.to_date = '9999-01-01'
  AND e.emp_no IN (
      SELECT titles.emp_no
      FROM titles
      GROUP BY titles.emp_no
      HAVING COUNT(*) > 2
  )
ORDER BY e.hire_date
;

-- 2.5 Diagnóstico de Data Quality: Identifique a los empleados que no 
-- tenían un departamento asignado el mismo día de su fecha de contratación.

SELECT e.emp_no, e.first_name, e.last_name, e.hire_date, MIN(d.from_date) AS primer_departamento
FROM employees AS e
INNER JOIN dept_emp AS d
    ON e.emp_no = d.emp_no
GROUP BY e.emp_no
HAVING e.hire_date != MIN(d.from_date)
;


-- 2.6 Movilidad Interna: Cuantifique cuántos empleados han cambiado de departamento
-- o trabajado en más de una unidad de negocio.

SELECT COUNT(*) as total
FROM
    (SELECT d.emp_no 
    FROM employees AS e
    INNER JOIN dept_emp AS d
        ON e.emp_no = d.emp_no
    GROUP BY d.emp_no
    HAVING COUNT(d.emp_no) > 1
) AS emp_mas_de1_dep
;


------------------------
-- fase 3
------------------------

-- 3.7 Análisis de Compensación (Quality Management): Encuentre el incremento
--  promedio de salario, junto con su máximo, mínimo y desviación estándar en 
-- este departamento.
SELECT * 
FROM departments 
WHERE dept_name = 'Quality Management'
;
-- d006

-- interpreto que es diferencia total, entre primer salario y ultimo, 
-- asumiendo que no hay decrementos de salario
SELECT AVG(incremento) AS inc_promedio,
    MAX(incremento) AS inc_maximo,
    MIN(incremento) AS inc_minimo,
    STD(incremento) AS inc_desviacion
FROM (
    SELECT s.emp_no, MAX(s.salary) - MIN(s.salary) AS incremento
    FROM salaries AS s
    INNER JOIN dept_emp AS d
        ON d.emp_no = s.emp_no
    WHERE
        d.dept_no = "d006"
    GROUP BY s.emp_no
) AS incrementos
;

-- 3.8 Brecha de Equidad (ESG Analysis): Compare el salario promedio entre
--  hombres y mujeres en los departamentos de 'Sales' y 'Research'.

SELECT * 
FROM departments 
WHERE dept_name = 'Sales' OR dept_name = 'Research'
;
-- d008 Research, d007 Sales

SELECT d.dept_name, e.gender, AVG(s.salary)
FROM employees AS e
INNER JOIN salaries AS s
    ON e.emp_no = s.emp_no
INNER JOIN dept_emp AS de
    ON e.emp_no = de.emp_no
INNER JOIN departments AS d
    ON de.dept_no = d.dept_no
WHERE de.dept_no IN ('d007', 'd008')
GROUP BY d.dept_name, e.gender
;

-- 3.9 Detección de High Potentials (HiPo): Identifique a los 10 empleados
--  que han recibido la mayor cantidad de incrementos salariales en sus primeros
-- 5 años de trayectoria.

-- interpreto que solo comparamos a los que siguen empleados (sino, high pontentials 
-- no tiene mucho sentido para un negocio)
SELECT e.emp_no, e.first_name, e.last_name, COUNT(*) AS num_incrementos
FROM employees AS e
INNER JOIN salaries AS s
    ON e.emp_no = s.emp_no
WHERE s.from_date > e.hire_date
  AND s.from_date <= DATE_ADD(e.hire_date, INTERVAL 5 YEAR)
  AND e.emp_no IN (
      SELECT emp_no
      FROM salaries
      WHERE to_date = '9999-01-01'
  )
GROUP BY e.emp_no, e.first_name, e.last_name
ORDER BY num_incrementos DESC
LIMIT 10
;

-- 3.10 Correlación de "Churn" y Compensación: Identifique el departamento
--  con la mayor tasa de rotación antes del corte y cruce este dato con el salario
--  promedio de dicha unidad.

-- no me quedó muy claro cual es el "corte", pero asumo que es la fecha usada antes: 2002-12-01
SELECT t.dept_name, t.tasa_rotacion, AVG(s.salary) AS salario_promedio
FROM (
    SELECT d.dept_no, d.dept_name,
        AVG(de.to_date < '2002-12-01') AS tasa_rotacion
    FROM departments AS d
    INNER JOIN dept_emp AS de
        ON d.dept_no = de.dept_no
    GROUP BY d.dept_no, d.dept_name
    ORDER BY tasa_rotacion DESC
) AS t
INNER JOIN dept_emp AS de
    ON t.dept_no = de.dept_no
INNER JOIN salaries AS s
    ON de.emp_no = s.emp_no
GROUP BY t.dept_no, t.dept_name, t.tasa_rotacion
ORDER BY t.tasa_rotacion DESC
;

-- Pregunta personal: 0250061
-- ¿Cuántos cambios de departamento ocurrieron cada año?
-- Estás haciendo esta consulta el 1 de diciembre de 2002. En la base, lo vigente 
-- hoy es el registro con to_date = ‘9999-01-01’. Para edades y antigüedades usa 
-- la fecha ‘2002-12-01’, no CURDATE() ni NOW(): esas devuelven la fecha real de 
-- tu computadoras.
SELECT YEAR(d.from_date) AS anio, COUNT(*) AS cambios
FROM dept_emp AS d
WHERE d.from_date > (
    SELECT MIN(d2.from_date)
    FROM dept_emp AS d2
    WHERE d2.emp_no = d.emp_no
)
  AND d.from_date <= '2002-12-01'
GROUP BY anio
ORDER BY anio
;
