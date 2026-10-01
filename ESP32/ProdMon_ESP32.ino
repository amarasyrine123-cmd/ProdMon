#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// =====================================================
// BROCHES
// =====================================================

// Capteur IR
#define IR_SENSOR 19

// Bouton d'aide
#define HELP_BUTTON 21

// LEDs
#define GREEN_LED 14
#define YELLOW_LED 27
#define RED_LED 26

// DHT22
#define DHTPIN 18
#define DHTTYPE DHT22

// Capteur de vibration SW520
#define SW520_PIN 23

// Buzzer passif
#define BUZZER_PIN 32
#define BUZZER_CHANNEL 0


// =====================================================
// WIFI
// =====================================================

const char* ssid = "VOTRE_WIFI";
const char* password = "VOTRE_MOT_DE_PASSE_WIFI";


// =====================================================
// HIVEMQ CLOUD
// =====================================================

const char* mqtt_server =
  "VOTRE_BROKER_HIVEMQ";

const int mqtt_port = 8883;

const char* mqtt_user = "VOTRE_UTILISATEUR_MQTT";
const char* mqtt_password = "VOTRE_MOT_DE_PASSE_MQTT";


// =====================================================
// TOPICS MQTT
// =====================================================

// Anciennes commandes - conservées temporairement
const char* TOPIC_GREEN =
  "prodmon/machine1/green";

const char* TOPIC_YELLOW =
  "prodmon/machine1/yellow";

const char* TOPIC_RED =
  "prodmon/machine1/red";

// Nouveau système de commande avec ID
const char* TOPIC_COMMAND =
  "prodmon/machine1/command";

// Accusé de réception ESP32
const char* TOPIC_ACK =
  "prodmon/machine1/ack";

// Données machine
const char* TOPIC_DATA =
  "prodmon/machine1/data";


// =====================================================
// OBJETS
// =====================================================

DHT dht(DHTPIN, DHTTYPE);

WiFiClientSecure espClient;
PubSubClient client(espClient);


// =====================================================
// VARIABLES MACHINE
// =====================================================

bool machineRunning = false;

// État du bouton d'aide
bool helpRequested = false;

// États LEDs
bool greenLedState = false;
bool yellowLedState = false;
bool redLedState = false;

// Production
int production = 0;

// Température
float temperature = 0.0;

// SW520
bool vibrationDetected = false;
bool lastVibrationDetected = false;

// Buzzer
bool buzzerActive = false;
unsigned long buzzerStartTime = 0;
const unsigned long buzzerDuration = 500;

// Publication périodique
unsigned long lastPublish = 0;


// =====================================================
// VARIABLES CAPTEUR IR
// =====================================================

bool lastIRState = HIGH;
bool currentIRState = HIGH;


// =====================================================
// VARIABLES BOUTON / ANTI-REBOND
// =====================================================

int lastButtonReading = HIGH;
int stableButtonState = HIGH;

unsigned long lastDebounceTime = 0;

const unsigned long debounceDelay = 50;


// =====================================================
// BUZZER
// =====================================================

void startBuzzer() {

  ledcWriteTone(
    BUZZER_CHANNEL,
    2000
  );

  buzzerActive = true;
  buzzerStartTime = millis();

  Serial.println("BUZZER ON");
}


void stopBuzzer() {

  ledcWriteTone(
    BUZZER_CHANNEL,
    0
  );

  buzzerActive = false;

  Serial.println("BUZZER OFF");
}


// =====================================================
// ENVOI DES DONNÉES MACHINE
// =====================================================

void publishMachineData() {

  String state;

  if (machineRunning) {
    state = "RUNNING";
  } else {
    state = "STOPPED";
  }

  String payload = "{";

  payload += "\"state\":\"";
  payload += state;
  payload += "\",";

  payload += "\"production\":";
  payload += String(production);
  payload += ",";

  payload += "\"temperature\":";
  payload += String(temperature, 1);
  payload += ",";

  payload += "\"help\":";
  payload += String(helpRequested ? 1 : 0);

  payload += "}";


  bool publicationOK = client.publish(
    TOPIC_DATA,
    payload.c_str()
  );


  Serial.println();
  Serial.println("-----------------------------");
  Serial.println("DONNEES MQTT :");
  Serial.println(payload);

  if (publicationOK) {
    Serial.println("Publication MQTT reussie");
  } else {
    Serial.println("Erreur publication MQTT");
  }

  Serial.println("-----------------------------");
}


// =====================================================
// ENVOYER ACK À FLUTTER
// =====================================================

void publishAck(
  int commandId,
  String command,
  String status
) {

  StaticJsonDocument<256> doc;

  doc["commandId"] = commandId;
  doc["machineId"] = 1;
  doc["command"] = command;
  doc["status"] = status;

  String payload;

  serializeJson(doc, payload);


  bool publicationOK = client.publish(
    TOPIC_ACK,
    payload.c_str()
  );


  Serial.println();
  Serial.println("=============================");
  Serial.println("ACK ENVOYE PAR ESP32");
  Serial.print("Topic : ");
  Serial.println(TOPIC_ACK);

  Serial.print("Payload : ");
  Serial.println(payload);


  if (publicationOK) {
    Serial.println("ACK MQTT publie avec succes");
  } else {
    Serial.println("ERREUR publication ACK");
  }

  Serial.println("=============================");
}


// =====================================================
// EXECUTION D'UNE COMMANDE
// =====================================================

bool executeCommand(String command) {

  // ---------------------------------------------------
  // LED VERTE ON
  // ---------------------------------------------------

  if (command == "GREEN_ON") {

    digitalWrite(GREEN_LED, HIGH);

    greenLedState = true;
    machineRunning = true;

    Serial.println("LED verte allumee");
    Serial.println("Machine en fonctionnement");

    return true;
  }


  // ---------------------------------------------------
  // LED VERTE OFF
  // ---------------------------------------------------

  if (command == "GREEN_OFF") {

    digitalWrite(GREEN_LED, LOW);

    greenLedState = false;
    machineRunning = false;

    Serial.println("LED verte eteinte");
    Serial.println("Machine arretee");

    return true;
  }


  // ---------------------------------------------------
  // LED JAUNE ON
  // ---------------------------------------------------

  if (command == "YELLOW_ON") {

    digitalWrite(YELLOW_LED, HIGH);

    yellowLedState = true;

    Serial.println("LED jaune allumee");

    return true;
  }


  // ---------------------------------------------------
  // LED JAUNE OFF
  // ---------------------------------------------------

  if (command == "YELLOW_OFF") {

    digitalWrite(YELLOW_LED, LOW);

    yellowLedState = false;

    Serial.println("LED jaune eteinte");

    return true;
  }


  // ---------------------------------------------------
  // LED ROUGE ON
  // ---------------------------------------------------

  if (command == "RED_ON") {

    digitalWrite(RED_LED, HIGH);

    redLedState = true;
    machineRunning = false;

    Serial.println("LED rouge allumee");
    Serial.println("Arret machine");

    return true;
  }


  // ---------------------------------------------------
  // LED ROUGE OFF
  // ---------------------------------------------------

  if (command == "RED_OFF") {

    digitalWrite(RED_LED, LOW);

    redLedState = false;

    Serial.println("LED rouge eteinte");

    return true;
  }


  // ---------------------------------------------------
  // START
  // ---------------------------------------------------

  if (command == "START") {

    digitalWrite(GREEN_LED, HIGH);
    digitalWrite(RED_LED, LOW);

    greenLedState = true;
    redLedState = false;

    machineRunning = true;

    Serial.println("START execute");
    Serial.println("Machine demarree");

    return true;
  }


  // ---------------------------------------------------
  // STOP
  // ---------------------------------------------------

  if (command == "STOP") {

    digitalWrite(GREEN_LED, LOW);
    digitalWrite(RED_LED, HIGH);

    greenLedState = false;
    redLedState = true;

    machineRunning = false;

    Serial.println("STOP execute");
    Serial.println("Machine arretee");

    return true;
  }


  // ---------------------------------------------------
  // HELP
  // ---------------------------------------------------

  if (command == "HELP") {

    helpRequested = true;

    digitalWrite(YELLOW_LED, HIGH);

    yellowLedState = true;

    startBuzzer();

    Serial.println("HELP execute");
    Serial.println("Demande d'aide active");

    return true;
  }


  // ---------------------------------------------------
  // COMMANDE INCONNUE
  // ---------------------------------------------------

  Serial.print("Commande inconnue : ");
  Serial.println(command);

  return false;
}


// =====================================================
// TRAITEMENT NOUVELLE COMMANDE JSON
// =====================================================

void processJsonCommand(String message) {

  StaticJsonDocument<256> doc;

  DeserializationError error =
    deserializeJson(doc, message);


  // ---------------------------------------------------
  // JSON incorrect
  // ---------------------------------------------------

  if (error) {

    Serial.println();
    Serial.println("ERREUR JSON");

    Serial.print(
      "Impossible de lire la commande : "
    );

    Serial.println(error.c_str());

    return;
  }


  // ---------------------------------------------------
  // EXTRAIRE LES INFORMATIONS
  // ---------------------------------------------------

  int commandId =
    doc["commandId"] | 0;

  String command =
    doc["command"] | "";


  Serial.println();
  Serial.println("=============================");
  Serial.println("NOUVELLE COMMANDE PRODMON");

  Serial.print("Command ID : ");
  Serial.println(commandId);

  Serial.print("Commande : ");
  Serial.println(command);

  Serial.println("=============================");


  // ---------------------------------------------------
  // VÉRIFICATIONS
  // ---------------------------------------------------

  if (commandId <= 0) {

    Serial.println(
      "ERREUR : commandId invalide"
    );

    return;
  }


  if (command.length() == 0) {

    Serial.println(
      "ERREUR : commande vide"
    );

    publishAck(
      commandId,
      command,
      "ECHEC"
    );

    return;
  }


  // ---------------------------------------------------
  // EXECUTION PHYSIQUE
  // ---------------------------------------------------

  bool executionOK =
    executeCommand(command);


  // ---------------------------------------------------
  // ENVOYER LE NOUVEL ÉTAT MACHINE
  // ---------------------------------------------------

  publishMachineData();


  // ---------------------------------------------------
  // ACK
  // ---------------------------------------------------

  if (executionOK) {

    publishAck(
      commandId,
      command,
      "EXECUTEE"
    );

  } else {

    publishAck(
      commandId,
      command,
      "ECHEC"
    );
  }
}


// =====================================================
// RÉCEPTION MQTT
// =====================================================

void callback(
  char* topic,
  byte* payload,
  unsigned int length
) {

  String message = "";

  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  String topicStr = String(topic);


  Serial.println();
  Serial.println("-----------------------------");

  Serial.print("Topic recu : ");
  Serial.println(topicStr);

  Serial.print("Message : ");
  Serial.println(message);


  // ===================================================
  // NOUVEAU SYSTÈME : COMMANDE JSON + ACK
  // ===================================================

  if (topicStr == TOPIC_COMMAND) {

    processJsonCommand(message);

    Serial.println("-----------------------------");

    return;
  }


  // ===================================================
  // ANCIEN SYSTÈME
  // Conservé pendant nos tests
  // ===================================================


  // ---------------------------------------------------
  // LED VERTE
  // ---------------------------------------------------

  if (topicStr == TOPIC_GREEN) {

    if (message == "ON") {

      executeCommand("GREEN_ON");

    } else if (message == "OFF") {

      executeCommand("GREEN_OFF");
    }
  }


  // ---------------------------------------------------
  // LED JAUNE
  // ---------------------------------------------------

  else if (topicStr == TOPIC_YELLOW) {

    if (message == "ON") {

      executeCommand("YELLOW_ON");

    } else if (message == "OFF") {

      executeCommand("YELLOW_OFF");
    }
  }


  // ---------------------------------------------------
  // LED ROUGE
  // ---------------------------------------------------

  else if (topicStr == TOPIC_RED) {

    if (message == "ON") {

      executeCommand("RED_ON");

    } else if (message == "OFF") {

      executeCommand("RED_OFF");
    }
  }


  Serial.println("-----------------------------");
}


// =====================================================
// CONNEXION WIFI
// =====================================================

void connectWiFi() {

  Serial.print("Connexion WiFi");

  WiFi.begin(ssid, password);


  while (WiFi.status() != WL_CONNECTED) {

    delay(500);

    Serial.print(".");
  }


  Serial.println();

  Serial.println("WiFi connecte");

  Serial.print("Adresse IP : ");

  Serial.println(
    WiFi.localIP()
  );
}


// =====================================================
// CONNEXION MQTT
// =====================================================

void reconnect() {

  while (!client.connected()) {

    Serial.print("Connexion MQTT...");


    if (
      client.connect(
        "ESP32_PRODMON",
        mqtt_user,
        mqtt_password
      )
    ) {

      Serial.println("OK");


      // Anciennes commandes
      client.subscribe(TOPIC_GREEN);
      client.subscribe(TOPIC_YELLOW);
      client.subscribe(TOPIC_RED);

      // Nouveau système de commande
      client.subscribe(TOPIC_COMMAND);


      Serial.println(
        "Abonnement MQTT termine"
      );

      Serial.print(
        "Nouveau topic commande : "
      );

      Serial.println(TOPIC_COMMAND);

      Serial.print(
        "Topic ACK : "
      );

      Serial.println(TOPIC_ACK);


      publishMachineData();

    } else {

      Serial.print(
        "Erreur MQTT, code : "
      );

      Serial.println(
        client.state()
      );


      Serial.println(
        "Nouvelle tentative dans 5 secondes"
      );


      delay(5000);
    }
  }
}


// =====================================================
// SETUP
// =====================================================

void setup() {

  Serial.begin(115200);

  delay(1000);


  Serial.println();
  Serial.println("=============================");
  Serial.println("DEMARRAGE PRODMON ACK");
  Serial.println("=============================");


  // ---------------------------------------------------
  // DHT22
  // ---------------------------------------------------

  dht.begin();


  // ---------------------------------------------------
  // LEDs
  // ---------------------------------------------------

  pinMode(
    GREEN_LED,
    OUTPUT
  );

  pinMode(
    YELLOW_LED,
    OUTPUT
  );

  pinMode(
    RED_LED,
    OUTPUT
  );


  digitalWrite(
    GREEN_LED,
    LOW
  );

  digitalWrite(
    YELLOW_LED,
    LOW
  );

  digitalWrite(
    RED_LED,
    LOW
  );


  // ---------------------------------------------------
  // CAPTEUR IR
  // ---------------------------------------------------

  pinMode(
    IR_SENSOR,
    INPUT_PULLUP
  );

  lastIRState =
    digitalRead(IR_SENSOR);


  // ---------------------------------------------------
  // BOUTON D'AIDE
  // ---------------------------------------------------

  pinMode(
    HELP_BUTTON,
    INPUT_PULLUP
  );


  lastButtonReading =
    digitalRead(HELP_BUTTON);

  stableButtonState =
    lastButtonReading;


  helpRequested =
    (stableButtonState == LOW);


  // ---------------------------------------------------
  // CAPTEUR DE VIBRATION SW520
  // ---------------------------------------------------

  pinMode(
    SW520_PIN,
    INPUT_PULLUP
  );

  vibrationDetected =
    (digitalRead(SW520_PIN) == HIGH);

  lastVibrationDetected =
    vibrationDetected;


  // ---------------------------------------------------
  // BUZZER
  // ---------------------------------------------------

  ledcSetup(
    BUZZER_CHANNEL,
    2000,
    8
  );

  ledcAttachPin(
    BUZZER_PIN,
    BUZZER_CHANNEL
  );

  ledcWriteTone(
    BUZZER_CHANNEL,
    0
  );


  // ---------------------------------------------------
  // WIFI
  // ---------------------------------------------------

  connectWiFi();


  // ---------------------------------------------------
  // MQTT TLS
  // ---------------------------------------------------

  espClient.setInsecure();

  client.setServer(
    mqtt_server,
    mqtt_port
  );

  client.setCallback(
    callback
  );


  Serial.println("=============================");
  Serial.println("PRODMON ACK PRET");
  Serial.println("=============================");
}


// =====================================================
// LOOP
// =====================================================

void loop() {

  // ---------------------------------------------------
  // WIFI
  // ---------------------------------------------------

  if (
    WiFi.status() !=
    WL_CONNECTED
  ) {

    Serial.println(
      "WiFi deconnecte"
    );

    connectWiFi();
  }


  // ---------------------------------------------------
  // MQTT
  // ---------------------------------------------------

  if (!client.connected()) {

    reconnect();
  }


  client.loop();


  // ===================================================
  // BOUTON D'AIDE
  // ===================================================

  int buttonReading =
    digitalRead(HELP_BUTTON);


  if (
    buttonReading !=
    lastButtonReading
  ) {

    lastDebounceTime =
      millis();
  }


  if (
    millis() -
    lastDebounceTime >
    debounceDelay
  ) {

    if (
      buttonReading !=
      stableButtonState
    ) {

      stableButtonState =
        buttonReading;


      // Bouton appuyé
      if (
        stableButtonState ==
        LOW
      ) {

        helpRequested = true;


        Serial.println();

        Serial.println(
          "*****************************"
        );

        Serial.println(
          "DEMANDE D'AIDE ACTIVE !"
        );

        Serial.println(
          "help = 1"
        );

        Serial.println(
          "*****************************"
        );


        digitalWrite(
          YELLOW_LED,
          HIGH
        );

        yellowLedState = true;

        startBuzzer();

      }

      // Bouton relâché
      else {

        helpRequested = false;


        Serial.println();

        Serial.println(
          "Bouton d'aide relache"
        );

        Serial.println(
          "help = 0"
        );


        digitalWrite(
          YELLOW_LED,
          LOW
        );

        yellowLedState = false;
      }


      if (client.connected()) {

        publishMachineData();
      }
    }
  }


  lastButtonReading =
    buttonReading;


  // ===================================================
  // CAPTEUR IR
  // ===================================================

  currentIRState =
    digitalRead(IR_SENSOR);


  if (
    lastIRState == HIGH &&
    currentIRState == LOW
  ) {

    production++;


    Serial.print(
      "Nouvelle piece detectee : "
    );

    Serial.println(
      production
    );
  }


  lastIRState =
    currentIRState;


  // ===================================================
  // CAPTEUR DE VIBRATION SW520
  // ===================================================

  vibrationDetected =
    (digitalRead(SW520_PIN) == HIGH);


  if (
    vibrationDetected &&
    !lastVibrationDetected
  ) {

    Serial.println();

    Serial.println(
      "*****************************"
    );

    Serial.println(
      "VIBRATION DETECTEE !"
    );

    Serial.println(
      "SW520 = 1"
    );

    Serial.println(
      "*****************************"
    );

    // Le SW520 signale uniquement la vibration.
    // Pas de buzzer ici pour eviter la boucle
    // vibration -> buzzer -> vibration.
  }


  lastVibrationDetected =
    vibrationDetected;


  // ===================================================
  // ARRET AUTOMATIQUE DU BUZZER
  // ===================================================

  if (
    buzzerActive &&
    millis() - buzzerStartTime >=
    buzzerDuration
  ) {

    stopBuzzer();
  }


  // ===================================================
  // DHT22 + PUBLICATION TOUTES LES 2 SECONDES
  // ===================================================

  if (
    millis() -
    lastPublish >=
    2000
  ) {

    lastPublish =
      millis();


    float t =
      dht.readTemperature();


    if (!isnan(t)) {

      temperature = t;

    } else {

      Serial.println(
        "Erreur lecture DHT22"
      );
    }


    publishMachineData();
  }
}
