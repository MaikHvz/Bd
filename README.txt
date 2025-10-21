==================================================
SISTEMA DE CÁLCULO DE ASIGNACIONES PARA PROFESIONALES
==================================================
Autor: Estudiante de Informática
Fecha: 2023
Curso: Bases de Datos II

DESCRIPCIÓN GENERAL
------------------
Este proyecto contiene scripts SQL para implementar un sistema de cálculo de asignaciones
para profesionales de la salud. El sistema calcula honorarios, asignaciones por tipo de
contrato, profesión y movilización, y registra los resultados en una base de datos.

ARCHIVOS INCLUIDOS
-----------------
1. 01_tablas_auditoria.sql
2. 02_triggers.sql
3. 03_funciones_basicas.sql
4. 04_package_spec.sql
5. 05_package_body.sql
6. 06_pruebas.sql

INSTRUCCIONES DE EJECUCIÓN
-------------------------
Para instalar y ejecutar correctamente el sistema, siga estos pasos en orden:

1. EJECUTAR 01_tablas_auditoria.sql
   - Este archivo crea la tabla de auditoría para registrar cambios en los sueldos
   - También crea la secuencia para generar IDs de auditoría
   - Comando: SQL> @01_tablas_auditoria.sql

2. EJECUTAR 02_triggers.sql
   - Este archivo crea el trigger que se activa cuando cambia el sueldo de un profesional
   - El trigger registra los cambios en la tabla de auditoría
   - Comando: SQL> @02_triggers.sql

3. EJECUTAR 03_funciones_basicas.sql
   - Este archivo crea funciones básicas para calcular honorarios y asignaciones
   - También crea un procedimiento para registrar errores
   - Comando: SQL> @03_funciones_basicas.sql

4. EJECUTAR 04_package_spec.sql
   - Este archivo crea la especificación del paquete de asignaciones
   - Define las funciones y procedimientos disponibles en el paquete
   - Comando: SQL> @04_package_spec.sql

5. EJECUTAR 05_package_body.sql
   - Este archivo implementa el cuerpo del paquete de asignaciones
   - Contiene toda la lógica de negocio para calcular asignaciones
   - Comando: SQL> @05_package_body.sql

6. EJECUTAR 06_pruebas.sql
   - Este archivo contiene pruebas para verificar el funcionamiento del sistema
   - Prueba cada función y procedimiento del paquete
   - Comando: SQL> @06_pruebas.sql

DESCRIPCIÓN DETALLADA DE CADA ARCHIVO
------------------------------------

01_tablas_auditoria.sql:
Este archivo crea la tabla de auditoría para registrar los cambios en los sueldos de los
profesionales. Cada vez que se modifica un sueldo, se guarda el valor anterior y el nuevo,
junto con información sobre quién hizo el cambio y cuándo.

02_triggers.sql:
Este archivo crea un trigger que se activa automáticamente cuando se actualiza el sueldo
de un profesional. El trigger inserta un registro en la tabla de auditoría con los datos
del cambio.

03_funciones_basicas.sql:
Este archivo contiene funciones básicas para calcular honorarios y asignaciones por
movilización, así como un procedimiento para registrar errores en el proceso. Estas
funciones son utilizadas por el paquete principal.

04_package_spec.sql:
Este archivo define la especificación del paquete de asignaciones, que es como un contrato
que indica qué funciones y procedimientos están disponibles para usar. Define la interfaz
pública del paquete.

05_package_body.sql:
Este archivo implementa toda la lógica de negocio del sistema. Contiene el código que
calcula las asignaciones según las reglas de negocio, procesa los datos de los profesionales
y genera resultados en formato JSON para integración con Java.

06_pruebas.sql:
Este archivo contiene pruebas para verificar que todas las funciones y procedimientos
funcionan correctamente. Ejecuta cada componente del sistema y muestra los resultados
para comprobar que los cálculos son correctos.

NOTAS ADICIONALES
----------------
- El sistema está diseñado para ser integrado con una interfaz Java
- Las funciones que devuelven JSON facilitan la integración con aplicaciones web
- El límite máximo de asignaciones está configurado en 250,000
- Se registran errores en la tabla errores_proceso para su posterior análisis

REQUISITOS DEL SISTEMA
--------------------
- Oracle Database 11g o superior
- Privilegios para crear tablas, secuencias, triggers y paquetes
- Tablas base (profesional, profesion, comuna) ya creadas en la base de datos

CONTACTO
-------
Para cualquier duda o consulta, contactar a:
estudiante@informatica.edu