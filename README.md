# ProdMon

Plateforme IoT de supervision intelligente de la production industrielle.

## Présentation

ProdMon est une plateforme développée pour assurer la supervision d'un système de production à travers l'acquisition, la transmission, le stockage et la visualisation des données issues des équipements.

Le prototype repose sur une architecture IoT intégrant un ESP32, le protocole MQTT, un Backend ASP.NET Core, une base de données PostgreSQL, une application mobile Flutter et un Dashboard Web.

## Contenu du dépôt

- **ESP32** : programme embarqué assurant l'acquisition des données, la communication MQTT et l'exécution des commandes.
- **Backend** : extrait du Backend ASP.NET Core assurant le traitement des données, la détection des alertes et leur enregistrement.
- **Flutter** : code principal de l'application mobile utilisée pour la supervision.
- **Dashboard-Web** : interface Web permettant la visualisation et l'analyse des données de production.

## Technologies utilisées

- ESP32
- MQTT / HiveMQ Cloud
- ASP.NET Core
- Entity Framework Core
- PostgreSQL
- Flutter / Dart
- HTML, CSS et JavaScript

## Fonctionnalités principales

- Acquisition et transmission des données de production
- Supervision de l'état des équipements
- Historisation des données
- Détection et gestion des alertes
- Notifications
- Commande à distance des équipements
- Acquittement des commandes par ACK
- Application mobile de supervision
- Dashboard Web de visualisation et d'analyse

## Projet académique

Ce dépôt accompagne le projet **ProdMon**, consacré à la conception et à l'implémentation d'un système de surveillance intelligente de la production industrielle.
