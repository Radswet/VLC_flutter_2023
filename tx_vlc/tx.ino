#define LED_PIN 13 // Pin del LED

void setup() {
  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  String mensaje = "Hola Mundo"; // Mensaje a enviar
  for (int i = 0; i < mensaje.length(); i++) {
    char letra = mensaje.charAt(i);
    for (int j = 0; j < 8; j++) {
      int bit = (letra >> (7 - j)) & 1; // Obtiene el bit actual del mensaje
      if (bit == 1) {
        digitalWrite(LED_PIN, HIGH); // Enciende el LED (bit 1)
      } else {
        digitalWrite(LED_PIN, LOW); // Apaga el LED (bit 0)
      }
      delay(1000); // Duración del bit (ajusta según tu necesidad y entorno)
    }
  }
}
