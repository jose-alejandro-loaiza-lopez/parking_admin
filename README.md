# Parking Admin

Aplicación móvil Flutter para la administración de un parqueadero. Registra el
ingreso y la salida de vehículos, calcula automáticamente el cobro según el tipo
de vehículo, genera facturas y ofrece reportes de ingresos.

Funciona **100% offline**: toda la información se guarda localmente en una base
de datos SQLite en el dispositivo, sin servidores ni conexión a internet.

## Características

### Activos (pantalla principal)
- Panel con métricas del día: vehículos activos, completados hoy e ingreso del día.
- Lista de vehículos actualmente estacionados con el tiempo transcurrido en vivo.
- Búsqueda por placa, conductor o cédula.
- Botón **Registrar ingreso** y acceso directo a procesar la salida tocando un vehículo.

### Registrar ingreso (check-in)
- Selección del tipo de vehículo (con opción de crear uno nuevo al vuelo).
- Datos del conductor: nombre (obligatorio), cédula y placa opcionales.

### Procesar salida (check-out)
- Calcula el valor a pagar automáticamente según el tipo de cobro del vehículo.
- Muestra el resumen y genera una **factura**.

### Historial
- Lista de registros filtrada por rango de fechas (por defecto, el día actual).
- Búsqueda por texto.
- Ver la factura de un registro y eliminarlo.

### Reportes
- Rango de fechas configurable (por defecto, el mes actual).
- Ingresos totales y número de vehículos atendidos.
- Desglose de ingresos y cantidad por tipo de vehículo.

### Configuración (Ajustes)
- **Tipos de vehículo**: administrar tipos y tarifas (crear, editar, eliminar).
- **Tema**: claro u oscuro (se recuerda entre sesiones).
- **Exportar respaldo CSV**: todo el historial o un rango personalizado; comparte el archivo.
- **Importar respaldo CSV**: restaura datos sin duplicar registros existentes.
- **Borrar todos los registros**: requiere escribir `confirmar` para confirmar.

## Tipos de cobro

Cada tipo de vehículo define cómo se calcula el valor:

| Tipo de cobro | `pricing_type` | Cálculo |
| --- | --- | --- |
| Por hora | `per_hour` | Horas redondeadas hacia arriba × tarifa |
| Por minuto | `per_minute` | Minutos transcurridos × tarifa |
| Por día | `per_day` | Días redondeados hacia arriba × tarifa |
| Tarifa única | `flat_rate` | Tarifa fija, sin importar el tiempo |

### Tipos de vehículo por defecto

| Nombre | Cobro | Tarifa |
| --- | --- | --- |
| Bicicleta | Tarifa única | $2.000 |
| Moto | Por hora | $3.000 |
| Carro | Por hora | $5.000 |

Los valores monetarios se formatean en pesos colombianos (`es_CO`, sin decimales).

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.12.2` o superior).
- Android Studio / SDK de Android para ejecutar en un dispositivo o emulador.

## Instalación y uso

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en un dispositivo o emulador conectado
flutter run

# Compilar APK de release
flutter build apk --release

# Ejecutar las pruebas
flutter test
```

## Estructura del proyecto

```
lib/
├── main.dart                     # Punto de entrada
├── app.dart                      # MaterialApp, tema y navegación por pestañas
├── database/
│   ├── database_helper.dart      # Creación/migración de SQLite y datos iniciales
│   ├── parking_record_dao.dart   # Consultas de registros de parqueo
│   └── vehicle_type_dao.dart     # Consultas de tipos de vehículo
├── models/
│   ├── parking_record.dart       # Registro de parqueo (ingreso, salida, total)
│   └── vehicle_type.dart         # Tipo de vehículo y tipo de cobro
├── screens/
│   ├── active_vehicles_screen.dart
│   ├── check_in_screen.dart
│   ├── check_out_screen.dart
│   ├── history_screen.dart
│   ├── invoice_screen.dart
│   ├── reports_screen.dart
│   ├── settings_screen.dart
│   └── vehicle_types_screen.dart
├── services/
│   ├── csv_service.dart          # Exportar/importar respaldos CSV
│   └── pricing_service.dart      # Cálculo del valor a pagar
├── utils/
│   ├── constants.dart            # Configuración y tipos por defecto
│   └── helpers.dart              # Utilidades de formato (moneda, fecha, duración)
└── widgets/                      # Componentes reutilizables
```

## Base de datos

SQLite con dos tablas (versión de esquema `2`):

- `vehicle_types`: `id`, `name`, `pricing_type`, `price`, `is_custom`, `is_default`.
- `parking_records`: `id`, `vehicle_type_id`, `plate`, `person_name`, `cedula`,
  `check_in`, `check_out`, `total_amount`, `is_active`.

## Dependencias principales

| Paquete | Uso |
| --- | --- |
| `sqflite` | Base de datos SQLite local |
| `path_provider` | Rutas de almacenamiento del dispositivo |
| `shared_preferences` | Persistencia de preferencias (tema) |
| `intl` | Formato de moneda y fechas |
| `csv` | Codificación/decodificación de respaldos |
| `share_plus` | Compartir el archivo CSV exportado |
| `file_picker` | Seleccionar el archivo CSV a importar |

## Licencia

Proyecto privado. Todos los derechos reservados.
