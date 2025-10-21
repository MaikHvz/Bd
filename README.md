# Sistema de Asignaciones para Profesionales

Este proyecto implementa una interfaz web con Spring Boot para el sistema de cálculo de asignaciones para profesionales de la salud, conectándose a una base de datos Oracle donde se encuentran los procedimientos almacenados, funciones y paquetes PL/SQL desarrollados previamente.

## Características

- Cálculo de asignaciones mensuales para profesionales
- Visualización de asignaciones procesadas
- Consulta de auditorías de cambios de sueldo
- Manejo de errores y validaciones
- API REST para integración con otros sistemas

## Requisitos

- Java 11 o superior
- Maven 3.6 o superior
- Base de datos Oracle 19c o superior
- Scripts SQL previamente ejecutados (01_tablas_auditoria.sql hasta 06_pruebas.sql)

## Configuración

1. Asegúrese de tener instalado Java y Maven
2. Configure la conexión a la base de datos Oracle en `src/main/resources/application.properties`
3. Ejecute los scripts SQL en el siguiente orden:
   - 01_tablas_auditoria.sql
   - 02_triggers.sql
   - 03_funciones_basicas.sql
   - 04_package_spec.sql
   - 05_package_body.sql
   - 06_pruebas.sql

## Ejecución

Para ejecutar la aplicación:

```bash
mvn spring-boot:run
```

La aplicación estará disponible en: http://localhost:8080

## Estructura del Proyecto

```
src/main/java/com/dolphinconsulting/asignaciones/
├── AsignacionesApplication.java       # Clase principal
├── config/                            # Configuraciones
│   └── OracleConfiguration.java       # Configuración de conexión a Oracle
├── controller/                        # Controladores MVC y REST
│   ├── AsignacionController.java      # Controlador para asignaciones
│   └── AuditoriaController.java       # Controlador para auditorías
├── exception/                         # Manejo de excepciones
│   ├── AsignacionException.java       # Excepción personalizada
│   └── GlobalExceptionHandler.java    # Manejador global de excepciones
├── model/                             # Entidades JPA
│   ├── AuditoriaSueldos.java          # Entidad para auditoría
│   ├── Comuna.java                    # Entidad para comuna
│   ├── DetalleAsignacionMes.java      # Entidad para asignaciones
│   ├── Profesion.java                 # Entidad para profesión
│   └── Profesional.java               # Entidad para profesional
├── repository/                        # Repositorios JPA
│   └── ProfesionalRepository.java     # Repositorio para profesionales
└── service/                           # Servicios
    └── AsignacionService.java         # Servicio para asignaciones
```

## Endpoints REST

- `GET /api/asignaciones?mes={mes}&anio={anio}` - Obtener asignaciones por mes y año
- `GET /api/errores?mes={mes}&anio={anio}` - Obtener errores de procesamiento por mes y año
- `POST /api/procesar?mes={mes}&anio={anio}` - Procesar asignaciones para un mes y año específicos

## Páginas Web

- `/` - Página principal
- `/asignaciones` - Visualización de asignaciones
- `/auditorias` - Visualización de auditorías de cambios de sueldo
- `/procesar` - Procesamiento de asignaciones mensuales

## Integración con PL/SQL

La aplicación se integra con los siguientes objetos PL/SQL:

- Paquete `pkg_asignaciones` para el cálculo de asignaciones
- Trigger de auditoría para cambios de sueldo
- Funciones básicas para cálculos específicos

## Autor

Dolphin Consulting