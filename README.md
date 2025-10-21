# Sistema de Asignaciones (Spring Boot + Oracle)

Aplicación web con Spring Boot y Thymeleaf que se conecta a Oracle para:
- Procesar asignaciones mensuales invocando el paquete `pkg_asignaciones`.
- Listar `detalle_asignacion_mes` por mes/año y filtrar por RUN.
- Buscar profesionales por nombre o RUT.
- Mostrar la hoja de auditoría de sueldos (`auditoria_sueldos`).
- Probar funciones del paquete y disparar el trigger actualizando sueldo.

## Requisitos
- Java 11+ y Maven 3.6+ (o IDE con soporte Spring Boot).
- Oracle 19c+ con objetos SQL cargados.
- Scripts SQL ejecutados en orden: `Crea_BD_DolphinConsulting.sql`, `01_tablas_auditoria.sql`, `02_triggers.sql`, `03_funciones_basicas.sql`, `04_package_spec.sql`, `05_package_body.sql` (opcional: `refactor/12_proceso_bloque_plsql.sql`).

## Configuración de Oracle
Edite `src/main/resources/application.properties` y descomente según su entorno:
- Sin Wallet:
  - `spring.datasource.url=jdbc:oracle:thin:@//HOST:PORT/SERVICE`
  - `spring.datasource.username=USER`
  - `spring.datasource.password=PASSWORD`
  - `spring.datasource.driver-class-name=oracle.jdbc.OracleDriver`
- Con Wallet (TCPS), ejemplo:
  - `spring.datasource.url=jdbc:oracle:thin:@DB_ALIAS?TNS_ADMIN=c:\\Users\\vina\\Desktop\\ejercicio\\Bd\\Wallet_DolphinConsulting`

Notas de encoding: use `AL32UTF8` en BD y clientes (`NLS_LANG=.AL32UTF8`) para ñ y acentos.

## Ejecución
- Con Maven: `mvn -DskipTests spring-boot:run`
- Con IDE: ejecutar `AsignacionesApplication`.

Abra `http://localhost:8080/`.

## Navegación Web
- `/` Inicio: procesar Mes/Año, buscar por nombre o RUT, enlaces a Auditorías y Pruebas.
- `/asignaciones?mes=MM&anio=YYYY[&run=RUT]` Listado de asignaciones.
- `/auditorias` Hoja de auditoría de sueldos.
- `/pruebas` Formularios para funciones del paquete y actualizar sueldo (trigger).

## Estructura principal
- `src/main/java/com/dolphinconsulting/asignaciones/AsignacionesApplication.java`
- `src/main/java/com/dolphinconsulting/asignaciones/service/AsignacionService.java`
- `src/main/java/com/dolphinconsulting/asignaciones/controller/AsignacionController.java`
- `src/main/java/com/dolphinconsulting/asignaciones/controller/AuditoriaController.java`
- `src/main/java/com/dolphinconsulting/asignaciones/controller/PruebasController.java`
- `src/main/resources/templates/index.html`
- `src/main/resources/templates/asignaciones.html`
- `src/main/resources/templates/auditorias.html`
- `src/main/resources/templates/pruebas.html`

## Detalles funcionales
- Proceso mensual: invoca `pkg_asignaciones.procesar_asignaciones_mes(mes, anio)`.
- Trigger de auditoría: `AFTER UPDATE OF sueldo ON profesional` inserta en `auditoria_sueldos`.
- Búsqueda: por nombre (LIKE) o RUT numérico.
- Bloque PL/SQL ajustado: si falta `tipo_contrato`, registra error y continúa con `v_porc_tpcont=0` para poblar tablas.

## Siguientes pasos opcionales
- Parametrizar límite de asignación vía UI (nueva proc en paquete).
- Ajustar trigger para registrar solo cambios reales (`:OLD.sueldo != :NEW.sueldo`).
- Validación y formato de RUT (con DV).